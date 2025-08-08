import XCTest
@testable import IntervalTimer

@MainActor 
final class IntervalTimerTests: XCTestCase {
    
    var viewModel: TimerViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = TimerViewModel()
        viewModel.config = TimerConfig(
            prepSeconds: 5,
            workSeconds: 5,
            restSeconds: 5,
            rounds: 2,
            cooldownSeconds: 7
        )
    }
    
    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }
    
    func testInitialState() {
        XCTAssertEqual(viewModel.currentPhase, .prep)
        XCTAssertEqual(viewModel.remaining, 5)
        XCTAssertFalse(viewModel.hasStarted)
        XCTAssertFalse(viewModel.isPaused)
    }
    
    func testStartTimer() {
        viewModel.start()
        
        XCTAssertTrue(viewModel.hasStarted)
        XCTAssertEqual(viewModel.currentPhase, .prep)
        XCTAssertFalse(viewModel.isPaused)
    }
    
    func testPauseAndResume() {
        viewModel.start()
        viewModel.pause()
        
        XCTAssertTrue(viewModel.isPaused)
        
        let remainingBeforePause = viewModel.remaining
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            Task { @MainActor in
                XCTAssertEqual(self.viewModel.remaining, remainingBeforePause)
                self.viewModel.resume()
                XCTAssertFalse(self.viewModel.isPaused)
            }
        }
    }
    
    func testReset() {
        viewModel.start()
        viewModel.pause()
        viewModel.resetToInitialState()
        
        XCTAssertEqual(viewModel.currentPhase, .prep)
        XCTAssertEqual(viewModel.currentRound, 1)
        XCTAssertFalse(viewModel.isPaused)
        XCTAssertFalse(viewModel.hasStarted)
    }
    
    func testCompleteWorkout() async {
        viewModel.start()
        
        // Prep (5s)
        try? await Task.sleep(nanoseconds: 5_500_000_000)
        XCTAssertEqual(viewModel.currentPhase, .work)
        
        // Work (5s)
        try? await Task.sleep(nanoseconds: 5_500_000_000)
        XCTAssertEqual(viewModel.currentPhase, .rest)
        
        // Rest (5s) - Primera ronda
        try? await Task.sleep(nanoseconds: 5_500_000_000)
        XCTAssertEqual(viewModel.currentPhase, .work)
        
        // Work (5s) - Segunda ronda
        try? await Task.sleep(nanoseconds: 5_500_000_000)
        XCTAssertEqual(viewModel.currentPhase, .cooldown)
        
        // Cooldown (7s)
        try? await Task.sleep(nanoseconds: 7_500_000_000)
        XCTAssertEqual(viewModel.currentPhase, .done)
    }
}
