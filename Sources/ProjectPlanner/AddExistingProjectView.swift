import SwiftUI

struct AddExistingProjectView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    let todoProject: PlannedProject?
    @State private var name = ""
    @State private var path = ""
    @State private var type: ProjectType = .other
    @State private var customType = ""

    init(todoProject: PlannedProject? = nil) {
        self.todoProject = todoProject
        _name = State(initialValue: todoProject?.alias ?? todoProject?.name ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("添加已有项目")
                .font(.title2)
                .fontWeight(.semibold)
            Form {
                TextField("项目名称", text: $name)
                Picker("项目类型", selection: $type) {
                    ForEach(ProjectType.allCases) { item in
                        Text(item.displayName).tag(item)
                    }
                }
                if type == .other {
                    TextField("自定义项目类型", text: $customType)
                }
                HStack {
                    Text(path.isEmpty ? "未选择项目目录" : path)
                        .lineLimit(1)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("选择项目") {
                        chooseDirectory()
                    }
                }
            }
            HStack {
                Spacer()
                Button("取消") {
                    dismiss()
                }
                Button("添加") {
                    Task {
                        if let todoProject {
                            await appState.bindExistingProject(
                                todoID: todoProject.id,
                                name: resolvedName,
                                path: path,
                                type: type,
                                customType: resolvedCustomType
                            )
                        } else {
                            await appState.addExistingProject(
                                name: resolvedName,
                                path: path,
                                type: type,
                                customType: resolvedCustomType
                            )
                        }
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canSubmit)
            }
        }
        .padding(20)
        .frame(width: 520)
    }

    private var resolvedName: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            return trimmed
        }
        return URL(fileURLWithPath: path).lastPathComponent
    }

    private var resolvedCustomType: String? {
        guard type == .other else { return nil }
        let trimmed = customType.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private var canSubmit: Bool {
        !path.isEmpty && (type != .other || resolvedCustomType != nil)
    }

    private func chooseDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            path = url.path
            if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                name = url.lastPathComponent
            }
        }
    }
}
