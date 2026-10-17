/// A bounded page of a collection. Empty collections have one empty page.
public struct PageWindow: Equatable, Sendable {
    public let index: Int
    public let pageCount: Int
    public let range: Range<Int>
    public var hasPrevious: Bool { index > 0 }
    public var hasNext: Bool { index + 1 < pageCount }

    public init(itemCount: Int, pageSize: Int, requestedIndex: Int) {
        let count = max(0, itemCount)
        let size = max(1, pageSize)
        pageCount = count == 0 ? 1 : (count - 1) / size + 1
        index = min(max(0, requestedIndex), pageCount - 1)
        let start = index * size
        range = start..<(start + min(size, count - start))
    }
}
