import XCTest

/// Recorrido que se graba con `simctl io recordVideo` para la vista previa (App Preview) de la tienda.
final class RecorridoUITests: XCTestCase {
    func testRecorridoParaVistaPrevia() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-demo", "YES", "-pantalla", "video", "-AppleLanguages", "(es-MX)", "-AppleLocale", "es_MX"]
        app.launch()
        pausa(3)

        // 1. Agregar una tarea nueva
        app.buttons["nueva"].tap()
        let titulo = app.textFields["titulo"]
        XCTAssertTrue(titulo.waitForExistence(timeout: 5))
        titulo.tap()
        titulo.typeText("Estudiar para el examen de Swift")
        pausa(1.5)
        app.buttons["guardar"].tap()
        pausa(2.5)

        // 2. Completar la tarea más urgente
        app.buttons["Marcar como completada"].firstMatch.tap()
        pausa(2.5)

        // 3. Revisar las completadas y volver
        app.buttons["Completadas"].firstMatch.tap()
        pausa(3)
        app.buttons["Pendientes"].firstMatch.tap()
        pausa(2)

        // 4. Abrir el aviso de privacidad
        app.buttons["Privacidad"].firstMatch.tap()
        pausa(3.5)
        app.buttons["Listo"].firstMatch.tap()
        pausa(2)
    }

    private func pausa(_ segundos: TimeInterval) {
        Thread.sleep(forTimeInterval: segundos)
    }
}
