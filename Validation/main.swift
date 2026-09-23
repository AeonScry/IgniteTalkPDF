import Foundation
import IgniteTalkCore

private struct CheckFailure: Error, CustomStringConvertible {
    let description: String
}

private func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    guard condition() else {
        throw CheckFailure(description: message)
    }
}

private func expectClose(_ actual: TimeInterval, _ expected: TimeInterval, _ message: String) throws {
    try expect(abs(actual - expected) < 0.001, "\(message): expected \(expected), got \(actual)")
}

private func runChecks() throws {
    var timeline = PresentationTimeline()
    timeline.start(at: 100)
    try expect(timeline.phase == .running, "Start should begin the presentation")
    try expect(timeline.currentPage == 0, "Start should show page 1")
    try expectClose(timeline.secondsRemaining(at: 100), 15, "Page 1 should receive a full interval")

    timeline.tick(at: 131.25)
    try expect(timeline.currentPage == 2, "A delayed tick should catch up by two pages")
    try expectClose(timeline.secondsRemaining(at: 131.25), 13.75, "Delayed ticks should preserve fractional elapsed time")
    timeline.tick(at: 145)
    try expect(timeline.currentPage == 3, "The timeline should remain anchored after a delayed tick")

    timeline = PresentationTimeline()
    timeline.start(at: 10)
    timeline.pause(at: 16)
    timeline.tick(at: 100)
    try expect(timeline.currentPage == 0, "Paused time must not advance pages")
    try expectClose(timeline.secondsRemaining(at: 100), 9, "Pause should preserve elapsed page time")
    timeline.resume(at: 100)
    timeline.tick(at: 109)
    try expect(timeline.currentPage == 1, "Resume should continue the preserved interval")

    timeline = PresentationTimeline()
    timeline.start(at: 0)
    timeline.tick(at: 8)
    timeline.next(at: 8)
    try expect(timeline.currentPage == 1, "Next should advance one page")
    try expectClose(timeline.secondsRemaining(at: 8), 15, "Next should reset the page interval")
    timeline.pause(at: 10)
    timeline.previous(at: 50)
    try expect(timeline.phase == .paused, "Navigation should preserve paused state")
    try expectClose(timeline.secondsRemaining(at: 50), 15, "Previous should reset the page interval")

    timeline = PresentationTimeline()
    timeline.start(at: 0)
    timeline.tick(at: 300)
    try expect(timeline.phase == .finished, "Twenty intervals should end the presentation")
    try expect(timeline.currentPage == 19, "Completion should follow page 20")
    timeline.tick(at: 900)
    timeline.next(at: 900)
    try expect(timeline.currentPage == 19, "Completion must not loop")

    timeline.previous(at: 901)
    try expect(timeline.currentPage == 18, "Previous should work after completion")
    try expect(timeline.phase == .paused, "Leaving completion should remain paused")
    timeline.restart(at: 1_000)
    try expect(timeline.currentPage == 0, "Restart should return to page 1")
    try expect(timeline.phase == .running, "Restart should begin playback")

    timeline = PresentationTimeline()
    timeline.start(at: 0)
    timeline.tick(at: 301)
    try expect(timeline.phase == .finished, "A delayed tick should finish the presentation without drift")
}

do {
    try runChecks()
    print("All IgniteTalkCore timing and state checks passed.")
} catch {
    fputs("Validation failed: \(error)\n", stderr)
    exit(1)
}
