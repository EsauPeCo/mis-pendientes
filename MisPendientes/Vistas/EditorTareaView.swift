import SwiftUI

struct EditorTareaView: View {
    @Environment(AlmacenTareas.self) private var almacen
    @Environment(\.dismiss) private var cerrar

    private let original: Tarea?
    @State private var borrador: Tarea
    @State private var conFecha: Bool
    @FocusState private var enfocado: Bool

    init(tarea: Tarea?) {
        original = tarea
        let base: Tarea
        if let tarea {
            base = tarea
        } else if ModoDemostracion.activo && ModoDemostracion.pantalla == "nueva" {
            base = Tarea.ejemploNueva()
        } else {
            base = Tarea(titulo: "")
        }
        _borrador = State(initialValue: base)
        _conFecha = State(initialValue: base.fechaLimite != nil)
    }

    private var tituloLimpio: String { borrador.titulo.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var fecha: Binding<Date> {
        Binding(get: { borrador.fechaLimite ?? Calendar.current.startOfDay(for: .now) },
                set: { borrador.fechaLimite = $0 })
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Tarea") {
                    TextField("Título", text: $borrador.titulo)
                        .focused($enfocado)
                        .accessibilityIdentifier("titulo")
                    TextField("Notas (opcional)", text: $borrador.notas, axis: .vertical)
                        .lineLimit(2...5)
                }
                Section("Detalles") {
                    Picker("Prioridad", selection: $borrador.prioridad) {
                        ForEach(Array(Prioridad.allCases.reversed())) { Text($0.nombre).tag($0) }
                    }
                    Toggle("Fecha límite", isOn: $conFecha.animation())
                    if conFecha {
                        DatePicker("Fecha", selection: fecha, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                    }
                }
                if let original {
                    Section {
                        Button("Eliminar tarea", role: .destructive) {
                            almacen.eliminar(original)
                            cerrar()
                        }
                    }
                }
            }
            .navigationTitle(original == nil ? "Nueva tarea" : "Editar tarea")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { cerrar() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { guardar() }
                        .disabled(tituloLimpio.isEmpty)
                        .accessibilityIdentifier("guardar")
                }
            }
            .onAppear {
                if original == nil && tituloLimpio.isEmpty { enfocado = true }
            }
        }
    }

    private func guardar() {
        var tarea = borrador
        tarea.titulo = tituloLimpio
        tarea.fechaLimite = conFecha ? fecha.wrappedValue : nil
        if original == nil {
            almacen.agregar(tarea)
        } else {
            almacen.actualizar(tarea)
        }
        cerrar()
    }
}
