import XCTest
@testable import ProjectPlanner

final class ModelsTests: XCTestCase {
    func testNewTemplateProjectStartsActiveWithTemplateMetadata() {
        let project = PlannedProject.templateProject(
            name: "Client iOS",
            path: "/tmp/ClientiOS",
            type: .ios,
            templateID: "ios-swiftui",
            templateVersion: 1,
            now: Date(timeIntervalSince1970: 100)
        )

        XCTAssertEqual(project.name, "Client iOS")
        XCTAssertNil(project.alias)
        XCTAssertEqual(project.path, "/tmp/ClientiOS")
        XCTAssertEqual(project.type, .ios)
        XCTAssertEqual(project.status, .active)
        XCTAssertEqual(project.createdAt, Date(timeIntervalSince1970: 100))
        XCTAssertEqual(project.updatedAt, Date(timeIntervalSince1970: 100))
        XCTAssertNil(project.completedAt)
        XCTAssertEqual(project.isCollapsed, true)
        XCTAssertEqual(project.template?.id, "ios-swiftui")
        XCTAssertEqual(project.template?.version, 1)
    }

    func testExistingProjectStartsTodoWithoutTemplateMetadata() {
        let project = PlannedProject.existingProject(
            name: "Legacy Android",
            path: "/tmp/LegacyAndroid",
            type: .android,
            now: Date(timeIntervalSince1970: 200)
        )

        XCTAssertEqual(project.status, .todo)
        XCTAssertNil(project.alias)
        XCTAssertNil(project.template)
        XCTAssertNil(project.completedAt)
        XCTAssertEqual(project.isCollapsed, false)
    }

    func testDocumentDefaultsToSchemaVersionOne() {
        let document = ProjectDocument()

        XCTAssertEqual(document.schemaVersion, 1)
        XCTAssertEqual(document.projects, [])
    }
}
