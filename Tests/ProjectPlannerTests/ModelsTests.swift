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
        XCTAssertEqual(project.startedAt, Date(timeIntervalSince1970: 100))
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
        XCTAssertNil(project.startedAt)
        XCTAssertNil(project.completedAt)
        XCTAssertEqual(project.isCollapsed, false)
    }

    func testLegacyProjectWithoutStartedAtDecodesAsNil() throws {
        let json = """
        {
          "schemaVersion" : 1,
          "groups" : [],
          "projects" : [
            {
              "id" : "00000000-0000-0000-0000-000000000051",
              "name" : "Legacy",
              "path" : "/tmp/Legacy",
              "type" : "ios",
              "groupName" : null,
              "sortOrder" : 10,
              "isCollapsed" : false,
              "status" : "todo",
              "createdAt" : "1970-01-01T00:00:10Z",
              "updatedAt" : "1970-01-01T00:00:10Z",
              "completedAt" : null,
              "remote" : {
                "mode" : "none",
                "setupState" : "none"
              }
            }
          ]
        }
        """

        let document = try JSONDecoder.projectPlanner.decode(ProjectDocument.self, from: Data(json.utf8))

        XCTAssertNil(document.projects[0].startedAt)
    }

    func testDocumentDefaultsToSchemaVersionOne() {
        let document = ProjectDocument()

        XCTAssertEqual(document.schemaVersion, 1)
        XCTAssertEqual(document.projects, [])
    }
}
