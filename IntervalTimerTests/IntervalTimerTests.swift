import XCTest
@testable import IntervalTimer

// MARK: - TimerManager Tests

@MainActor
final class TimerManagerTests: XCTestCase {

    var timerManager: TimerManager!

    override func setUp() {
        super.setUp()
        timerManager = TimerManager()
        // Configuración de test con tiempos cortos
        timerManager.updateConfig { config in
            config.prepSeconds = 2
            config.workSeconds = 2
            config.restSeconds = 2
            config.rounds = 2
            config.cooldownSeconds = 2
        }
    }

    override func tearDown() {
        timerManager.reset()
        timerManager = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState() {
        XCTAssertEqual(timerManager.phase, .prep)
        XCTAssertEqual(timerManager.state, .idle)
        XCTAssertEqual(timerManager.currentRound, 1)
        XCTAssertFalse(timerManager.isRunning)
        XCTAssertFalse(timerManager.isPaused)
    }

    func testCanStartFromIdleState() {
        XCTAssertTrue(timerManager.canStart)
    }

    // MARK: - Start Tests

    func testStartTimer() {
        timerManager.start()

        XCTAssertEqual(timerManager.state, .running)
        XCTAssertTrue(timerManager.isRunning)
        XCTAssertEqual(timerManager.phase, .prep)
    }

    func testStartDoesNothingIfAlreadyRunning() {
        timerManager.start()
        let initialRemaining = timerManager.remainingSeconds

        timerManager.start() // Second start should be ignored

        XCTAssertEqual(timerManager.remainingSeconds, initialRemaining)
        XCTAssertTrue(timerManager.isRunning)
    }

    // MARK: - Pause/Resume Tests

    func testPauseTimer() {
        timerManager.start()
        timerManager.pause()

        XCTAssertEqual(timerManager.state, .paused)
        XCTAssertTrue(timerManager.isPaused)
        XCTAssertFalse(timerManager.isRunning)
    }

    func testResumeTimer() {
        timerManager.start()
        timerManager.pause()
        timerManager.resume()

        XCTAssertEqual(timerManager.state, .running)
        XCTAssertTrue(timerManager.isRunning)
        XCTAssertFalse(timerManager.isPaused)
    }

    func testPauseDoesNothingIfNotRunning() {
        timerManager.pause()

        XCTAssertEqual(timerManager.state, .idle)
    }

    // MARK: - Reset Tests

    func testResetFromRunning() {
        timerManager.start()
        timerManager.reset()

        XCTAssertEqual(timerManager.state, .idle)
        XCTAssertEqual(timerManager.phase, .prep)
        XCTAssertEqual(timerManager.currentRound, 1)
    }

    func testResetFromPaused() {
        timerManager.start()
        timerManager.pause()
        timerManager.reset()

        XCTAssertEqual(timerManager.state, .idle)
        XCTAssertEqual(timerManager.phase, .prep)
    }

    // MARK: - Toggle Tests

    func testToggleFromIdle() {
        timerManager.toggle()

        XCTAssertEqual(timerManager.state, .running)
    }

    func testToggleFromRunning() {
        timerManager.start()
        timerManager.toggle()

        XCTAssertEqual(timerManager.state, .paused)
    }

    func testToggleFromPaused() {
        timerManager.start()
        timerManager.pause()
        timerManager.toggle()

        XCTAssertEqual(timerManager.state, .running)
    }

    // MARK: - Config Tests

    func testUpdateConfig() {
        timerManager.updateConfig { $0.workSeconds = 45 }

        XCTAssertEqual(timerManager.config.workSeconds, 45)
    }

    func testConfigUpdateResetsRemainingWhenIdle() {
        timerManager.updateConfig { $0.prepSeconds = 15 }

        XCTAssertEqual(timerManager.remainingSeconds, 15)
    }

    // MARK: - Computed Properties Tests

    func testFormattedTime() {
        timerManager.updateConfig { $0.prepSeconds = 125 } // 2:05

        XCTAssertEqual(timerManager.formattedTime, "02:05")
    }

    func testRoundDisplay() {
        XCTAssertEqual(timerManager.roundDisplay, "RONDA 1 DE 2")
    }

    func testProgress() {
        timerManager.updateConfig { $0.prepSeconds = 10 }

        // Al inicio, progress debe ser 0
        XCTAssertEqual(timerManager.progress, 0.0, accuracy: 0.01)
    }
}

// MARK: - TimerConfig Tests

final class TimerConfigTests: XCTestCase {

    func testDefaultValues() {
        let config = TimerConfig()

        XCTAssertEqual(config.prepSeconds, 10)
        XCTAssertEqual(config.workSeconds, 20)
        XCTAssertEqual(config.restSeconds, 10)
        XCTAssertEqual(config.rounds, 8)
        XCTAssertEqual(config.cooldownSeconds, 30)
    }

    func testPrepDisplay() {
        var config = TimerConfig()
        config.prepSeconds = 45

        XCTAssertEqual(config.prepDisplay, "45 s")
    }

    func testWorkDisplayWithMinutes() {
        var config = TimerConfig()
        config.workSeconds = 90

        XCTAssertEqual(config.workDisplay, "1:30")
    }

    func testCooldownDisplayNone() {
        var config = TimerConfig()
        config.cooldownSeconds = 0

        XCTAssertEqual(config.cooldownDisplay, "Ninguno")
    }

    func testTotalDuration() {
        let config = TimerConfig(
            prepSeconds: 10,
            workSeconds: 20,
            restSeconds: 10,
            rounds: 8,
            cooldownSeconds: 30
        )

        // 10 + (20*8) + (10*7) + 30 = 10 + 160 + 70 + 30 = 270
        XCTAssertEqual(config.totalDuration, 270)
    }

    func testPresets() {
        let tabata = TimerConfig.tabataClassic

        XCTAssertEqual(tabata.workSeconds, 20)
        XCTAssertEqual(tabata.restSeconds, 10)
        XCTAssertEqual(tabata.rounds, 8)
    }

    func testCodable() throws {
        let config = TimerConfig(
            prepSeconds: 15,
            workSeconds: 30,
            restSeconds: 15,
            rounds: 6,
            cooldownSeconds: 60
        )

        let encoded = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(TimerConfig.self, from: encoded)

        XCTAssertEqual(config, decoded)
    }
}

// MARK: - Legacy TimerViewModel Tests (Backward Compatibility)

@MainActor
final class TimerViewModelTests: XCTestCase {

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
        viewModel.resetToInitialState()
        viewModel = nil
        super.tearDown()
    }

    func testInitialState() {
        XCTAssertEqual(viewModel.currentPhase, .prep)
        XCTAssertFalse(viewModel.hasStarted)
        XCTAssertFalse(viewModel.isPaused)
    }

    func testStartTimer() {
        viewModel.start()

        XCTAssertTrue(viewModel.hasStarted)
        XCTAssertEqual(viewModel.currentPhase, .prep)
        XCTAssertFalse(viewModel.isPaused)
    }

    func testPause() {
        viewModel.start()
        viewModel.pause()

        XCTAssertTrue(viewModel.isPaused)
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
}
