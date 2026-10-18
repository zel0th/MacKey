import Foundation

/// At most one write and one pending snapshot. Submission order is established
/// on the main actor; encoding and atomic file replacement run off the UI thread.
@MainActor public final class StatePersistence {
    private let queue = DispatchQueue(label: "dev.mackey.persistence", qos: .utility)
    private let write: @Sendable (SavedState) throws -> Void
    private var pending: SavedState?
    private var writing = false
    private var waiters: [CheckedContinuation<String?, Never>] = []
    public private(set) var lastError: String?
    public var onError: ((String) -> Void)?

    public convenience init(url: URL) {
        self.init { state in
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(state)
            try data.write(to: url, options: .atomic)
        }
    }

    // Injectable disk operation allows deterministic ordering and failure tests.
    init(write: @escaping @Sendable (SavedState) throws -> Void) { self.write = write }

    public func enqueue(_ state: SavedState) {
        pending = state
        startNextWrite()
    }

    /// Returns only after the newest submitted snapshot has finished writing.
    public func flush() async -> String? {
        guard writing else { return lastError }
        return await withCheckedContinuation { waiters.append($0) }
    }

    private func startNextWrite() {
        guard !writing, let snapshot = pending else { return }
        pending = nil; writing = true
        let operation = write
        queue.async { [self] in
            let error: String?
            do { try operation(snapshot); error = nil }
            catch let failure { error = failure.localizedDescription }
            Task { @MainActor in
                lastError = error
                writing = false
                if let error { onError?(error) }
                if pending != nil { startNextWrite() }
                else {
                    let completed = waiters; waiters.removeAll()
                    for waiter in completed { waiter.resume(returning: error) }
                }
            }
        }
    }
}
