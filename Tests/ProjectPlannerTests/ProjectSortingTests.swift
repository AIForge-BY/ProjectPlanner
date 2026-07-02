import XCTest
@testable import ProjectPlanner

final class ProjectSortingTests: XCTestCase {
    func testGroupsProjectsAndSortsWithinEachGroupByTime() {
        var backendEarly = project(
            id: "00000000-0000-0000-0000-000000000101",
            name: "Backend Early",
            group: "后端",
            createdAt: 10
        )
        backendEarly.startedAt = Date(timeIntervalSince1970: 100)
        var backendLate = project(
            id: "00000000-0000-0000-0000-000000000102",
            name: "Backend Late",
            group: "后端",
            createdAt: 20
        )
        backendLate.startedAt = Date(timeIntervalSince1970: 200)
        var ungroupedLate = project(
            id: "00000000-0000-0000-0000-000000000103",
            name: "Ungrouped Late",
            group: nil,
            createdAt: 30
        )
        ungroupedLate.startedAt = Date(timeIntervalSince1970: 300)
        var ungroupedEarly = project(
            id: "00000000-0000-0000-0000-000000000104",
            name: "Ungrouped Early",
            group: nil,
            createdAt: 40
        )
        ungroupedEarly.startedAt = Date(timeIntervalSince1970: 150)

        let groups = ProjectSorter.groupedProjects(
            [backendLate, ungroupedLate, backendEarly, ungroupedEarly],
            status: .active,
            sortField: .time,
            direction: .ascending
        )

        XCTAssertEqual(groups.map(\.name), ["未分组", "后端"])
        XCTAssertEqual(groups[0].projects.map(\.name), ["Ungrouped Early", "Ungrouped Late"])
        XCTAssertEqual(groups[1].projects.map(\.name), ["Backend Early", "Backend Late"])
    }

    func testSortsProjectNamesWithinEachGroup() {
        let alpha = project(
            id: "00000000-0000-0000-0000-000000000111",
            name: "Alpha",
            group: "客户端",
            createdAt: 30,
            status: .todo
        )
        let zeta = project(
            id: "00000000-0000-0000-0000-000000000112",
            name: "Zeta",
            group: "客户端",
            createdAt: 10,
            status: .todo
        )
        var beta = project(
            id: "00000000-0000-0000-0000-000000000113",
            name: "Original",
            group: "客户端",
            createdAt: 20,
            status: .todo
        )
        beta.alias = "Beta"

        let groups = ProjectSorter.groupedProjects(
            [zeta, beta, alpha],
            status: .todo,
            sortField: .name,
            direction: .ascending
        )

        XCTAssertEqual(groups.map(\.name), ["客户端"])
        XCTAssertEqual(groups[0].projects.map { $0.alias ?? $0.name }, ["Alpha", "Beta", "Zeta"])
    }

    func testLegacyActiveProjectsUseCreatedAtWhenStartedAtIsMissing() {
        var first = project(
            id: "00000000-0000-0000-0000-000000000121",
            name: "First",
            group: "客户端",
            createdAt: 10
        )
        first.startedAt = nil
        first.updatedAt = Date(timeIntervalSince1970: 1_000)
        var second = project(
            id: "00000000-0000-0000-0000-000000000122",
            name: "Second",
            group: "客户端",
            createdAt: 20
        )
        second.startedAt = nil
        second.updatedAt = Date(timeIntervalSince1970: 30)

        let groups = ProjectSorter.groupedProjects(
            [second, first],
            status: .active,
            sortField: .time,
            direction: .ascending
        )

        XCTAssertEqual(ProjectSorter.time(for: first, status: .active), Date(timeIntervalSince1970: 10))
        XCTAssertEqual(groups[0].projects.map(\.name), ["First", "Second"])
    }

    private func project(
        id: String,
        name: String,
        group: String?,
        createdAt: TimeInterval,
        status: ProjectStatus = .active
    ) -> PlannedProject {
        var project = PlannedProject.existingProject(
            id: UUID(uuidString: id)!,
            name: name,
            path: "/tmp/\(name)",
            type: .ios,
            now: Date(timeIntervalSince1970: createdAt)
        )
        project.groupName = group
        project.status = status
        return project
    }
}
