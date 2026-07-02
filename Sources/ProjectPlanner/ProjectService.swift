import Foundation

enum ProjectServiceError: LocalizedError, Equatable {
    case projectNotFound(UUID)

    var errorDescription: String? {
        switch self {
        case .projectNotFound(let id):
            return "找不到项目：\(id.uuidString)"
        }
    }
}

struct ProjectService {
    let now: () -> Date

    init(now: @escaping () -> Date = Date.init) {
        self.now = now
    }

    func addExistingProject(
        name: String,
        path: String,
        type: ProjectType,
        customType: String? = nil,
        to document: inout ProjectDocument
    ) -> PlannedProject {
        var project = PlannedProject.existingProject(name: name, path: path, type: type, now: now())
        project.customType = normalizedCustomType(customType)
        document.projects.append(project)
        return project
    }

    func addTodoAlias(_ alias: String, groupName: String? = nil, to document: inout ProjectDocument) -> PlannedProject {
        let trimmed = alias.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayName = trimmed.isEmpty ? "未命名待办" : trimmed
        var project = PlannedProject.existingProject(name: displayName, path: "", type: .other, now: now())
        project.alias = displayName
        project.groupName = ensureGroup(groupName, in: &document)
        document.projects.append(project)
        return project
    }

    func addTemplateProject(
        name: String,
        path: String,
        type: ProjectType,
        customType: String? = nil,
        templateID: String,
        templateVersion: Int,
        remote: RemoteInfo,
        to document: inout ProjectDocument
    ) -> PlannedProject {
        var project = PlannedProject.templateProject(
            name: name,
            path: path,
            type: type,
            templateID: templateID,
            templateVersion: templateVersion,
            now: now()
        )
        project.customType = normalizedCustomType(customType)
        project.remote = remote
        document.projects.append(project)
        return project
    }

    func startProject(id: UUID, in document: inout ProjectDocument) throws {
        try update(id: id, in: &document) { project in
            project.status = .active
            project.completedAt = nil
            project.isCollapsed = true
            project.updatedAt = now()
        }
    }

    func completeProject(id: UUID, in document: inout ProjectDocument) throws {
        try update(id: id, in: &document) { project in
            let timestamp = now()
            project.status = .completed
            project.completedAt = timestamp
            project.isCollapsed = true
            project.updatedAt = timestamp
        }
    }

    func reopenProject(id: UUID, in document: inout ProjectDocument) throws {
        try startProject(id: id, in: &document)
    }

    func updateProject(
        id: UUID,
        name: String,
        path: String,
        type: ProjectType,
        customType: String? = nil,
        ideOverride: IDEOverride?,
        in document: inout ProjectDocument
    ) throws {
        try update(id: id, in: &document) { project in
            project.name = name
            project.path = path
            project.type = type
            project.customType = normalizedCustomType(customType)
            project.ideOverride = ideOverride
            project.updatedAt = now()
        }
    }

    func bindExistingProject(
        id: UUID,
        name: String,
        path: String,
        type: ProjectType,
        customType: String? = nil,
        in document: inout ProjectDocument
    ) throws {
        try update(id: id, in: &document) { project in
            project.name = name
            project.path = path
            project.type = type
            project.customType = normalizedCustomType(customType)
            project.status = .active
            project.completedAt = nil
            project.isCollapsed = true
            project.updatedAt = now()
        }
    }

    func bindTemplateProject(
        id: UUID,
        name: String,
        path: String,
        type: ProjectType,
        customType: String? = nil,
        templateID: String,
        templateVersion: Int,
        remote: RemoteInfo,
        in document: inout ProjectDocument
    ) throws {
        try update(id: id, in: &document) { project in
            project.name = name
            project.path = path
            project.type = type
            project.customType = normalizedCustomType(customType)
            project.status = .active
            project.completedAt = nil
            project.isCollapsed = true
            project.remote = remote
            project.template = TemplateInfo(id: templateID, version: templateVersion)
            project.updatedAt = now()
        }
    }

    func updateRemote(id: UUID, remote: RemoteInfo, in document: inout ProjectDocument) throws {
        try update(id: id, in: &document) { project in
            project.remote = remote
            project.updatedAt = now()
        }
    }

    func updateAlias(id: UUID, alias: String, in document: inout ProjectDocument) throws {
        let trimmed = alias.trimmingCharacters(in: .whitespacesAndNewlines)
        try update(id: id, in: &document) { project in
            project.alias = trimmed.isEmpty ? nil : trimmed
            project.updatedAt = now()
        }
    }

    func updateGroup(id: UUID, groupName: String, in document: inout ProjectDocument) throws {
        let trimmed = ensureGroup(groupName, in: &document)
        try update(id: id, in: &document) { project in
            project.groupName = trimmed
            project.updatedAt = now()
        }
    }

    func createGroup(_ groupName: String, in document: inout ProjectDocument) {
        _ = ensureGroup(groupName, in: &document)
    }

