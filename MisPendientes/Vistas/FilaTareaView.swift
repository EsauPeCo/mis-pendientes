import SwiftUI

struct FilaTareaView: View {
    let tarea: Tarea
    let alternar: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: alternar) {
                Image(systemName: tarea.completada ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(tarea.completada ? Color.accentColor : Color.secondary)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(tarea.completada ? "Marcar como pendiente" : "Marcar como completada")

            VStack(alignment: .leading, spacing: 4) {
                Text(tarea.titulo)
                    .strikethrough(tarea.completada)
                    .foregroundStyle(tarea.completada ? Color.secondary : Color.primary)
                if !tarea.notas.isEmpty {
                    Text(tarea.notas)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                HStack(spacing: 8) {
                    if let fecha = tarea.fechaLimite {
                        Label(Tarea.textoFecha(fecha), systemImage: "calendar")
                            .foregroundStyle(tarea.vencida() ? Color.red : Color.secondary)
                    }
                    EtiquetaPrioridad(prioridad: tarea.prioridad)
                }
                .font(.caption)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }
}

struct EtiquetaPrioridad: View {
    let prioridad: Prioridad

    private var color: Color {
        switch prioridad {
        case .alta: return .red
        case .media: return .orange
        case .baja: return .blue
        }
    }

    var body: some View {
        Text(prioridad.nombre)
            .padding(.horizontal, 6)
            .padding(.vertical, 1)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
            .accessibilityLabel("Prioridad \(prioridad.nombre.lowercased())")
    }
}
