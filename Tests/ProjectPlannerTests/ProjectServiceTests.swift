import XCTest
@testable import ProjectPlanner

final class ProjectServiceTests: XCTestCase {
    func testAddExistingProjectAppendsTodoProject() {
        var document = ProjectDocument()
        let service = ProjectService(now: { Date(timeIntervalSince1970: 400) })

        let project = service.addExistingProject(
            name: "Legacy",
            path: "/tmp/Legacy",
            type: .android,
            to: &document
        )

        XCTAssertEqual(document.projects, [project])
        XCTAssertEqual(project.status, .todo)
        XCTAssertEqual(project.type, .android)
    }

    func testAddExistingProjectStoresCustomTypeForOtherProjects() {
        var document = ProjectDocument()
        let service = ProjectService(now: { Date(timeIntervalSince1970: 405) })

        let project = service.addExistingProject(
            name: "Backend Tool",
            path: "/tmp/BackendTool",
            type: .other,
            customType: "Rust CLI",
            to: &document
        )

        XCTAssertEqual(project.type, .other)
        XCTAssertEqual(project.customType, "Rust CLI")
        XCTAssertEqual(project.typeLabel, "Rust CLI")
    }

    func testAddTodoAliasCreatesUnboundTodoProject() {
        var document = ProjectDocument()
        let service = ProjectService(now: { Date(timeIntervalSince1970: 410) })

        let project = service.addTodoAlias("  客户登录改版  ", groupName: "  移动端  ", to: &document)

        XCTAssertEqual(project.name, "客户登录改版")
        XCTAssertEqual(project.alias, "客户登录改版")
        XCTAssertEqual(project.path, "")
        XCTAssertEqual(project.type, .other)
        XCTAssertEqual(project.status, .todo)
        XCTAssertEqual(project.isCollapsed, false)
        XCTAssertEqual(project.groupName, "移动端")
        XCTAssertEqual(document.groups?.map(\.name), ["移动端"])
        XCTAssertEqual(document.projects, [project])
    }

    func testAddTemplateProjectAppendsActiveProject() {
        var document = ProjectDocument()
        let service = ProjectService(now: { Date(timeIntervalSince1970: 500) })

        let project = service.addTemplateProject(
            name: "New iOS",
            path: "/tmp/NewiOS",
            type: .ios,
            templateID: "ios-swiftui",
            templateVersion: 1,
            remote: RemoteInfo(platform: .github, url: nil, mode: .createNew, setupState: .pending, lastError: nil),
            to: &document
        )

        XCTAssertEqual(document.projects, [project])
        XCTAssertEqual(project.status, .active)
        XCTAssertEqual(project.remote.platform, .github)
        XCTAssertEqual(project.remote.mode, .createNew)
    }

    func testCompleteProjectRecordsCompletionTime() throws {
        var document = ProjectDocument(projects: [
            PlannedProject.existingProject(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000010")!,
                name: "Project",
                path: "/tmp/Project",
                type: .other,
                now: Date(timeIntervalSince1970: 10)
            )
        ])
        let service = ProjectService(now: { Date(timeIntervalSince1970: 600) })

        try service.startProject(id: document.projects[0].id, in: &document)
        try service.completeProject(id: document.projects[0].id, in: &document)

        XCTAssertEqual(document.projects[0].status, .completed)
        XCTAssertEqual(document.projects[0].startedAt, Date(timeIntervalSince1970: 600))
        XCTAssertEqual(document.projects[0].completedAt, Date(timeIntervalSince1970: 600))
        XCTAssertEqual(document.projects[0].updatedAt, Date(timeIntervalSince1970: 600))
    }

    func testReopenProjectClearsCompletionTime() throws {
        var project = PlannedProject.existingProject(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000011")!,
            name: "Project",
            path: "/tmp/Project",
            type: .other,
            now: Date(timeIntervalSince1970: 10)
        )
        project.status = .completed
        project.startedAt = Date(timeIntervalSince1970: 15)
        project.completedAt = Date(timeIntervalSince1970: 20)
        var document = ProjectDocument(projects: [project])
        let service = ProjectService(now: { Date(timeIntervalSince1970: 700) })

        try service.reopenProject(id: project.id, in: &document)

        XCTAssertEqual(document.projects[0].status, .active)
        XCTAssertEqual(document.projects[0].startedAt, Date(timeIntervalSince1970: 15))
        XCTAssertNil(document.projects[0].completedAt)
        XCTAssertEqual(document.projects[0].updatedAt, Date(timeIntervalSince1970: 700))
    }

