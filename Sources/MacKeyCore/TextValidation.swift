import Foundation

/// Shared by the editor and training store, so imported and saved texts obey
/// the same limits and keyboard compatibility rules.
public struct TextValidation: Sendable {
    public static let maximumLength = 50_000
    public let characterCount: Int
    public let normalized: String
    public let unsupported: [Character]
    public var isTooLong: Bool { characterCount > Self.maximumLength }
    public var canStart: Bool { !isTooLong && !normalized.isEmpty && unsupported.isEmpty }

    public init(text: String, supported: Set<Character>) {
        characterCount = text.count
        // Reject oversized paste before normalization, allocation and sorting.
        guard characterCount <= Self.maximumLength else {
            normalized = ""; unsupported = []; return
        }
        normalized = TypingEngine.normalize(text)
        unsupported = Set(normalized.filter { !supported.contains($0) }).sorted()
    }
}
