import Foundation
import Cocoa

struct TextDiffParagraph: Identifiable {
    let id = UUID()
    let segments: [TextDiffSegment]
}

struct TextFixResult {
    let originalText: String
    let correctedText: String
    let fixCount: Int
    let paragraphs: [TextDiffParagraph]
}

enum DiffSegmentType {
    case unchanged
    case inserted
    case deleted
    case modified(original: String, new: String)
}

struct TextDiffSegment: Identifiable {
    let id = UUID()
    let text: String
    let type: DiffSegmentType
}

class TextAssistantEngine {
    static let shared = TextAssistantEngine()
    
    private let spellChecker = NSSpellChecker.shared
    
    /// Основной метод проверки орфографии и пунктуации (100% локальный, Option B)
    func processText(_ inputText: String) -> TextFixResult {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return TextFixResult(originalText: inputText, correctedText: inputText, fixCount: 0, paragraphs: [])
        }
        
        var text = inputText
        var totalFixes = 0
        
        // 1. Исправление типичных пунктуационных ошибок в русском языке (Правила)
        let punctuationResult = fixRussianPunctuation(text)
        text = punctuationResult.text
        totalFixes += punctuationResult.fixCount
        
        // 2. Проверка и исправление орфографии с помощью NSSpellChecker
        let spellResult = fixRussianSpelling(text)
        text = spellResult.text
        totalFixes += spellResult.fixCount
        
        // 3. Генерация абзацев и сегментов различий (Diff) с сохранением структуры строк
        let paragraphs = computeDiffParagraphs(original: inputText, corrected: text)
        
        return TextFixResult(
            originalText: inputText,
            correctedText: text,
            fixCount: totalFixes,
            paragraphs: paragraphs
        )
    }
    
    // MARK: - Пунктуация (Русский язык)
    private func fixRussianPunctuation(_ input: String) -> (text: String, fixCount: Int) {
        var text = input
        var fixes = 0
        
        // Правило 1: Добавление запятой перед вводными союзами и союзами в сложносочиненных/подчиненных предложениях
        let conjunctions = ["а", "но", "что", "чтобы", "если", "когда", "потому что", "так как", "хотя", "будто", "словно", "ежели"]
        
        for conj in conjunctions {
            let pattern = "(?i)(?<=\\S)\\s+(" + NSRegularExpression.escapedPattern(for: conj) + ")\\b(?=[\\s.,!?:;])"
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
                if !matches.isEmpty {
                    let mutable = NSMutableString(string: text)
                    for match in matches.reversed() {
                        let range = match.range(at: 1)
                        if range.location != NSNotFound {
                            mutable.insert(",", at: range.location)
                            fixes += 1
                        }
                    }
                    text = mutable as String
                }
            }
        }
        
        // Правило 2: Пробелы после знаков препинания (точка, запятая, двоеточие, тире)
        let missingSpaceRegex = try? NSRegularExpression(pattern: "([.,!?:;])([А-Яа-яA-Za-z0-9])", options: [])
        if let matches = missingSpaceRegex?.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)), !matches.isEmpty {
            let mutable = NSMutableString(string: text)
            for match in matches.reversed() {
                let range = match.range(at: 2)
                if range.location != NSNotFound {
                    mutable.insert(" ", at: range.location)
                    fixes += 1
                }
            }
            text = mutable as String
        }
        
        // Правило 3: Двойные пробелы
        while text.contains("  ") {
            text = text.replacingOccurrences(of: "  ", with: " ")
            fixes += 1
        }
        
        // Правило 4: Заглавная буква в начале предложений
        let sentenceStartRegex = try? NSRegularExpression(pattern: "([.!?]\\s+)([а-я])", options: [])
        if let matches = sentenceStartRegex?.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)), !matches.isEmpty {
            let mutable = NSMutableString(string: text)
            for match in matches.reversed() {
                let range = match.range(at: 2)
                if range.location != NSNotFound {
                    let substring = mutable.substring(with: range)
                    mutable.replaceCharacters(in: range, with: substring.uppercased())
                    fixes += 1
                }
            }
            text = mutable as String
        }
        
        return (text, fixes)
    }
    
    // MARK: - Орфография (NSSpellChecker)
    private func fixRussianSpelling(_ input: String) -> (text: String, fixCount: Int) {
        var text = input
        var fixes = 0
        let language = "ru"
        
        spellChecker.automaticallyIdentifiesLanguages = false
        
        var stringRange = NSRange(location: 0, length: text.utf16.count)
        
        while stringRange.location < text.utf16.count {
            let misspelledRange = spellChecker.checkSpelling(
                of: text,
                startingAt: stringRange.location,
                language: language,
                wrap: false,
                inSpellDocumentWithTag: 0,
                wordCount: nil
            )
            
            if misspelledRange.location == NSNotFound || misspelledRange.length == 0 {
                break
            }
            
            let guesses = spellChecker.guesses(
                forWordRange: misspelledRange,
                in: text,
                language: language,
                inSpellDocumentWithTag: 0
            )
            
            if let firstGuess = guesses?.first, !firstGuess.isEmpty {
                let mutable = NSMutableString(string: text)
                mutable.replaceCharacters(in: misspelledRange, with: firstGuess)
                text = mutable as String
                fixes += 1
                
                stringRange.location = misspelledRange.location + (firstGuess as NSString).length
                stringRange.length = text.utf16.count - stringRange.location
            } else {
                stringRange.location = misspelledRange.location + misspelledRange.length
                stringRange.length = text.utf16.count - stringRange.location
            }
        }
        
        return (text, fixes)
    }
    
    // MARK: - Расчет разностей по абзацам (Paragraph & Word Diff)
    private func computeDiffParagraphs(original: String, corrected: String) -> [TextDiffParagraph] {
        let origLines = original.components(separatedBy: "\n")
        let corrLines = corrected.components(separatedBy: "\n")
        
        var paragraphs: [TextDiffParagraph] = []
        let maxLines = max(origLines.count, corrLines.count)
        
        for k in 0..<maxLines {
            let origLine = k < origLines.count ? origLines[k] : ""
            let corrLine = k < corrLines.count ? corrLines[k] : ""
            
            let origWords = origLine.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            let corrWords = corrLine.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            
            var segments: [TextDiffSegment] = []
            var i = 0
            var j = 0
            
            while i < origWords.count || j < corrWords.count {
                if i < origWords.count && j < corrWords.count {
                    let w1 = origWords[i]
                    let w2 = corrWords[j]
                    
                    if w1 == w2 {
                        segments.append(TextDiffSegment(text: w1, type: .unchanged))
                        i += 1
                        j += 1
                    } else {
                        segments.append(TextDiffSegment(text: w2, type: .modified(original: w1, new: w2)))
                        i += 1
                        j += 1
                    }
                } else if i < origWords.count {
                    segments.append(TextDiffSegment(text: origWords[i], type: .deleted))
                    i += 1
                } else if j < corrWords.count {
                    segments.append(TextDiffSegment(text: corrWords[j], type: .inserted))
                    j += 1
                }
            }
            
            paragraphs.append(TextDiffParagraph(segments: segments))
        }
        
        return paragraphs
    }
}
