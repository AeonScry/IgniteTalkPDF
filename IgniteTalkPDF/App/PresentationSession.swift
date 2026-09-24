import Foundation
import IgniteTalkCore

@MainActor
final class PresentationSession: ObservableObject {
    @Published private(set) var timeline = PresentationTimeline()
    @Published private(set) var secondsRemaining = PresentationTimeline().secondsPerPage

    var currentPage: Int { timeline.currentPage }
    var phase: PresentationTimeline.Phase { timeline.phase }

    func start() {
        update { $0.start(at: $1) }
    }

    func start(pageCount: Int) {
        timeline = PresentationTimeline(pageCount: pageCount)
        update { $0.start(at: $1) }
    }

    func tick() {
        update { $0.tick(at: $1) }
    }

    func togglePause() {
        update { $0.togglePause(at: $1) }
    }

    func previous() {
        update { $0.previous(at: $1) }
    }

    func next() {
        update { $0.next(at: $1) }
    }

    func restart() {
        update { $0.restart(at: $1) }
    }

    func pause() {
        update { $0.pause(at: $1) }
    }

    private var monotonicNow: TimeInterval {
        ProcessInfo.processInfo.systemUptime
    }

    private func update(_ operation: (inout PresentationTimeline, TimeInterval) -> Void) {
        let now = monotonicNow
        operation(&timeline, now)
        secondsRemaining = timeline.secondsRemaining(at: now)
    }
}
