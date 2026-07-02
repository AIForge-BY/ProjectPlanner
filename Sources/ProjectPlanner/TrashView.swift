import SwiftUI

struct TrashView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    var closeAction: (() -> Void)?

    private var projects: [PlannedProject] {
        appState.projects(with: .trash)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            content
        }
        .padding(22)
        .frame(width: 560, height: 520)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.020, green: 0.030, blue: 0.050),
                    Color(red: 0.035, green: 0.070, blue: 0.095)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("回收站")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("\(projects.count) 个项目")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.55))
            }
            Spacer()
            Button {
                close()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 17, weight: .bold))
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.white.opacity(0.72))
            .help("关闭")
        }
    }

    @ViewBuilder
    private var content: some View {
        if projects.isEmpty {
            Text("暂无项目")
                .foregroundStyle(.white.opacity(0.48))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        } else {
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(projects) { project in
                        TrashProjectRow(project: project)
                    }
                }
                .padding(.vertical, 2)
            }
            Button(role: .destructive) {
                Task { await appState.emptyTrash() }
            } label: {
                Label("清空回收站", systemImage: "trash.slash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PanelButtonStyle(accent: Color(red: 0.95, green: 0.47, blue: 0.52), isProminent: true))
        }
    }

    private func close() {
        if let closeAction {
            closeAction()
        } else {
            dismiss()
        }
    }
}

private struct TrashProjectRow: View {
    @EnvironmentObject private var appState: AppState
    let project: PlannedProject

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.alias ?? project.name)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(project.path.isEmpty ? "未绑定项目目录" : project.path)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.52))
                        .lineLimit(1)
                }
                Spacer()
                if !(project.status == .todo && project.path.isEmpty) {
                    Text(project.typeLabel)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color(red: 0.46, green: 0.86, blue: 0.95))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.08), in: Capsule())
                }
            }

            HStack(spacing: 8) {
                Button {
                    Task { await appState.restoreProject(id: project.id) }
                } label: {
                    Label("还原", systemImage: "arrow.uturn.backward")
                }
                .buttonStyle(PanelButtonStyle(accent: Color(red: 0.36, green: 0.84, blue: 0.68)))

                Button(role: .destructive) {
                    Task { await appState.permanentlyDeleteProject(id: project.id) }
                } label: {
                    Label("永久删除", systemImage: "trash")
                }
                .buttonStyle(PanelButtonStyle(accent: Color(red: 0.95, green: 0.47, blue: 0.52)))
            }
            .controlSize(.small)
        }
        .padding(14)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.115), Color.white.opacity(0.055)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 14)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(red: 0.95, green: 0.47, blue: 0.52).opacity(0.18), lineWidth: 1)
        }
    }
}
