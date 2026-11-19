import SwiftUI

@main
struct MisPendientesApp: App {
    @State private var almacen: AlmacenTareas = ModoDemostracion.activo ? .demostracion() : AlmacenTareas()

    var body: some Scene {
        WindowGroup {
            ListaTareasView()
                .environment(almacen)
        }
    }
}

/// Argumentos de arranque para las capturas automáticas, por ejemplo: -demo YES -pantalla nueva
enum ModoDemostracion {
    static var activo: Bool { UserDefaults.standard.bool(forKey: "demo") }
    static var pantalla: String { UserDefaults.standard.string(forKey: "pantalla") ?? "lista" }
}
