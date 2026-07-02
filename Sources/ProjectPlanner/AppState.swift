import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published private(set) var document: ProjectDocument
    @Published var errorMessage: String?

    private let store: ProjectStoring
    private let projectService: ProjectService
    private let templateService: TemplateGenerating
    private let gitService: GitManaging
    private let commandRunner: CommandRunning

    init(
        store: ProjectStoring = ProjectStore(),
        projectService: ProjectService = ProjectService(),
        templateService: TemplateGenerating = TemplateService(),
        gitService: GitManaging = GitService(),
        commandRunner: CommandRunning = ProcessCommandRunner()
    ) {
        self.store = store
        self.projectService = projectService
        self.templateService = templateService
        self.gitService = gitService
        self.commandRunner = commandRunner
        self.document = ProjectDocument()
    }

    func load() async {
        do {
            document = try store.load()
            errorMessage = nil
        } catch {
            errorMessage = localizedMessage(error)
        }
    }

    func addExistingProject(name: String, path: String, type: ProjectType, customType: String? = nil) async {
        do {
            _ = projectService.addExistingProject(name: name, path: path, type: type, customType: customType, to: &document)
            try store.save(document)
            errorMessage = nil
        } catch {
            errorMessage = localizedMessage(error)
        }
    }

    func addTodo(alias: String, groupName: String? = nil) async {
        do {
            _ = projectService.addTodoAlias(alias, groupName: groupName, to: &document)
            try store.save(document)
            errorMessage = nil
        } catch {
            errorMessage = localizedMessage(error)
        }
    }

    func bindExistingProject(todoID: UUID, name: String, path: String, type: ProjectType, customType: String? = nil) async {
        await mutateAndSave {
            try projectService.bindExistingProject(id: todoID, name: name, path: path, type: type, customType: customType, in: &document)
        }
    }

    func createDefaultProject(
        name: String,
        parentDirectory: URL,
        type: ProjectType,
        customType: String? = nil,
        remoteRequest: RemoteSetupRequest,
        boundTodoID: UUID? = nil
    ) async {
        let projectDirectory = parentDirectory.appendingPathComponent(name, isDirectory: true)
        do {
            let template = try templateService.generateTemplate(type: type, name: name, at: projectDirectory)
            try await gitService.initializeLocalRepository(at: projectDirectory.path)

            let remote: RemoteInfo
            do {
                remote = try await gitService.configureRemote(at: projectDirectory.path, request: remoteRequest)
                errorMessage = nil
            } catch {
                let message = localizedMessage(error)
                remote = failedRemoteInfo(from: remoteRequest, message: message)
                errorMessage = message
            }

            if let boundTodoID {
                try projectService.bindTemplateProject(
                    id: boundTodoID,
                    name: name,
                    path: projectDirectory.path,
                    type: type,
                    customType: customType,
                    templateID: template.id,
                    templateVersion: template.version,
                    remote: remote,
                    in: &document
                )
            } else {
                _ = projectService.addTemplateProject(
                    name: name,
                    path: projectDirectory.path,
                    type: type,
                    customType: customType,
                    templateID: template.id,
                    templateVersion: template.version,
                    remote: remote,
                    to: &document
                )
            }
            try store.save(document)
        } catch {
            errorMessage = localizedMessage(error)
        }
    }

    func startProject(id: UUID) async {
        await mutateAndSave {
            try projectService.startProject(id: id, in: &document)
        }
    }

    func completeProject(id: UUID) async {
        await mutateAndSave {
            try projectService.completeProject(id: id, in: &document)
        }
    }

    func reopenProject(id: UUID) async {
        await mutateAndSave {
            try projectService.reopenProject(id: id, in: &document)
        }
    }

    func deleteProject(id: UUID) async {
        await mutateAndSave {
            try projectService.moveToTrash(id: id, in: &document)
        }
    }

    func restoreProject(id: UUID) async {
        await mutateAndSave {
            try projectService.restoreFromTrash(id: id, in: &document)
        }
    }

    func permanentlyDeleteProject(id: UUID) async {
        await mutateAndSave {
            try projectService.permanentlyDeleteProject(id: id, from: &document)
        }
    }

    func emptyTrash() async {
        await mutateAndSave {
            projectService.emptyTrash(in: &document)
        }
    }

    func updateAlias(projectID: UUID, alias: String) async {
        await mutateAndSave {
            try projectService.updateAlias(id: projectID, alias: alias, in: &document)
        }
    }

    func updateGroup(projectID: UUID, groupName: String) async {
        await mutateAndSave {
            try projectService.updateGroup(id: projectID, groupName: groupName, in: &document)
        }
    }

    func renameGroup(from oldName: String, to newName: String) async {
        await mutateAndSave {
            projectService.renameGroup(from: oldName, to: newName, in: &document)
        }
    }

    func createGroup(_ groupName: String) async {
        await mutateAndSave {
            projectService.createGroup(groupName, in: &document)
        }
    }

    func deleteGroup(_ groupName: String) async {
        await mutateAndSave {
            projectService.deleteGroup(groupName, in: &document)
        }
    }

    func moveProjects(ids: Set<UUID>, toGroup groupName: String) async {
        await mutateAndSave {
            projectService.moveProjects(ids: ids, toGroup: groupName, in: &document)
        }
    }

    func setCollapsed(projectID: UUID, isCollapsed: Bool) async {
        await mutateAndSave {
            try projectService.setCollapsed(id: projectID, isCollapsed: isCollapsed, in: &document)
        }
    }

    func setCollapsed(status: ProjectStatus, isCollapsed: Bool) async {
        await mutateAndSave {
            projectService.setCollapsed(status: status, isCollapsed: isCollapsed, in: &document)
        }
    }

    func openFolder(project: PlannedProject) async {
        await run(FinderOpener().command(forDirectory: project.path))
    }

    func openIDE(project: PlannedProject) async {
        await run(IDEOpener().command(for: project))
    }

    func openTerminal(project: PlannedProject) async {
        for invocation in TerminalOpener().commands(forDirectory: project.path) {
            await run(invocation)
            if errorMessage != nil {
                return
            }
        }
    }

    func projects(with status: ProjectStatus) -> [PlannedProject] {
        ProjectSorter
            .groupedProjects(document.projects, status: status, sortField: .time, direction: .ascending)
            .flatMap(\.projects)
    }

    func groupNames() -> [String] {
        let existingGroups = document.groups?.map(\.name) ?? []
        let projectGroups = document.projects.compactMap { project in
            let trimmed = project.groupName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return trimmed.isEmpty ? nil : trimmed
        }
        return Array(Set(existingGroups + projectGroups))
        .sorted()
    }

    private func mutateAndSave(_ mutation: () throws -> Void) async {
        do {
            try mutation()
            try store.save(document)
            errorMessage = nil
        } catch {
            errorMessage = localizedMessage(error)
        }
    }

    private func failedRemoteInfo(from request: RemoteSetupRequest, message: String) -> RemoteInfo {
        switch request {
        case .none:
            return .none
        case .bindExisting(let platform, let url):
            return RemoteInfo(platform: platform, url: url, mode: .bindExisting, setupState: .failed, lastError: message)
        case .createNew(let platform, _):
            return RemoteInfo(platform: platform, url: nil, mode: .createNew, setupState: .failed, lastError: message)
        }
    }

    private func localizedMessage(_ error: Error) -> String {
        if let localized = error as? LocalizedError, let description = localized.errorDescription {
            return description
        }
        return error.localizedDescription
    }

    private func run(_ invocation: CommandInvocation) async {
        do {
            let result = try await commandRunner.run(invocation)
            guard result.exitCode == 0 else {
                errorMessage = commandErrorMessage(result)
                return
            }
            errorMessage = nil
        } catch {
            errorMessage = localizedMessage(error)
        }
    }

    private func commandErrorMessage(_ result: CommandResult) -> String {
        let stderr = String(data: result.standardError, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let stdout = String(data: result.standardOutput, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return stderr?.isEmpty == false ? stderr! : (stdout?.isEmpty == false ? stdout! : "命令执行失败")
    }
}
