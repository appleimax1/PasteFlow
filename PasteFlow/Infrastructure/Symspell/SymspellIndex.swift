import Foundation

/// Lightweight SymSpell-inspired index for O(1) fuzzy word lookup.
///
/// Precomputes a delete-table: for each dictionary word, generates all variants
/// with 1 character deleted. At lookup time, the same delete variants of the
/// input word are used to find candidate matches in constant time.
///
/// Memory footprint: ~3-5 MB for a 200K-word dictionary (maxDeleteDistance = 1).
final class SymspellIndex {
    static let shared = SymspellIndex()

    /// Maps a delete variant to the set of original words that produce it.
    private var deleteTable: [String: Set<String>] = [:]

    /// All words currently in the index (for fast membership check).
    private var allWords: Set<String> = []

    private(set) var isLoaded = false

    private init() {}

    // MARK: - Loading

    /// Load words from .dic dictionary files.
    /// Only base forms are indexed (affix expansions are handled by Hunspell).
    func load(fromDicPaths dicPaths: [String]) {
        guard !dicPaths.isEmpty else { return }

        var words: Set<String> = []

        for dicPath in dicPaths {
            guard let content = try? String(contentsOfFile: dicPath, encoding: .utf8) else {
                continue
            }
            for line in content.components(separatedBy: .newlines) {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { continue }
                // .dic format: word[/flags] or word count[/flags]
                let parts = trimmed.split(separator: " ", maxSplits: 1)
                guard let firstPart = parts.first else { continue }
                let wordPart = String(firstPart)
                // Remove affix flags (everything after '/')
                let baseWord = wordPart.split(separator: "/", maxSplits: 1).first.map(String.init) ?? wordPart
                guard baseWord.count >= 3 else { continue } // Skip very short words
                words.insert(baseWord.lowercased())
            }
        }

        allWords = words
        buildDeleteTable(from: words, maxDeleteDistance: 1)
        isLoaded = true
    }

    // MARK: - Lookup

    /// Find candidate corrections for a misspelled word.
    /// Returns candidates sorted by edit distance (ascending).
    func lookup(word: String, maxDistance: Int = 2) -> [(candidate: String, distance: Int)] {
        guard isLoaded else { return [] }
        let lower = word.lowercased()

        // Exact match — word is correct
        if allWords.contains(lower) {
            return []
        }

        var candidates: [String: Int] = [:]

        // Generate delete variants of the input word
        let deleteVariants = generateDeleteVariants(of: lower, maxDistance: 1)

        for variant in deleteVariants {
            guard let matchingWords = deleteTable[variant] else { continue }
            for match in matchingWords {
                let dist = fastLevenshtein(lower, match, maxDistance: maxDistance)
                if dist <= maxDistance {
                    if let existing = candidates[match] {
                        candidates[match] = min(existing, dist)
                    } else {
                        candidates[match] = dist
                    }
                }
            }
        }

        return candidates
            .sorted { $0.value < $1.value }
            .map { (candidate: $0.key, distance: $0.value) }
    }

    // MARK: - Delete Table Construction

    private func buildDeleteTable(from words: Set<String>, maxDeleteDistance: Int) {
        for word in words {
            let variants = generateDeleteVariants(of: word, maxDistance: maxDeleteDistance)
            for variant in variants {
                deleteTable[variant, default: []].insert(word)
            }
            // Also index the word itself (distance 0)
            deleteTable[word, default: []].insert(word)
        }
    }

    private func generateDeleteVariants(of word: String, maxDistance: Int) -> [String] {
        var variants: [String] = []
        let chars = Array(word)

        if maxDistance >= 1 {
            for i in 0..<chars.count {
                var variant = chars
                variant.remove(at: i)
                variants.append(String(variant))
            }
        }

        return variants
    }

    // MARK: - Fast Levenshtein with early exit

    private func fastLevenshtein(_ s1: String, _ s2: String, maxDistance: Int) -> Int {
        let a1 = Array(s1)
        let a2 = Array(s2)

        let len1 = a1.count
        let len2 = a2.count

        if len1 == 0 { return len2 }
        if len2 == 0 { return len1 }
        if abs(len1 - len2) > maxDistance { return maxDistance + 1 }

        // Optimised: only compute if lengths are close enough
        var prevRow = Array(0...len2)
        var currRow = Array(repeating: 0, count: len2 + 1)

        for i in 1...len1 {
            currRow[0] = i
            var minInRow = i

            for j in 1...len2 {
                let cost = a1[i - 1] == a2[j - 1] ? 0 : 1
                currRow[j] = min(
                    prevRow[j] + 1,
                    currRow[j - 1] + 1,
                    prevRow[j - 1] + cost
                )
                minInRow = min(minInRow, currRow[j])
            }

            // Early exit: if minimum in current row exceeds maxDistance
            if minInRow > maxDistance {
                return maxDistance + 1
            }

            let temp = prevRow
            prevRow = currRow
            currRow = temp
        }

        return prevRow[len2]
    }
}
