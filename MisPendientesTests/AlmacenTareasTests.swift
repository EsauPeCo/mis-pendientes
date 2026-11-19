import XCTest
@testable import MisPendientes

final class AlmacenTareasTests: XCTestCase {
    private var archivo: URL!

    override func setUp() {
        super.setUp()
        archivo = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: archivo)
        super.tearDown()
    }

    func testAgregarYPersistir() {
        let almacen = AlmacenTareas(archivo: archivo)
        almacen.agregar(Tarea(titulo: "Comprar pan"))
        let recargado = AlmacenTareas(archivo: archivo)
        XCTAssertEqual(recargado.tareas.map(\.titulo), ["Comprar pan"])
    }

    func testAlternarMueveLaTareaACompletadas() {
        let almacen = AlmacenTareas(archivo: archivo)
        let tarea = Tarea(titulo: "Lavar ropa")
        almacen.agregar(tarea)
        almacen.alternar(tarea)
        XCTAssertTrue(almacen.pendientes.isEmpty)
        XCTAssertEqual(almacen.completadas.first?.id, tarea.id)
    }

    func testOrdenPorFechaYDespuesPorPrioridad() {
        let hoy = Calendar.current.startOfDay(for: .now)
        let manana = Calendar.current.date(byAdding: .day, value: 1, to: hoy)!
        let almacen = AlmacenTareas(archivo: archivo)
        almacen.agregar(Tarea(titulo: "Sin fecha baja", prioridad: .baja))
        almacen.agregar(Tarea(titulo: "Mañana", fechaLimite: manana))
        almacen.agregar(Tarea(titulo: "Sin fecha alta", prioridad: .alta))
        almacen.agregar(Tarea(titulo: "Hoy", fechaLimite: hoy))
        XCTAssertEqual(almacen.pendientes.map(\.titulo), ["Hoy", "Mañana", "Sin fecha alta", "Sin fecha baja"])
    }

    func testTareaVencida() {
        let ayer = Calendar.current.date(byAdding: .day, value: -1, to: .now)!
        XCTAssertTrue(Tarea(titulo: "Atrasada", fechaLimite: ayer).vencida())
        XCTAssertFalse(Tarea(titulo: "Hecha", fechaLimite: ayer, completada: true).vencida())
        XCTAssertFalse(Tarea(titulo: "Sin fecha").vencida())
    }

    func testEliminar() {
        let almacen = AlmacenTareas(archivo: archivo)
        let tarea = Tarea(titulo: "Borrar")
        almacen.agregar(tarea)
        almacen.eliminar(tarea)
        XCTAssertTrue(AlmacenTareas(archivo: archivo).tareas.isEmpty)
    }
}