    func testReopenLegacyProjectUsesCreatedAtAsStartTime() throws {
        var project = PlannedProject.existingProject(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000019")!,
            name: "Legacy",
            path: "/tmp/Legacy",
            type: .other,
            now: Date(timeIntervalSince1970: 10)
        )
        project.status = .completed
        project.startedAt = nil
        project.completedAt = Date(timeIntervalSince1970: 20)
        var document = ProjectDocument(projects: [project])
        let service = ProjectService(now: { Date(timeIntervalSince1970: 710) })

        try service.reopenProject(id: project.id, in: &document)

        XCTAssertEqual(document.projects[0].status, .active)
        XCTAssertEqual(document.projects[0].startedAt, Date(timeIntervalSince1970: 10))
        XCTAssertNil(document.projects[0].completedAt)
        XCTAssertEqual(document.projects[0].updatedAt, Date(timeIntervalSince1970: 710))
    }

    func testUpdateAndDeleteProject() throws {
        var document = ProjectDocument(projects: [
            PlannedProject.existingProject(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000012")!,
                name: "Old",
                path: "/tmp/Old",
                type: .other,
                now: Date(timeIntervalSince1970: 10)
            )
        ])
        let service = ProjectService(now: { Date(timeIntervalSince1970: 800) })
        let id = document.projects[0].id

        try service.updateProject(
            id: id,
            name: "New",
            path: "/tmp/New",
            type: .harmony,
            ideOverride: .applicationPath("/Applications/DevEco Studio.app"),
            in: &document
        )
        XCTAssertEqual(document.projects[0].name, "New")
        XCTAssertEqual(document.projects[0].path, "/tmp/New")
        XCTAssertEqual(document.projects[0].type, .harmony)
        XCTAssertEqual(document.projects[0].updatedAt, Date(timeIntervalSince1970: 800))

        try service.moveToTrash(id: id, in: &document)
        XCTAssertEqual(document.projects[0].status, .trash)
        XCTAssertEqual(document.projects[0].statusBeforeTrash, .todo)
    }

    func testTrashRestorePermanentDeleteAndEmptyTrash() throws {
        var active = PlannedProject.existingProject(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000017")!,
            name: "Active",
            path: "/tmp/Active",
            type: .ios,
            now: Date(timeIntervalSince1970: 10)
        )
        active.status = .active
        let completed = PlannedProject.existingProject(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000018")!,
            name: "Completed",
            path: "/tmp/Completed",
            type: .android,
            now: Date(timeIntervalSince1970: 20)
        )
        var document = ProjectDocument(projects: [active, completed])
        let service = ProjectService(now: { Date(timeIntervalSince1970: 904) })

        try service.moveToTrash(id: active.id, in: &document)
        XCTAssertEqual(document.projects[0].status, .trash)
        XCTAssertEqual(document.projects[0].statusBeforeTrash, .active)

        try service.restoreFromTrash(id: active.id, in: &document)
        XCTAssertEqual(document.projects[0].status, .active)
        XCTAssertNil(document.projects[0].statusBeforeTrash)

        try service.moveToTrash(id: active.id, in: &document)
        try service.permanentlyDeleteProject(id: active.id, from: &document)
        XCTAssertEqual(document.projects.map(\.name), ["Completed"])

        try service.moveToTrash(id: completed.id, in: &document)
        service.emptyTrash(in: &document)
        XCTAssertTrue(document.projects.isEmpty)
    }

    func testUpdateAliasStoresTrimmedAliasAndUpdatesTimestamp() throws {
        var document = ProjectDocument(projects: [
            PlannedProject.existingProject(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000013")!,
                name: "Project",
                path: "/tmp/Project",
                type: .ios,
                now: Date(timeIntervalSince1970: 10)
            )
        ])
        let service = ProjectService(now: { Date(timeIntervalSince1970: 900) })
        let id = document.projects[0].id

        try service.updateAlias(id: id, alias: "  核心客户 App  ", in: &document)

        XCTAssertEqual(document.projects[0].alias, "核心客户 App")
        XCTAssertEqual(document.projects[0].updatedAt, Date(timeIntervalSince1970: 900))
    }

    func testUpdateAliasClearsBlankAlias() throws {
        var project = PlannedProject.existingProject(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000014")!,
            name: "Project",
            path: "/tmp/Project",
            type: .ios,
            now: Date(timeIntervalSince1970: 10)
        )
        project.alias = "Old Alias"
        var document = ProjectDocument(projects: [project])
        let service = ProjectService(now: { Date(timeIntervalSince1970: 901) })

        try service.updateAlias(id: project.id, alias: "   ", in: &document)

        XCTAssertNil(document.projects[0].alias)
    }

