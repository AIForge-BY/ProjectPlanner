import XCTest
@testable import ProjectPlanner

final class ProjectStoreTests: XCTestCase {
    func testLoadCreatesDefaultDocumentWhenFileDoesNotExist() throws {
        let store = ProjectStore(fileURL: temporaryDirectory().appendingPathComponent("projects.json"))

        let document = try store.load()

        XCTAssertEqual(document, ProjectDocument())
    }

    func testSaveAndLoadPreservesSchemaVersionAndProjects() throws {
        let fileURL = temporaryDirectory().appendingPathComponent("projects.json")
        let store = ProjectStore(fileURL: fileURL)
        let project = PlannedProject.existingProject(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            name: "Existing",
            path: "/tmp/Existing",
            type: .other,
            now: Date(timeIntervalSince1970: 300)
        )
        let document = ProjectDocument(schemaVersion: 7, projects: [project])

        try store.save(document)
        let loaded = try store.load()

        XCTAssertEqual(loaded, document)
    }

    func testDefaultStoreURLUsesApplicationSupportDirectory() {
        let url = ProjectStore.defaultFileURL(
            homeDirectory: URL(fileURLWithPath: "/Users/example", isDirectory: true)
        )

        XCTAssertEqual(
            url.path,
            "/Users/example/Library/Application Support/ProjectPlanner/projects.json"
        )
    }

    private func temporaryDirectory() -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ProjectPlannerTests")
            .appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}
