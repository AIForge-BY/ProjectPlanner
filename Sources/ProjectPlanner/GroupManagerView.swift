import SwiftUI

struct GroupManagerView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    var closeAction: (() -> Void)?
    @State private var selectedGroup: String?
    @State private var renameDraft = ""
    @State private var createDraft = ""
    @State private var isRenaming = false
    @State private var isBulkMoving = false
    @State private var selectedProjectIDs = Set<UUID>()

    private var groups: [String] {
        appState.groupNames()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            content
        }
        .padding(22)
        .frame(width: 460, height: 420)
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
        .alert("重命名分组", isPresented: $isRenaming) {
            TextField("分组名称", text: $renameDraft)
            Button("保存") {
                if let selectedGroup {
                    Task { await appState.renameGroup(from: selectedGroup, to: renameDraft) }
                }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text(selectedGroup ?? "")
        }
        .sheet(isPresented: $isBulkMoving) {
            bulkMoveView
                .environmentObject(appState)
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("分组管理")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("\(groups.count) 个分组")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.55))
            }
            Spacer()
            TextField("新分组", text: $createDraft)
                .textFieldStyle(.roundedBorder)
                .frame(width: 110)
            Button {
                Task {
                    await appState.createGroup(createDraft)
                    createDraft = ""
                }
            } label: {
                Label("新建", systemImage: "plus")
            }
            .buttonStyle(PanelButtonStyle(accent: Color(red: 0.46, green: 0.86, blue: 0.95), isProminent: true))
            .disabled(createDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
        if groups.isEmpty {
            Text("暂无分组")
                .foregroundStyle(.white.opacity(0.48))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        } else {
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(groups, id: \.self) { group in
                        groupRow(group)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func groupRow(_ group: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "folder")
                .foregroundStyle(Color(red: 0.46, green: 0.86, blue: 0.95))
            Text(group)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
            Spacer()
            Button {
                selectedGroup = group
                selectedProjectIDs.removeAll()
                isBulkMoving = true
            } label: {
                Label("移入", systemImage: "arrow.right")
            }
            .buttonStyle(PanelButtonStyle(accent: Color(red: 0.36, green: 0.84, blue: 0.68)))
            Button {
                selectedGroup = group
                renameDraft = group
                isRenaming = true
            } label: {
                Label("重命名", systemImage: "pencil")
            }
            .buttonStyle(PanelButtonStyle(accent: Color(red: 0.46, green: 0.86, blue: 0.95)))
            Button(role: .destructive) {
                Task { await appState.deleteGroup(group) }
            } label: {
                Label("删除", systemImage: "trash")
            }
            .buttonStyle(PanelButtonStyle(accent: Color(red: 0.95, green: 0.47, blue: 0.52)))
        }
        .padding(12)
        .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        }
    }

    private var movableProjects: [PlannedProject] {
        appState.document.projects
            .filter { $0.status != .trash }
            .sorted { ($0.alias ?? $0.name) < ($1.alias ?? $1.name) }
    }

    private var bulkMoveView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("批量移入 \(selectedGroup ?? "")")
                .font(.system(size: 22, weight: .bold, design: .rounded))
            if movableProjects.isEmpty {
                Text("暂无可移动项目")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(movableProjects) { project in
                            Button {
                                toggleProject(project.id)
                            } label: {
                                HStack {
                                    Image(systemName: selectedProjectIDs.contains(project.id) ? "checkmark.circle.fill" : "circle")
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(project.alias ?? project.name)
                                            .fontWeight(.semibold)
                                        Text(project.groupName ?? "未分组")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            HStack {
                Spacer()
                Button("取消") {
                    isBulkMoving = false
                }
                Button("移动") {
                    if let selectedGroup {
                        Task {
                            await appState.moveProjects(ids: selectedProjectIDs, toGroup: selectedGroup)
                            selectedProjectIDs.removeAll()
                            isBulkMoving = false
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedProjectIDs.isEmpty)
            }
        }
        .padding(22)
        .frame(width: 440, height: 480)
    }

    private func toggleProject(_ id: UUID) {
        if selectedProjectIDs.contains(id) {
            selectedProjectIDs.remove(id)
        } else {
            selectedProjectIDs.insert(id)
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
