import XCTest

final class IntervalTimerUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-UITesting"]
        app.launch()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // MARK: - Main Screen Tests

    func testMainScreenElements() {
        // Verificar que el botón principal existe
        XCTAssert(app.buttons["MainActionButton"].waitForExistence(timeout: 5))

        // Verificar que el botón de configuración existe
        XCTAssert(app.buttons["SettingsButton"].exists)

        // Verificar que se muestra el texto de preparación
        XCTAssert(app.staticTexts["PREPÁRATE"].exists)
    }

    func testStartTimer() {
        // Iniciar el timer
        app.buttons["MainActionButton"].tap()

        // Esperar a que cambie a fase de trabajo
        XCTAssert(app.staticTexts["¡TRABAJO!"].waitForExistence(timeout: 15))
    }

    func testPauseAndResume() {
        // Iniciar
        app.buttons["MainActionButton"].tap()

        // Esperar un momento
        sleep(1)

        // Pausar (el mismo botón ahora es pause)
        app.buttons["MainActionButton"].tap()

        // Esperar que la UI se actualice
        sleep(1)

        // Reanudar
        app.buttons["MainActionButton"].tap()

        // Verificar que sigue funcionando
        XCTAssert(app.buttons["MainActionButton"].exists)
    }

    func testNavigateToSettings() {
        // Ir a configuración
        app.buttons["SettingsButton"].tap()

        // Verificar que estamos en la pantalla de configuración
        XCTAssert(app.navigationBars["Configuración"].waitForExistence(timeout: 3))

        // Verificar elementos de configuración
        XCTAssert(app.staticTexts["Preparación"].exists)
        XCTAssert(app.staticTexts["Trabajo"].exists)
        XCTAssert(app.staticTexts["Descanso"].exists)
        XCTAssert(app.staticTexts["Rondas"].exists)
    }

    func testSettingsDisabledWhileRunning() {
        // Iniciar el timer
        app.buttons["MainActionButton"].tap()

        // El botón de settings debería estar deshabilitado
        let settingsButton = app.buttons["SettingsButton"]
        XCTAssertFalse(settingsButton.isEnabled)
    }
}
