import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            Divider()
            activeProjects
            Divider()
            actions
            if let errorMessage = appState.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
        .padding(14)
        .frame(width: 440)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(AppBrand.name)
                .font(.headline)
            Text("\(appState.projects(with: .active).count) 个执行中项目")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var activeProjects: some View {
        let projects = appState.projects(with: .active)
        if projects.isEmpty {
            Text("暂无执行中项目")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(projects) { project in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(project.alias ?? project.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        if let alias = project.alias, alias != project.name {
                            Text(project.name)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        HStack(spacing: 6) {
                            actionButton("文件夹", systemImage: "folder") {
                                Task { await appState.openFolder(project: project) }
                            }
                            actionButton("IDE", systemImage: "hammer") {
                                Task { await appState.openIDE(project: project) }
                            }
                            actionButton("终端", systemImage: "terminal") {
                                Task { await appState.openTerminal(project: project) }
                            }
                        }
                    }
                    .padding(8)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }

    private var actions: some View {
        HStack {
            Button {
                openWindow(id: "manage-projects")
            } label: {
                Label("管理", systemImage: "rectangle.grid.3x2")
            }
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Label("退出", systemImage: "power")
            }
        }
        .buttonStyle(.bordered)
    }

    private func actionButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .labelStyle(.titleAndIcon)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }
}
