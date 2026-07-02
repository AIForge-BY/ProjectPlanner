import SwiftUI

struct ProjectRow: View {
    @EnvironmentObject private var appState: AppState
    let project: PlannedProject
    let isManaging: Bool
    let isSelected: Bool
    let toggleSelection: () -> Void
    var newExistingAction: ((PlannedProject) -> Void)?
    var newTemplateAction: ((PlannedProject) -> Void)?
    @State private var isEditingAlias = false
    @State private var aliasDraft = ""
    @State private var groupDraft = ""
    @State private var isShowingProjectActions = false
    @State private var isShowingLaunchOptions = false
    @State private var isEditingGroup = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header

            if !isCollapsed {
                if let completedAt = project.completedAt {
                    Text("完成时间：\(completedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.52))
                }

                if !isManaging {
                    actions
                }
            }
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
                .stroke(Color(red: 0.55, green: 0.78, blue: 0.88).opacity(0.16), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.22), radius: 16, y: 8)
        .contentShape(Rectangle())
        .onTapGesture {
            if isManaging {
                toggleSelection()
            } else {
                toggleCollapsed()
            }
        }
        .onLongPressGesture {
            if isManaging {
                toggleSelection()
            } else {
                isShowingProjectActions = true
            }
        }
        .contextMenu {
            Button("修改别名") {
                beginAliasEdit()
            }
            Button("设置分组") {
                beginGroupEdit()
            }
            Button(isCollapsed ? "展开项目" : "折叠项目") {
                toggleCollapsed()
            }
            Button("移入回收站", role: .destructive) {
                Task { await appState.deleteProject(id: project.id) }
            }
        }
        .confirmationDialog(project.alias ?? project.name, isPresented: $isShowingProjectActions) {
            Button("修改别名") {
                beginAliasEdit()
            }
            Button("设置分组") {
                beginGroupEdit()
            }
            Button(isCollapsed ? "展开项目" : "折叠项目") {
                toggleCollapsed()
            }
            Button("移入回收站", role: .destructive) {
                Task { await appState.deleteProject(id: project.id) }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("选择要对这个项目执行的操作。")
        }
        .confirmationDialog("启动待办项目", isPresented: $isShowingLaunchOptions) {
            Button("添加已有项目") {
                newExistingAction?(project)
            }
            Button("新建默认工程") {
                newTemplateAction?(project)
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text(project.alias ?? project.name)
        }
        .alert("修改项目别名", isPresented: $isEditingAlias) {
            TextField("别名", text: $aliasDraft)
            Button("保存") {
                Task { await appState.updateAlias(projectID: project.id, alias: aliasDraft) }
            }
            Button("清除别名", role: .destructive) {
                Task { await appState.updateAlias(projectID: project.id, alias: "") }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("也可以在项目菜单中再次修改。")
        }
        .alert("设置项目分组", isPresented: $isEditingGroup) {
            TextField("分组名称", text: $groupDraft)
            Button("保存") {
                Task { await appState.updateGroup(projectID: project.id, groupName: groupDraft) }
            }
            Button("移出分组", role: .destructive) {
                Task { await appState.updateGroup(projectID: project.id, groupName: "") }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("留空或移出分组会回到未分组。")
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            if isManaging {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isSelected ? Color(red: 0.36, green: 0.84, blue: 0.68) : .white.opacity(0.42))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(project.alias ?? project.name)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                if !isCollapsed, let alias = project.alias, alias != project.name {
                    Text(project.name)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.46))
                        .lineLimit(1)
                }
                if !isCollapsed {
                    Text(project.path)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.52))
                        .lineLimit(1)
                }
            }
            Spacer()
            if !isCollapsed, shouldShowType {
                Text(project.typeLabel)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(red: 0.46, green: 0.86, blue: 0.95))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.08), in: Capsule())
            }
            Button {
                toggleCollapsed()
            } label: {
                Image(systemName: isCollapsed ? "chevron.down" : "chevron.up")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.58))
            }
            .buttonStyle(.plain)
            .help(isCollapsed ? "展开项目" : "折叠项目")
        }
    }

    private var actions: some View {
        LazyVGrid(columns: buttonColumns, alignment: .leading, spacing: 6) {
            switch project.status {
            case .todo:
                if project.path.isEmpty {
                    launchButton {
                        isShowingLaunchOptions = true
                    }
                } else {
                    launchButton {
                        Task { await appState.startProject(id: project.id) }
                    }
                }
            case .active:
                smallButton("文件夹", systemImage: "folder") {
                    Task { await appState.openFolder(project: project) }
                }
                smallButton("IDE", systemImage: "hammer") {
                    Task { await appState.openIDE(project: project) }
                }
                smallButton("终端", systemImage: "terminal") {
                    Task { await appState.openTerminal(project: project) }
                }
                smallButton("完成", systemImage: "checkmark.circle") {
                    Task { await appState.completeProject(id: project.id) }
                }
            case .completed:
                smallButton("重新开启", systemImage: "arrow.uturn.left") {
                    Task { await appState.reopenProject(id: project.id) }
                }
            case .trash:
                EmptyView()
            }
        }
    }

    private func beginAliasEdit() {
        aliasDraft = project.alias ?? project.name
        isEditingAlias = true
    }

    private func beginGroupEdit() {
        groupDraft = project.groupName ?? ""
        isEditingGroup = true
    }

    private func toggleCollapsed() {
        Task { await appState.setCollapsed(projectID: project.id, isCollapsed: !isCollapsed) }
    }

    private var isCollapsed: Bool {
        project.isCollapsed ?? (project.status != .todo)
    }

    private var shouldShowType: Bool {
        !(project.status == .todo && project.path.isEmpty)
    }

    private var buttonColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 76), spacing: 6)]
    }

    private func smallButton(
        _ title: String,
        systemImage: String,
        role: ButtonRole? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(role: role, action: action) {
            Label(title, systemImage: systemImage)
                .font(.caption)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(Color(red: 0.70, green: 0.82, blue: 0.90))
        .controlSize(.small)
    }

    private func launchButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "play.fill")
                    .font(.system(size: 13, weight: .bold))
                Text("启动")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
            }
            .foregroundStyle(Color(red: 0.02, green: 0.07, blue: 0.08))
            .frame(width: 94, height: 38)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.48, green: 0.86, blue: 0.70),
                        Color(red: 0.34, green: 0.74, blue: 0.66)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: Capsule()
            )
            .overlay {
                Capsule()
                    .stroke(Color.white.opacity(0.20), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}
