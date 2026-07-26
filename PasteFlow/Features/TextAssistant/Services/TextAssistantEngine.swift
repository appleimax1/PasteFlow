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
    
    private lazy var hunspell: HunspellWrapper? = {
        let fileManager = FileManager.default
        let bundlePath = Bundle.main.bundlePath
        let resourcePath = Bundle.main.resourcePath ?? (bundlePath + "/Contents/Resources")
        
        let possiblePaths: [(dic: String, aff: String)] = [
            (resourcePath + "/ru_RU.dic", resourcePath + "/ru_RU.aff"),
            (resourcePath + "/Dictionaries/ru_RU.dic", resourcePath + "/Dictionaries/ru_RU.aff"),
            (resourcePath + "/Resources/Dictionaries/ru_RU.dic", resourcePath + "/Resources/Dictionaries/ru_RU.aff"),
            (
                Bundle.main.path(forResource: "ru_RU", ofType: "dic") ?? "",
                Bundle.main.path(forResource: "ru_RU", ofType: "aff") ?? ""
            ),
            (
                fileManager.currentDirectoryPath + "/PasteFlow/Resources/Dictionaries/ru_RU.dic",
                fileManager.currentDirectoryPath + "/PasteFlow/Resources/Dictionaries/ru_RU.aff"
            )
        ]
        
        for p in possiblePaths {
            if !p.dic.isEmpty && !p.aff.isEmpty && fileManager.fileExists(atPath: p.dic) && fileManager.fileExists(atPath: p.aff) {
                NSLog("[TextAssistantEngine] Successfully loaded Hunspell dictionary from: %@", p.dic)
                return HunspellWrapper(dicPath: p.dic, affPath: p.aff)
            }
        }
        
        NSLog("[TextAssistantEngine] WARNING: Could not find ru_RU.dic / ru_RU.aff in bundle!")
        return nil
    }()
    
    /// Основной метод проверки текста (100% локальный, Hunspell + Безопасное ранжирование + Слитные опечатки + Пунктуация)
    func processText(_ inputText: String) -> TextFixResult {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return TextFixResult(originalText: inputText, correctedText: inputText, fixCount: 0, paragraphs: [])
        }
        
        var text = inputText
        var totalFixes = 0
        
        // 0. Предварительная коррекция устойчивых слитных/дефисных опечаток ("не знаю", "из-за", "что-то")
        let splitResult = fixCommonSplitAndHyphenErrors(text)
        text = splitResult.text
        totalFixes += splitResult.fixCount
        
        // 1. Проверка орфографии Hunspell с контролем дистанции Левенштейна и буквой Ё
        let spellResult = fixRussianSpelling(text)
        text = spellResult.text
        totalFixes += spellResult.fixCount
        
        // 2. Исправление пунктуации, исключений и кавычек
        let punctuationResult = fixRussianPunctuation(text)
        text = punctuationResult.text
        totalFixes += punctuationResult.fixCount
        
        // 3. Генерация сегментов различий (Diff)
        let paragraphs = computeDiffParagraphs(original: inputText, corrected: text)
        
        return TextFixResult(
            originalText: inputText,
            correctedText: text,
            fixCount: totalFixes,
            paragraphs: paragraphs
        )
    }
    
    // MARK: - Предварительные фразовые и дефисные опечатки
    private func fixCommonSplitAndHyphenErrors(_ input: String) -> (text: String, fixCount: Int) {
        var text = input
        var fixes = 0
        
        // Слитные предлоги и не с глаголами
        let phraseReplacements: [(pattern: String, replacement: String)] = [
            ("(?i)\\bиз\\s+за\\b", "из-за"),
            ("(?i)\\bиз\\s+под\\b", "из-под"),
            ("(?i)\\bкое\\s+кто\\b", "кое-кто"),
            ("(?i)\\bкое\\s+что\\b", "кое-что"),
            ("(?i)\\bкое\\s+как\\b", "кое-как"),
            ("(?i)\\bчто\\s+то\\b", "что-то"),
            ("(?i)\\bгде\\s+то\\b", "где-то"),
            ("(?i)\\bкак\\s+то\\b", "как-то"),
            ("(?i)\\bкто\\s+то\\b", "кто-то"),
            ("(?i)\\bчто\\s+нибудь\\b", "что-нибудь"),
            ("(?i)\\bгде\\s+нибудь\\b", "где-нибудь"),
            ("(?i)\\bпо\\s+русски\\b", "по-русски"),
            ("(?i)\\bпо\\s+английски\\b", "по-английски"),
            ("(?i)\\bпо\\s+прежнему\\b", "по-прежнему"),
            ("(?i)\\bнезнаю\\b", "не знаю"),
            ("(?i)\\bнехочу\\b", "не хочу"),
            ("(?i)\\bнемогу\\b", "не могу"),
            ("(?i)\\bнебудет\\b", "не будет"),
            ("(?i)\\bнебыл\\b", "не был"),
            ("(?i)\\bнебыло\\b", "не было"),
            ("(?i)\\bвтечение\\b", "в течение"),
            ("(?i)\\bвпродолжение\\b", "в продолжение"),
            ("(?i)\\bвзаключение\\b", "в заключение"),
            ("(?i)\\bиметь\\s+ввиду\\b", "иметь в виду"),
            ("(?i)\\bиметь\\s+ввиде\\b", "иметь в виду")
        ]
        
        for p in phraseReplacements {
            if let regex = try? NSRegularExpression(pattern: p.pattern, options: []) {
                let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
                if !matches.isEmpty {
                    let mutable = NSMutableString(string: text)
                    for match in matches.reversed() {
                        let range = match.range(at: 0)
                        if range.location != NSNotFound {
                            let origStr = mutable.substring(with: range)
                            let replacementStr = matchCase(original: origStr, suggestion: p.replacement)
                            mutable.replaceCharacters(in: range, with: replacementStr)
                            fixes += 1
                        }
                    }
                    text = mutable as String
                }
            }
        }
        
        return (text, fixes)
    }
    
    // MARK: - Орфография (Hunspell + Безопасное ранжирование по Левенштейну)
    private func fixRussianSpelling(_ input: String) -> (text: String, fixCount: Int) {
        var text = input
        var fixes = 0
        
        guard let hunspellEngine = self.hunspell else {
            NSLog("[TextAssistantEngine] Hunspell engine unavailable")
            return (input, 0)
        }
        
        let words = extractWordsWithRanges(from: text)
        let mutable = NSMutableString(string: text)
        
        for item in words.reversed() {
            let word = item.word
            
            // Пропускаем однобуквенные слова, числа и аббревиатуры из ВСЕХ заглавных букв (США, РФ, API, JSON)
            if word.count < 2 || containsNonRussianOrDigits(word) || isAllCapsAcronym(word) {
                continue
            }
            
            // 1. Проверяем корректность слова в оригинальном и нижнем регистре
            var isWordCorrect = hunspellEngine.isCorrect(word) || hunspellEngine.isCorrect(word.lowercased())
            
            // 2. Проверка гипотезы буквы Ё (если слово пишется через "е", проверяем вариант через "ё")
            if !isWordCorrect && word.contains("е") {
                let yoWord = word.replacingOccurrences(of: "е", with: "ё")
                if hunspellEngine.isCorrect(yoWord) {
                    mutable.replaceCharacters(in: item.range, with: yoWord)
                    fixes += 1
                    continue
                }
            }
            
            if !isWordCorrect {
                var suggestions = hunspellEngine.suggest(word)
                if suggestions.isEmpty && word.first?.isUppercase == true {
                    suggestions = hunspellEngine.suggest(word.lowercased())
                }
                
                if let best = selectBestCandidate(for: word, from: suggestions), !best.isEmpty, best.lowercased() != word.lowercased() {
                    // Контроль безопасности: проверяем максимальное допустимое расстояние Левенштейна
                    let maxAllowedDist = maxAllowedDistance(forLength: word.count)
                    let dist = levenshteinDistance(word.lowercased(), best.lowercased())
                    
                    if dist <= maxAllowedDist {
                        let replacement = matchCase(original: word, suggestion: best)
                        mutable.replaceCharacters(in: item.range, with: replacement)
                        fixes += 1
                    }
                }
            }
        }
        
        return (mutable as String, fixes)
    }
    
    /// Безопасный порог максимального расстояния редактирования
    private func maxAllowedDistance(forLength length: Int) -> Int {
        if length <= 4 {
            return 1 // Для коротких слов (4 и менее букв) разрешаем максимум 1 замену
        } else if length <= 8 {
            return 2 // Для средних слов (5-8 букв) максимум 2 замены
        } else {
            return 3 // Для длинных слов (9+ букв) максимум 3 замены
        }
    }
    
    /// Проверка, является ли слово аббревиатурой из всех заглавных букв (США, РФ, МЧС, ГОСТ)
    private func isAllCapsAcronym(_ word: String) -> Bool {
        return word.count >= 2 && word == word.uppercased()
    }
    
    /// Алгоритм выбора наилучшего кандидата из подсказок Hunspell
    private func selectBestCandidate(for word: String, from suggestions: [String]) -> String? {
        let lowerWord = word.lowercased()
        
        // База частых разговорных опечаток и фонетических искажений
        let commonOverrides: [String: String] = [
            "нада": "надо",
            "вабще": "вообще",
            "вообщем": "в общем",
            "впринципе": "в принципе",
            "извените": "извините",
            "лутше": "лучше",
            "щас": "сейчас",
            "ща": "сейчас",
            "сиводня": "сегодня",
            "симпотичный": "симпатичный",
            "помоему": "по-моему",
            "зделал": "сделал",
            "зделаю": "сделаю",
            "прейти": "прийти",
            "расчитать": "рассчитать",
            "тож": "тоже",
            "ток": "только"
        ]
        if let override = commonOverrides[lowerWord] {
            return override
        }
        
        guard !suggestions.isEmpty else { return nil }
        
        // Ранжирование по минимальному дистанционному расстоянию Левенштейна и совпадению начального префикса
        var bestCandidate = suggestions.first!
        var minScore = Int.max
        
        for cand in suggestions {
            let lowerCand = cand.lowercased()
            let dist = levenshteinDistance(lowerWord, lowerCand)
            
            var prefixBonus = 0
            if lowerWord.prefix(1) == lowerCand.prefix(1) { prefixBonus += 2 }
            if lowerWord.prefix(2) == lowerCand.prefix(2) { prefixBonus += 3 }
            if lowerWord.prefix(3) == lowerCand.prefix(3) { prefixBonus += 4 }
            
            let score = dist * 10 - prefixBonus
            if score < minScore {
                minScore = score
                bestCandidate = cand
            }
        }
        
        return bestCandidate
    }
    
    private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let a1 = Array(s1)
        let a2 = Array(s2)
        var matrix = Array(repeating: Array(repeating: 0, count: a2.count + 1), count: a1.count + 1)
        
        for i in 0...a1.count { matrix[i][0] = i }
        for j in 0...a2.count { matrix[0][j] = j }
        
        if a1.count == 0 { return a2.count }
        if a2.count == 0 { return a1.count }
        
        for i in 1...a1.count {
            for j in 1...a2.count {
                if a1[i - 1] == a2[j - 1] {
                    matrix[i][j] = matrix[i - 1][j - 1]
                } else {
                    matrix[i][j] = min(
                        matrix[i - 1][j] + 1,
                        matrix[i][j - 1] + 1,
                        matrix[i - 1][j - 1] + 1
                    )
                }
            }
        }
        return matrix[a1.count][a2.count]
    }
    
    // MARK: - Расширенные правила пунктуации и типографики
    private func fixRussianPunctuation(_ input: String) -> (text: String, fixCount: Int) {
        var text = input
        var fixes = 0
        
        // Правило 1: Запятые перед союзами и придаточными словами
        let conjunctions = [
            "а", "но", "что", "чтобы", "если", "когда", "потому что", "так как",
            "хотя", "будто", "словно", "ежели", "ибо", "дабы", "пока", "прежде чем",
            "так что", "несмотря на то что", "ввиду того что", "благодаря тому что",
            "где", "куда", "откуда", "почему", "зачем", "сколько", "который", "которая", "которое", "которые"
        ]
        
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
        
        // Правило 1б: Запятая перед "как", ТОЛЬКО если это НЕ устойчивое выражение (фразеологизм)
        let rawAsPattern = "(?i)(?<=\\S)\\s+(как)\\s+([а-яа-яa-z0-9]+)"
        if let asRegex = try? NSRegularExpression(pattern: rawAsPattern, options: []) {
            let matches = asRegex.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
            let idiomSecondWords: Set<String> = ["надо", "следует", "можно", "минимум", "раз", "бы", "раньше", "всегда", "правило"]
            
            let mutable = NSMutableString(string: text)
            for match in matches.reversed() {
                let kakRange = match.range(at: 1)
                let secondWordRange = match.range(at: 2)
                
                if kakRange.location != NSNotFound && secondWordRange.location != NSNotFound {
                    let nextWord = (text as NSString).substring(with: secondWordRange).lowercased()
                    if !idiomSecondWords.contains(nextWord) {
                        mutable.insert(",", at: kakRange.location)
                        fixes += 1
                    }
                }
            }
            text = mutable as String
        }
        
        // Правило 2: Вводные слова в начале или внутри предложения
        let introductoryWords = [
            "конечно", "например", "к сожалению", "к счастью", "во-первых", "во-вторых",
            "в-третьих", "безусловно", "очевидно", "вероятно", "действительно",
            "между прочим", "с одной стороны", "с другой стороны", "кроме того", "впрочем",
            "кстати", "итак", "следовательно", "пожалуй", "напротив", "наоборот", "соответственно"
        ]
        
        for word in introductoryWords {
            let startPattern = "(?i)(?<=[.!?]\\s|^)(" + NSRegularExpression.escapedPattern(for: word) + ")\\s+(?=[а-яа-яa-z0-9])"
            if let regex = try? NSRegularExpression(pattern: startPattern, options: []) {
                let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
                if !matches.isEmpty {
                    let mutable = NSMutableString(string: text)
                    for match in matches.reversed() {
                        let range = match.range(at: 1)
                        if range.location != NSNotFound {
                            mutable.insert(",", at: range.location + range.length)
                            fixes += 1
                        }
                    }
                    text = mutable as String
                }
            }
        }
        
        // Правило 3: Удаление пробелов ПЕРЕД знаками препинания ( .,!?:; )
        let spaceBeforePunctRegex = try? NSRegularExpression(pattern: "\\s+([.,!?:;])", options: [])
        if let matches = spaceBeforePunctRegex?.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)), !matches.isEmpty {
            let mutable = NSMutableString(string: text)
            for match in matches.reversed() {
                let fullRange = match.range(at: 0)
                let punctRange = match.range(at: 1)
                if fullRange.location != NSNotFound && punctRange.location != NSNotFound {
                    let punctChar = mutable.substring(with: punctRange)
                    mutable.replaceCharacters(in: fullRange, with: punctChar)
                    fixes += 1
                }
            }
            text = mutable as String
        }
        
        // Правило 4: Пробелы ПОСЛЕ знаков препинания
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
        
        // Правило 5: Дефис ` - ` заменяется на длинное тире ` — `
        let dashRegex = try? NSRegularExpression(pattern: "(\\s)-(\\s)", options: [])
        if let matches = dashRegex?.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)), !matches.isEmpty {
            let mutable = NSMutableString(string: text)
            for match in matches.reversed() {
                let range = match.range(at: 0)
                if range.location != NSNotFound {
                    mutable.replaceCharacters(in: range, with: " — ")
                    fixes += 1
                }
            }
            text = mutable as String
        }
        
        // Правило 6: Двойные и множественные пробелы
        while text.contains("  ") {
            text = text.replacingOccurrences(of: "  ", with: " ")
            fixes += 1
        }
        
        // Правило 7: Заглавная буква в начале предложений и в самом начале текста
        if let firstChar = text.first, firstChar.isLowercase {
            text = text.prefix(1).uppercased() + text.dropFirst()
            fixes += 1
        }
        
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
        
        // Правило 8: Замена прямых кавычек "..." на ёлочки «...»
        let quotesRegex = try? NSRegularExpression(pattern: "\"([^\"]+)\"", options: [])
        if let matches = quotesRegex?.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)), !matches.isEmpty {
            let mutable = NSMutableString(string: text)
            for match in matches.reversed() {
                let fullRange = match.range(at: 0)
                let innerRange = match.range(at: 1)
                if fullRange.location != NSNotFound && innerRange.location != NSNotFound {
                    let innerText = mutable.substring(with: innerRange)
                    mutable.replaceCharacters(in: fullRange, with: "«\(innerText)»")
                    fixes += 1
                }
            }
            text = mutable as String
        }
        
        // Правило 9: Автоматическая точка в конце предложения (если текст состоит из нескольких слов и нет знака препинания)
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if wordCount(trimmed) >= 2 {
            if let lastChar = trimmed.last, lastChar != "." && lastChar != "!" && lastChar != "?" && lastChar != ":" && lastChar != "…" && lastChar != "»" {
                text = text + "."
                fixes += 1
            }
        }
        
        return (text, fixes)
    }
    
    // MARK: - Вспомогательные методы
    private struct WordItem {
        let word: String
        let range: NSRange
    }
    
    private func extractWordsWithRanges(from text: String) -> [WordItem] {
        var items: [WordItem] = []
        let range = NSRange(location: 0, length: text.utf16.count)
        
        if let regex = try? NSRegularExpression(pattern: "[А-Яа-яЁё]+(?:-[А-Яа-яЁё]+)*", options: []) {
            let matches = regex.matches(in: text, options: [], range: range)
            for match in matches {
                if let r = Range(match.range, in: text) {
                    let word = String(text[r])
                    items.append(WordItem(word: word, range: match.range))
                }
            }
        }
        return items
    }
    
    private func containsNonRussianOrDigits(_ word: String) -> Bool {
        for char in word {
            if char.isASCII || char.isNumber {
                return true
            }
        }
        return false
    }
    
    private func matchCase(original: String, suggestion: String) -> String {
        if original.first?.isUppercase == true {
            return suggestion.prefix(1).uppercased() + suggestion.dropFirst()
        }
        return suggestion
    }
    
    private func wordCount(_ text: String) -> Int {
        let components = text.components(separatedBy: .whitespacesAndNewlines)
        return components.filter { !$0.isEmpty }.count
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
