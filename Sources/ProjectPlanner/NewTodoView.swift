import SwiftUI

struct NewTodoView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var alias = ""
    @State private var groupMode: GroupMode = .none
    @State private var selectedGroup = ""
    @State private var newGroup = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("新建待办")
                .font(.title2)
                .fontWeight(.semibold)
            TextField("输入别名", text: $alias)
                .textFieldStyle(.roundedBorder)
            Picker("分组", selection: $groupMode) {
                Text("不加入分组").tag(GroupMode.none)
                if !appState.groupNames().isEmpty {
                    Text("选择已有分组").tag(GroupMode.existing)
                }
                Text("新建分组").tag(GroupMode.new)
            }
            if groupMode == .existing {
                Picker("已有分组", selection: $selectedGroup) {
                    ForEach(appState.groupNames(), id: \.self) { group in
                        Text(group).tag(group)
                    }
                }
                .onAppear {
                    if selectedGroup.isEmpty {
                        selectedGroup = appState.groupNames().first ?? ""
                    }
                }
            }
            if groupMode == .new {
                TextField("新分组名称", text: $newGroup)
                    .textFieldStyle(.roundedBorder)
            }
            HStack {
                Spacer()
                Button("取消") {
                    dismiss()
                }
                Button("创建") {
                    Task {
                        await appState.addTodo(alias: alias, groupName: resolvedGroupName)
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canSubmit)
            }
        }
        .padding(24)
        .frame(width: 460)
    }

    private var canSubmit: Bool {
        !alias.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && (groupMode != .existing || !selectedGroup.isEmpty)
            && (groupMode != .new || !newGroup.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    private var resolvedGroupName: String? {
        switch groupMode {
        case .none:
            return nil
        case .existing:
            return selectedGroup
        case .new:
            return newGroup
        }
    }
}

private enum GroupMode {
    case none
    case existing
    case new
}
