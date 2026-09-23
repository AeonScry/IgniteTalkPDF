import Foundation

public struct PresentationTimeline: Equatable, Sendable {
    public enum Phase: Equatable, Sendable {
        case idle
        case running
        case paused
        case finished
    }

    public static let pageCount = 20
    public static let secondsPerPage: TimeInterval = 15

    public private(set) var currentPage = 0
    public private(set) var phase: Phase = .idle

    private var pageStartedAt: TimeInterval?
    private var elapsedBeforeStart: TimeInterval = 0

    public init() {}

    public var pageNumber: Int {
        currentPage + 1
    }

    public var canGoPrevious: Bool {
        currentPage > 0
    }

    public var canGoNext: Bool {
        phase == .running || phase == .paused
    }

    public func secondsRemaining(at now: TimeInterval) -> TimeInterval {
        guard phase != .finished else { return 0 }
        return max(0, Self.secondsPerPage - elapsedOnCurrentPage(at: now))
    }

    public mutating func start(at now: TimeInterval) {
        currentPage = 0
        elapsedBeforeStart = 0
        pageStartedAt = now
        phase = .running
    }

    public mutating func pause(at now: TimeInterval) {
        guard phase == .running else { return }
        tick(at: now)
        guard phase == .running else { return }

        elapsedBeforeStart = elapsedOnCurrentPage(at: now)
        pageStartedAt = nil
        phase = .paused
    }

    public mutating func resume(at now: TimeInterval) {
        guard phase == .paused else { return }
        pageStartedAt = now
        phase = .running
    }

    public mutating func togglePause(at now: TimeInterval) {
        switch phase {
        case .running:
            pause(at: now)
        case .paused:
            resume(at: now)
        case .idle, .finished:
            break
        }
    }

    public mutating func tick(at now: TimeInterval) {
        guard phase == .running else { return }

        let elapsed = elapsedOnCurrentPage(at: now)
        let pagesElapsed = Int(elapsed / Self.secondsPerPage)
        guard pagesElapsed > 0 else { return }

        if currentPage + pagesElapsed >= Self.pageCount {
            currentPage = Self.pageCount - 1
            elapsedBeforeStart = 0
            pageStartedAt = nil
            phase = .finished
            return
        }

        currentPage += pagesElapsed
        elapsedBeforeStart = elapsed.truncatingRemainder(dividingBy: Self.secondsPerPage)
        pageStartedAt = now
    }

    public mutating func previous(at now: TimeInterval) {
        guard currentPage > 0 else { return }
        if phase == .finished {
            phase = .paused
        }
        currentPage -= 1
        resetPageClock(at: now)
    }

    public mutating func next(at now: TimeInterval) {
        guard phase == .running || phase == .paused else { return }
        if currentPage == Self.pageCount - 1 {
            elapsedBeforeStart = 0
            pageStartedAt = nil
            phase = .finished
            return
        }
        currentPage += 1
        resetPageClock(at: now)
    }

    public mutating func restart(at now: TimeInterval) {
        start(at: now)
    }

    private func elapsedOnCurrentPage(at now: TimeInterval) -> TimeInterval {
        guard let pageStartedAt else { return elapsedBeforeStart }
        return elapsedBeforeStart + max(0, now - pageStartedAt)
    }

    private mutating func resetPageClock(at now: TimeInterval) {
        elapsedBeforeStart = 0
        pageStartedAt = phase == .running ? now : nil
    }
}
