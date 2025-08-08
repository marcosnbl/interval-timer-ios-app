import XCTest

final class IntervalTimerUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-UITesting"]
        app.launch()
    }
    
    func testCompleteWorkout() {
        
        // Primero verifica que estás en la pantalla principal
        XCTAssert(app.buttons["StartPauseContinueButton"].waitForExistence(timeout: 5))
        
        // Inicia el entrenamiento
        app.buttons["StartPauseContinueButton"].tap()
        
        // Espera y verifica la transición
        XCTAssert(app.staticTexts["Trabajo"].waitForExistence(timeout: 10))
        
        // 3. Pausar y reanudar
        app.buttons["Pausar"].tap()
        XCTAssert(app.buttons["Continuar"].exists)
        
        app.buttons["Continuar"].tap()
        XCTAssert(app.buttons["Pausar"].exists)
        
        // 4. Esperar a que termine (configuración rápida para pruebas)
        sleep(10)
        
        // 5. Verificar pantalla final
        XCTAssert(app.buttons["Volver a empezar"].exists)
    }
    
}
