import SwiftUI

enum Filtro: String, CaseIterable, Identifiable {
    case pendientes = "Pendientes"
    case completadas = "Completadas"
    var id: String { rawValue }
}

struct ListaTareasView: View {
    @Environment(AlmacenTareas.self) private var almacen
    @State private var filtro: Filtro = ModoDemostracion.pantalla == "completadas" ? .completadas : .pendientes
    @State private var busqueda = ""
    @State private var editando: Tarea?
    @State private var creando = ModoDemostracion.pantalla == "nueva"
    @State private var mostrandoPrivacidad = ModoDemostracion.pantalla == "privacidad"

    private var visibles: [Tarea] {
        let base = filtro == .pendientes ? almacen.pendientes : almacen.completadas
        guard !busqueda.isEmpty else { return base }
        return base.filter {
            $0.titulo.localizedCaseInsensitiveContains(busqueda) || $0.notas.localizedCaseInsensitiveContains(busqueda)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ResumenView(pendientes: almacen.pendientes.count, completadas: almacen.completadas.count)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
                Section {
                    Picker("Filtro", selection: $filtro) {
                        ForEach(Filtro.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
                Section {
                    if visibles.isEmpty {
                        ContentUnavailableView(
                            filtro == .pendientes ? "Sin pendientes" : "Nada completado aún",
                            systemImage: filtro == .pendientes ? "checkmark.circle" : "tray",
                            description: Text(filtro == .pendientes ? "Toca + para agregar una tarea."
                                                                    : "Las tareas que marques aparecerán aquí."))
                    }
                    ForEach(visibles) { tarea in
                        FilaTareaView(tarea: tarea) { almacen.alternar(tarea) }
                            .contentShape(Rectangle())
                            .onTapGesture { editando = tarea }
                            .swipeActions {
                                Button("Eliminar", systemImage: "trash", role: .destructive) { almacen.eliminar(tarea) }
                            }
                    }
                }
            }
            .navigationTitle("Mis pendientes")
            .searchable(text: $busqueda, prompt: "Buscar tareas")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Privacidad", systemImage: "hand.raised") { mostrandoPrivacidad = true }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Nueva tarea", systemImage: "plus") { creando = true }
                        .accessibilityIdentifier("nueva")
                }
            }
            .sheet(isPresented: $creando) { EditorTareaView(tarea: nil) }
            .sheet(item: $editando) { EditorTareaView(tarea: $0) }
            .sheet(isPresented: $mostrandoPrivacidad) { PrivacidadView() }
            .onAppear {
                if ModoDemostracion.pantalla == "editar", editando == nil {
                    editando = almacen.pendientes.first
                }
            }
        }
    }
}

struct ResumenView: View {
    let pendientes: Int
    let completadas: Int

    private var total: Int { pendientes + completadas }
    private var avance: Double { total == 0 ? 0 : Double(completadas) / Double(total) }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().stroke(Color.accentColor.opacity(0.2), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: avance)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text(avance, format: .percent.precision(.fractionLength(0)))
                    .font(.footnote.bold())
            }
            .frame(width: 56, height: 56)
            VStack(alignment: .leading, spacing: 2) {
                Text(pendientes == 1 ? "1 tarea pendiente" : "\(pendientes) tareas pendientes")
                    .font(.headline)
                Text("\(completadas) de \(total) completadas")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }
}