    func testUpdateGroupCollapseAndManageGroups() throws {
        let first = PlannedProject.existingProject(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000021")!,
            name: "First",
            path: "/tmp/First",
            type: .ios,
            now: Date(timeIntervalSince1970: 10)
        )
        let second = PlannedProject.existingProject(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000022")!,
            name: "Second",
            path: "/tmp/Second",
            type: .ios,
            now: Date(timeIntervalSince1970: 20)
        )
        var document = ProjectDocument(projects: [first, second])
        let service = ProjectService(now: { Date(timeIntervalSince1970: 910) })

        try service.updateGroup(id: first.id, groupName: "  客户端  ", in: &document)
        service.renameGroup(from: "客户端", to: "移动端", in: &document)
        service.deleteGroup("移动端", in: &document)
        try service.updateGroup(id: first.id, groupName: "客户端", in: &document)
        service.createGroup("后端", in: &document)
        service.moveProjects(ids: [second.id], toGroup: "后端", in: &document)
        try service.setCollapsed(id: first.id, isCollapsed: true, in: &document)

        XCTAssertEqual(document.projects[0].groupName, "客户端")
        XCTAssertEqual(document.projects[1].groupName, "后端")
        XCTAssertEqual(document.groups?.map(\.name), ["后端", "客户端"])
        XCTAssertEqual(document.projects[0].isCollapsed, true)
    }

    func testSetCollapsedForStatusOnlyUpdatesProjectsInThatColumn() {
        var todo = PlannedProject.existingProject(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000031")!,
            name: "Todo",
            path: "/tmp/Todo",
            type: .ios,
            now: Date(timeIntervalSince1970: 10)
        )
        todo.isCollapsed = false
        var active = PlannedProject.existingProject(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000032")!,
            name: "Active",
            path: "/tmp/Active",
            type: .ios,
            now: Date(timeIntervalSince1970: 20)
        )
        active.status = .active
        active.isCollapsed = false
        var completed = PlannedProject.existingProject(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000033")!,
            name: "Completed",
            path: "/tmp/Completed",
            type: .ios,
            now: Date(timeIntervalSince1970: 30)
        )
        completed.status = .completed
        completed.isCollapsed = false
        var document = ProjectDocument(projects: [todo, active, completed])
        let service = ProjectService(now: { Date(timeIntervalSince1970: 920) })

        service.setCollapsed(status: .active, isCollapsed: true, in: &document)

        XCTAssertEqual(document.projects[0].isCollapsed, false)
        XCTAssertEqual(document.projects[1].isCollapsed, true)
        XCTAssertEqual(document.projects[1].updatedAt, Date(timeIntervalSince1970: 920))
        XCTAssertEqual(document.projects[2].isCollapsed, false)
    }

    func testBindExistingProjectToTodoUpdatesProjectMetadata() throws {
        var document = ProjectDocument(projects: [
            PlannedProject.existingProject(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000015")!,
                name: "客户登录改版",
                path: "",
                type: .other,
                now: Date(timeIntervalSince1970: 10)
            )
        ])
        document.projects[0].alias = "客户登录改版"
        let service = ProjectService(now: { Date(timeIntervalSince1970: 902) })

        try service.bindExistingProject(
            id: document.projects[0].id,
            name: "ClientApp",
            path: "/tmp/ClientApp",
            type: .ios,
            in: &document
        )

        XCTAssertEqual(document.projects[0].name, "ClientApp")
        XCTAssertEqual(document.projects[0].alias, "客户登录改版")
        XCTAssertEqual(document.projects[0].path, "/tmp/ClientApp")
        XCTAssertEqual(document.projects[0].type, .ios)
        XCTAssertEqual(document.projects[0].status, .active)
    }

    func testBindTemplateProjectToTodoMovesItActive() throws {
        var document = ProjectDocument(projects: [
            PlannedProject.existingProject(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000016")!,
                name: "客户登录改版",
                path: "",
                type: .other,
                now: Date(timeIntervalSince1970: 10)
            )
        ])
        document.projects[0].alias = "客户登录改版"
        let service = ProjectService(now: { Date(timeIntervalSince1970: 903) })

        try service.bindTemplateProject(
            id: document.projects[0].id,
            name: "ClientApp",
            path: "/tmp/ClientApp",
            type: .android,
            templateID: "android-kotlin",
            templateVersion: 1,
            remote: .none,
            in: &document
        )

        XCTAssertEqual(document.projects[0].name, "ClientApp")
        XCTAssertEqual(document.projects[0].alias, "客户登录改版")
        XCTAssertEqual(document.projects[0].status, .active)
        XCTAssertEqual(document.projects[0].template?.id, "android-kotlin")
    }
}
