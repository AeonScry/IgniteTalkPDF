import Foundation
import Testing
import IgniteTalkCore

@Test
func startBeginsOnFirstPageWithFullInterval() {
    var timeline = PresentationTimeline()

    timeline.start(at: 100)

    #expect(timeline.phase == .running)
    #expect(timeline.currentPage == 0)
    #expect(abs(timeline.secondsRemaining(at: 100) - 15) < 0.001)
}

@Test
func delayedTickCatchesUpWithoutAccumulatingDrift() {
    var timeline = PresentationTimeline()
    timeline.start(at: 100)

    timeline.tick(at: 131.25)

    #expect(timeline.currentPage == 2)
    #expect(abs(timeline.secondsRemaining(at: 131.25) - 13.75) < 0.001)

    timeline.tick(at: 145)
    #expect(timeline.currentPage == 3)
    #expect(abs(timeline.secondsRemaining(at: 145) - 15) < 0.001)
}

@Test
func pauseAndResumeExcludePausedTime() {
    var timeline = PresentationTimeline()
    timeline.start(at: 10)
    timeline.pause(at: 16)

    timeline.tick(at: 100)
    #expect(timeline.currentPage == 0)
    #expect(abs(timeline.secondsRemaining(at: 100) - 9) < 0.001)

    timeline.resume(at: 100)
    timeline.tick(at: 109)
    #expect(timeline.currentPage == 1)
    #expect(abs(timeline.secondsRemaining(at: 109) - 15) < 0.001)
}

@Test
func manualNavigationResetsPageClockAndPreservesPlaybackState() {
    var timeline = PresentationTimeline()
    timeline.start(at: 0)
    timeline.tick(at: 8)

    timeline.next(at: 8)
    #expect(timeline.currentPage == 1)
    #expect(timeline.phase == .running)
    #expect(abs(timeline.secondsRemaining(at: 8) - 15) < 0.001)

    timeline.pause(at: 10)
    timeline.previous(at: 50)
    #expect(timeline.currentPage == 0)
    #expect(timeline.phase == .paused)
    #expect(abs(timeline.secondsRemaining(at: 50) - 15) < 0.001)
}

@Test
func presentationStopsAfterTwentyPagesWithoutLooping() {
    var timeline = PresentationTimeline()
    timeline.start(at: 0)

    timeline.tick(at: 300)
    #expect(timeline.phase == .finished)
    #expect(timeline.currentPage == 19)

    timeline.tick(at: 900)
    timeline.next(at: 900)
    #expect(timeline.currentPage == 19)
    #expect(timeline.phase == .finished)
}

@Test
func nextFromLastPageFinishesAndPreviousReturnsPaused() {
    var timeline = PresentationTimeline()
    timeline.start(at: 0)
    for second in 1...19 {
        timeline.next(at: TimeInterval(second))
    }

    #expect(timeline.currentPage == 19)
    #expect(timeline.phase == .running)

    timeline.next(at: 20)
    #expect(timeline.phase == .finished)

    timeline.previous(at: 21)
    #expect(timeline.currentPage == 18)
    #expect(timeline.phase == .paused)
}

@Test
func restartAlwaysReturnsToRunningFirstPage() {
    var timeline = PresentationTimeline()
    timeline.start(at: 0)
    timeline.tick(at: 300)

    timeline.restart(at: 500)

    #expect(timeline.phase == .running)
    #expect(timeline.currentPage == 0)
    #expect(abs(timeline.secondsRemaining(at: 500) - 15) < 0.001)
}

@Test
func delayedTickCanFinishPresentationWithoutDrift() {
    var timeline = PresentationTimeline()
    timeline.start(at: 0)

    timeline.tick(at: 301)

    #expect(timeline.phase == .finished)
    #expect(timeline.currentPage == 19)
}