    func renameGroup(from oldName: String, to newName: String, in document: inout ProjectDocument) {
        let source = normalizedGroupName(oldName)
        let destination = normalizedGroupName(newName)
        guard let source else { return }
        let timestamp = now()
        if let destination {
            var groups = document.groups ?? []
            groups.removeAll { $0.name == source || $0.name == destination }
            groups.append(ProjectGroup(name: destination, createdAt: timestamp))
            document.groups = groups.sorted { $0.name < $1.name }
        } else {
            document.groups?.removeAll { $0.name == source }
        }
        for index in document.projects.indices where document.projects[index].groupName == source {
            document.projects[index].groupName = destination
            document.projects[index].updatedAt = timestamp
        }
    }

    func deleteGroup(_ groupName: String, in document: inout ProjectDocument) {
        renameGroup(from: groupName, to: "", in: &document)
    }

    func moveProjects(ids: Set<UUID>, toGroup groupName: String, in document: inout ProjectDocument) {
        let group = ensureGroup(groupName, in: &document)
        let timestamp = now()
        for index in document.projects.indices where ids.contains(document.projects[index].id) {
            document.projects[index].groupName = group
            document.projects[index].updatedAt = timestamp
        }
    }

    func setCollapsed(id: UUID, isCollapsed: Bool, in document: inout ProjectDocument) throws {
        try update(id: id, in: &document) { project in
            project.isCollapsed = isCollapsed
            project.updatedAt = now()
        }
    }

    func setCollapsed(status: ProjectStatus, isCollapsed: Bool, in document: inout ProjectDocument) {
        let timestamp = now()
        for index in document.projects.indices where document.projects[index].status == status {
            document.projects[index].isCollapsed = isCollapsed
            document.projects[index].updatedAt = timestamp
        }
    }

    func moveProject(id: UUID, before targetID: UUID, in document: inout ProjectDocument) throws {
        guard id != targetID else { return }
        guard let movingIndex = document.projects.firstIndex(where: { $0.id == id }) else {
            throw ProjectServiceError.projectNotFound(id)
        }
        guard let target = document.projects.first(where: { $0.id == targetID }) else {
            throw ProjectServiceError.projectNotFound(targetID)
        }
        let status = target.status
        var ordered = document.projects
            .filter { $0.status == status }
            .sorted { sortValue($0) < sortValue($1) }
            .map(\.id)
        ordered.removeAll { $0 == id }
        guard let targetIndex = ordered.firstIndex(of: targetID) else { return }
        ordered.insert(id, at: targetIndex)
        for (index, projectID) in ordered.enumerated() {
            if let documentIndex = document.projects.firstIndex(where: { $0.id == projectID }) {
                document.projects[documentIndex].sortOrder = Double(index)
                document.projects[documentIndex].updatedAt = now()
            }
        }
        document.projects[movingIndex].status = status
        document.projects[movingIndex].groupName = target.groupName
    }

    func moveToTrash(id: UUID, in document: inout ProjectDocument) throws {
        try update(id: id, in: &document) { project in
            if project.status != .trash {
                project.statusBeforeTrash = project.status
            }
            project.status = .trash
            project.updatedAt = now()
        }
    }

    func restoreFromTrash(id: UUID, in document: inout ProjectDocument) throws {
        try update(id: id, in: &document) { project in
            project.status = project.statusBeforeTrash ?? .todo
            project.statusBeforeTrash = nil
            project.updatedAt = now()
        }
    }

    func emptyTrash(in document: inout ProjectDocument) {
        document.projects.removeAll { $0.status == .trash }
    }

    func permanentlyDeleteProject(id: UUID, from document: inout ProjectDocument) throws {
        guard let index = document.projects.firstIndex(where: { $0.id == id }) else {
            throw ProjectServiceError.projectNotFound(id)
        }
        document.projects.remove(at: index)
    }

    func deleteProject(id: UUID, from document: inout ProjectDocument) throws {
        try permanentlyDeleteProject(id: id, from: &document)
    }

    private func update(
        id: UUID,
        in document: inout ProjectDocument,
        mutate: (inout PlannedProject) -> Void
    ) throws {
        guard let index = document.projects.firstIndex(where: { $0.id == id }) else {
            throw ProjectServiceError.projectNotFound(id)
        }
        mutate(&document.projects[index])
    }

    private func normalizedCustomType(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }

    private func normalizedGroupName(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }

    private func ensureGroup(_ value: String?, in document: inout ProjectDocument) -> String? {
        guard let name = normalizedGroupName(value) else { return nil }
        var groups = document.groups ?? []
        if !groups.contains(where: { $0.name == name }) {
            groups.append(ProjectGroup(name: name, createdAt: now()))
            document.groups = groups.sorted { $0.name < $1.name }
        } else {
            document.groups = groups
        }
        return name
    }

    private func sortValue(_ project: PlannedProject) -> Double {
        project.sortOrder ?? project.createdAt.timeIntervalSince1970
    }
}
