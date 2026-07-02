import SwiftUI

struct NewProjectView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    let todoProject: PlannedProject?
    @State private var name = "ClientApp"
    @State private var parentDirectory = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Desktop")
    @State private var type: ProjectType = .ios
    @State private var customType = ""
    @State private var remoteMode: RemoteMode = .none
    @State private var remotePlatform: RemotePlatform = .github
    @State private var repositoryName = ""
    @State private var remoteURL = ""

    init(todoProject: PlannedProject? = nil) {
        self.todoProject = todoProject
        _name = State(initialValue: todoProject?.alias ?? todoProject?.name ?? "ClientApp")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("新建默认工程")
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
                    Text(parentDirectory.path)
                        .lineLimit(1)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("选择地址") {
                        chooseDirectory()
                    }
                }
                Picker("远程仓库", selection: $remoteMode) {
                    Text("不绑定远程").tag(RemoteMode.none)
                    Text("创建新远程").tag(RemoteMode.createNew)
                    Text("绑定已有远程").tag(RemoteMode.bindExisting)
                }
                if remoteMode != .none {
                    Picker("平台", selection: $remotePlatform) {
                        Text("GitHub").tag(RemotePlatform.github)
                        Text("Gitee").tag(RemotePlatform.gitee)
                    }
                }
                if remoteMode == .createNew {
                    TextField("仓库名，例如 owner/repo", text: $repositoryName)
                }
                if remoteMode == .bindExisting {
                    TextField("已有仓库 URL", text: $remoteURL)
                }
            }
            HStack {
                Spacer()
                Button("取消") {
                    dismiss()
                }
                Button("创建") {
                    Task {
                        await appState.createDefaultProject(
                            name: name,
                            parentDirectory: parentDirectory,
                            type: type,
                            customType: resolvedCustomType,
                            remoteRequest: remoteRequest,
                            boundTodoID: todoProject?.id
                        )
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canSubmit)
            }
        }
        .padding(20)
        .frame(width: 560)
    }

    private var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && (type != .other || resolvedCustomType != nil)
    }

    private var resolvedCustomType: String? {
        guard type == .other else { return nil }
        let trimmed = customType.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private var remoteRequest: RemoteSetupRequest {
        switch remoteMode {
        case .none:
            return .none
        case .createNew:
            return .createNew(platform: remotePlatform, repositoryName: repositoryName)
        case .bindExisting:
            return .bindExisting(platform: remotePlatform, url: remoteURL)
        }
    }

    private func chooseDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            parentDirectory = url
        }
    }
}
