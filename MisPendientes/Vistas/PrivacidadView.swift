import SwiftUI

struct PrivacidadView: View {
    @Environment(\.dismiss) private var cerrar

    private static let sitio = "https://esaupeco.github.io/mis-pendientes/"

    var body: some View {
        NavigationStack {
            List {
                Section("Resumen") {
                    Label("Tus tareas se guardan solo en este iPhone y en sus respaldos, si los tienes activados.",
                          systemImage: "iphone")
                    Label("El archivo de tareas está cifrado por el sistema mientras el teléfono está bloqueado.",
                          systemImage: "lock")
                    Label("No hay cuentas, anuncios ni analítica, y la app no se conecta a internet.",
                          systemImage: "wifi.slash")
                    Label("No recopilamos ni compartimos datos personales.", systemImage: "hand.raised")
                    Label("Si eliminas la app, se eliminan también tus tareas.", systemImage: "trash")
                }
                Section("Más información") {
                    if let politica = URL(string: Self.sitio + "privacidad.html") {
                        Link("Política de privacidad completa", destination: politica)
                    }
                    if let soporte = URL(string: Self.sitio + "soporte.html") {
                        Link("Soporte", destination: soporte)
                    }
                }
                Section {
                    LabeledContent("Versión", value: version)
                }
            }
            .navigationTitle("Privacidad")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo") { cerrar() }
                }
            }
        }
    }

    private var version: String {
        let info = Bundle.main.infoDictionary
        let corta = info?["CFBundleShortVersionString"] as? String ?? "?"
        let compilacion = info?["CFBundleVersion"] as? String ?? "?"
        return "\(corta) (\(compilacion))"
    }
}
