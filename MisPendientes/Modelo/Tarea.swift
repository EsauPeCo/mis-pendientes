import Foundation

enum Prioridad: Int, Codable, CaseIterable, Identifiable, Comparable {
    case baja = 0, media = 1, alta = 2

    var id: Int { rawValue }

    var nombre: String {
        switch self {
        case .baja: return "Baja"
        case .media: return "Media"
        case .alta: return "Alta"
        }
    }

    static func < (a: Prioridad, b: Prioridad) -> Bool { a.rawValue < b.rawValue }
}

struct Tarea: Identifiable, Codable, Equatable {
    var id = UUID()
    var titulo: String
    var notas: String = ""
    var fechaLimite: Date? = nil
    var prioridad: Prioridad = .media
    var completada = false
    var creada = Date()

    /// Una tarea está vencida si sigue pendiente y su fecha límite ya pasó.
    func vencida(hoy: Date = .now) -> Bool {
        guard let fechaLimite, !completada else { return false }
        let calendario = Calendar.current
        return calendario.startOfDay(for: fechaLimite) < calendario.startOfDay(for: hoy)
    }

    static func textoFecha(_ fecha: Date) -> String {
        let calendario = Calendar.current
        if calendario.isDateInToday(fecha) { return "Hoy" }
        if calendario.isDateInTomorrow(fecha) { return "Mañana" }
        return fecha.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
    }
}

extension Tarea {
    /// Datos de ejemplo para el modo de demostración (capturas y vista previa de la tienda).
    static func ejemplos(hoy: Date = .now) -> [Tarea] {
        let calendario = Calendar.current
        func dia(_ n: Int) -> Date {
            calendario.date(byAdding: .day, value: n, to: calendario.startOfDay(for: hoy)) ?? hoy
        }
        return [
            Tarea(titulo: "Entregar el Reto 5 de Despliegue", notas: "Documento en PDF con las capturas de cada paso",
                  fechaLimite: dia(0), prioridad: .alta),
            Tarea(titulo: "Pagar el recibo de luz", fechaLimite: dia(1), prioridad: .alta),
            Tarea(titulo: "Participar en el foro de la unidad", notas: "Dos retroalimentaciones a compañeros",
                  fechaLimite: dia(2), prioridad: .media),
            Tarea(titulo: "Comprar despensa", notas: "Tortillas, huevo, frijol y café", fechaLimite: dia(3), prioridad: .media),
            Tarea(titulo: "Llevar el auto a servicio", fechaLimite: dia(6), prioridad: .baja),
            Tarea(titulo: "Leer el capítulo 4 del libro de Swift", prioridad: .baja),
            Tarea(titulo: "Respaldar las fotos del teléfono", prioridad: .media, completada: true),
            Tarea(titulo: "Renovar la credencial de la biblioteca", fechaLimite: dia(-2), prioridad: .baja, completada: true),
        ]
    }

    static func ejemploNueva(hoy: Date = .now) -> Tarea {
        let fecha = Calendar.current.date(byAdding: .day, value: 4, to: Calendar.current.startOfDay(for: hoy))
        return Tarea(titulo: "Preparar la exposición de Despliegue", notas: "Diapositivas y demostración de la app",
                     fechaLimite: fecha, prioridad: .alta)
    }
}
