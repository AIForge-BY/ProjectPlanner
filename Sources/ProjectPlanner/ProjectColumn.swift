import SwiftUI
import UniformTypeIdentifiers

struct ProjectColumn: View {
    @EnvironmentObject private var appState: AppState
    let title: String
    let status: ProjectStatus
    let accent: Color
    var newExistingAction: ((PlannedProject) -> Void)?
    var newTemplateAction: ((PlannedProject) -> Void)?
    @State private var isManaging = false
    @State private var selectedProjectIDs = Set<UUID>()
    @State private var draggingProjectID: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            managementBar
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.105), Color.white.opacity(0.055)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 18)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(accent.opacity(0.18), lineWidth: 1)
        }
    }

    private var header: some View {
        HStack {
            Circle()
                .fill(accent)
                .frame(width: 8, height: 8)
            Text(title)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
            Spacer()
            Text("\(projects.count)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(accent)
            ColumnHeaderButton(
                icon: .collapse,
                help: "全部折叠",
                accent: accent
            ) {
                Task { await appState.setCollapsed(status: status, isCollapsed: true) }
            }
            ColumnHeaderButton(
                icon: .expand,
                help: "全部展开",
                accent: accent
            ) {
                Task { await appState.setCollapsed(status: status, isCollapsed: false) }
            }
            Button {
                isManaging.toggle()
                selectedProjectIDs.removeAll()
            } label: {
                Label(isManaging ? "完成" : "管理", systemImage: isManaging ? "checkmark" : "checklist")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .foregroundStyle(isManaging ? Color(red: 0.02, green: 0.06, blue: 0.08) : accent)
                    .background(
                        isManaging ? accent : Color.white.opacity(0.10),
                        in: RoundedRectangle(cornerRadius: 9)
                    )
            }
            .buttonStyle(.plain)
            .help(isManaging ? "结束批量管理" : "批量管理")
        }
    }

    @ViewBuilder
    private var managementBar: some View {
        if isManaging {
            HStack(spacing: 8) {
                Text("已选择 \(selectedProjectIDs.count) 个")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.58))
                Spacer()
                Button(role: .destructive) {
                    let ids = selectedProjectIDs
                    isManaging = false
                    selectedProjectIDs.removeAll()
                    Task {
                        for id in ids {
                            await appState.deleteProject(id: id)
                        }
                    }
                } label: {
                    Label("移入回收站", systemImage: "trash")
                }
                .disabled(selectedProjectIDs.isEmpty)
                .buttonStyle(PanelButtonStyle(accent: Color(red: 0.95, green: 0.47, blue: 0.52), isProminent: true))
                .controlSize(.small)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if projects.isEmpty {
            Text("暂无项目")
                .foregroundStyle(.white.opacity(0.48))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 12)
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(groupedProjects, id: \.name) { group in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(group.name)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white.opacity(0.50))
                                .padding(.horizontal, 2)
                            ForEach(group.projects) { project in
                                ProjectRow(
                                    project: project,
                                    isManaging: isManaging,
                                    isSelected: selectedProjectIDs.contains(project.id),
                                    toggleSelection: {
                                        toggleSelection(project.id)
                                    },
                                    newExistingAction: newExistingAction,
                                    newTemplateAction: newTemplateAction
                                )
                                .onDrag {
                                    draggingProjectID = project.id
                                    return NSItemProvider(object: project.id.uuidString as NSString)
                                }
                                .onDrop(
                                    of: [.text],
                                    delegate: ProjectDropDelegate(
                                        target: project,
                                        draggingProjectID: $draggingProjectID,
                                        appState: appState
                                    )
                                )
                            }
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var projects: [PlannedProject] {
        appState.projects(with: status)
    }

    private var groupedProjects: [(name: String, projects: [PlannedProject])] {
        let groups = Dictionary(grouping: projects) { project in
            project.groupName?.isEmpty == false ? project.groupName! : "未分组"
        }
        return groups
            .map { (name: $0.key, projects: $0.value) }
            .sorted { lhs, rhs in
                if lhs.name == "未分组" { return true }
                if rhs.name == "未分组" { return false }
                return lhs.name < rhs.name
            }
    }

    private func toggleSelection(_ id: UUID) {
        if selectedProjectIDs.contains(id) {
            selectedProjectIDs.remove(id)
        } else {
            selectedProjectIDs.insert(id)
        }
    }
}

private struct ColumnHeaderButton: View {
    let icon: ColumnHeaderIcon
    let help: String
    let accent: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            iconView
                .frame(width: 28, height: 28)
                .background(Color.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 9))
        }
        .buttonStyle(.plain)
        .help(help)
    }

    private var iconView: some View {
        VStack(spacing: 1) {
            Image(systemName: icon.topChevron)
                .font(.system(size: 8, weight: .heavy))
            Rectangle()
                .fill(accent)
                .frame(width: 13, height: 2)
                .clipShape(Capsule())
            Image(systemName: icon.bottomChevron)
                .font(.system(size: 8, weight: .heavy))
        }
        .foregroundStyle(accent)
    }
}

private enum ColumnHeaderIcon {
    case collapse
    case expand

    var topChevron: String {
        switch self {
        case .collapse:
            return "chevron.down"
        case .expand:
            return "chevron.up"
        }
    }

    var bottomChevron: String {
        switch self {
        case .collapse:
            return "chevron.up"
        case .expand:
            return "chevron.down"
        }
    }
}

private struct ProjectDropDelegate: DropDelegate {
    let target: PlannedProject
    @Binding var draggingProjectID: UUID?
    let appState: AppState

    func dropEntered(info: DropInfo) {
        moveDraggingProjectBeforeTarget()
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        if draggingProjectID != nil {
            moveDraggingProjectBeforeTarget()
            draggingProjectID = nil
            return true
        }

        guard let provider = info.itemProviders(for: [.text]).first else {
            return false
        }
        provider.loadItem(forTypeIdentifier: "public.text", options: nil) { item, _ in
            let value = (item as? Data).flatMap { String(data: $0, encoding: .utf8) } ?? item as? String
            guard let value, let id = UUID(uuidString: value), id != target.id else {
                return
            }
            Task { @MainActor in
                await appState.moveProject(id: id, before: target.id)
            }
        }
        return true
    }

    private func moveDraggingProjectBeforeTarget() {
        guard let id = draggingProjectID, id != target.id else {
            return
        }
        Task { @MainActor in
            await appState.moveProject(id: id, before: target.id)
        }
    }
}
