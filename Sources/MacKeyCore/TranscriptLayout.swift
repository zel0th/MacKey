import Foundation

/// Lossless, word-aware pagination. Character offsets remain those of TypingEngine.
public struct TranscriptLayout: Equatable, Sendable {
    public let lines: [Range<Int>]

    public init(characters: [Character] = [], capacity: Int = 40) {
        let capacity = max(1, capacity)
        var result: [Range<Int>] = []
        var start = 0
        while start < characters.count {
            var end = min(start + capacity, characters.count)
            if end < characters.count,
               let space = characters[start..<end].lastIndex(of: " "), space > start {
                end = space + 1
            }
            result.append(start..<end)
            start = end
        }
        lines = result
    }

    public func page(containing cursor: Int, lineCount: Int = 2) -> [Range<Int>] {
        guard !lines.isEmpty else { return [] }
        let count = max(1, lineCount)
        var low = 0, high = lines.count
        while low < high {
            let mid = (low + high) / 2
            if lines[mid].upperBound <= cursor { low = mid + 1 } else { high = mid }
        }
        let first = (min(low, lines.count - 1) / count) * count
        return Array(lines[first..<min(first + count, lines.count)])
    }
}
