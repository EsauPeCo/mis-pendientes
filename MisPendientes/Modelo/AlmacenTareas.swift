import Foundation
import Observation

/// Guarda las tareas en un archivo JSON dentro del contenedor de la app.
/// No hay servidor ni cuentas: los datos nunca salen del dispositivo.
@Observable
final class AlmacenTareas {
    private(set) var tareas: [Tarea] = []
    private let archivo: URL?

    init(archivo: URL? = AlmacenTareas.archivoPredeterminado) {
        self.archivo = archivo
        cargar()
    }

    static var archivoPredeterminado: URL? {
        let carpeta = try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                                   appropriateFor: nil, create: true)
        return carpeta?.appendingPathComponent("tareas.json")
    }

    /// Almacén en memoria con datos de ejemplo; no escribe en disco.
    static func demostracion() -> AlmacenTareas {
        let almacen = AlmacenTareas(archivo: nil)
        almacen.tareas = Tarea.ejemplos()
        return almacen
    }

    var pendientes: [Tarea] { tareas.filter { !$0.completada }.sorted(by: Self.orden) }
    var completadas: [Tarea] { tareas.filter(\.completada).sorted { $0.creada > $1.creada } }

    /// Primero las que tienen fecha (la más próxima arriba); después, por prioridad.
    static func orden(_ a: Tarea, _ b: Tarea) -> Bool {
        switch (a.fechaLimite, b.fechaLimite) {
        case let (x?, y?) where x != y:
            return x < y
        case (.some, nil):
            return true
        case (nil, .some):
            return false
        default:
            if a.prioridad != b.prioridad { return a.prioridad > b.prioridad }
            return a.creada < b.creada
        }
    }

    func agregar(_ tarea: Tarea) {
        tareas.append(tarea)
        guardar()
    }

    func actualizar(_ tarea: Tarea) {
        guard let i = tareas.firstIndex(where: { $0.id == tarea.id }) else { return }
        tareas[i] = tarea
        guardar()
    }

    func alternar(_ tarea: Tarea) {
        guard let i = tareas.firstIndex(where: { $0.id == tarea.id }) else { return }
        tareas[i].completada.toggle()
        guardar()
    }

    func eliminar(_ tarea: Tarea) {
        tareas.removeAll { $0.id == tarea.id }
        guardar()
    }

    private func cargar() {
        guard let archivo, let datos = try? Data(contentsOf: archivo) else { return }
        tareas = (try? JSONDecoder().decode([Tarea].self, from: datos)) ?? []
    }

    private func guardar() {
        guard let archivo else { return }
        do {
            let datos = try JSONEncoder().encode(tareas)
            // completeFileProtection: el sistema cifra el archivo mientras el teléfono está bloqueado.
            try datos.write(to: archivo, options: [.atomic, .completeFileProtection])
        } catch {
            print("No se pudieron guardar las tareas: \(error)")
        }
    }
}
