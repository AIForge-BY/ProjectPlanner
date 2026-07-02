import Foundation
import XCTest
@testable import ProjectPlanner

@MainActor
final class AppStateTests: XCTestCase {
    func testLoadReadsDocumentFromStore() async {
        let project = PlannedProject.existingProject(
            name: "Existing",
            path: "/tmp/Existing",
            type: .other,
            now: Date(timeIntervalSince1970: 10)
        )
        let store = MemoryProjectStore(document: ProjectDocument(projects: [project]))
        let appState = AppState(store: store)

        await appState.load()

        XCTAssertEqual(appState.document.projects, [project])
    }

    func testAddExistingProjectPersistsTodoProject() async {
        let store = MemoryProjectStore()
        let appState = AppState(
            store: store,
            projectService: ProjectService(now: { Date(timeIntervalSince1970: 900) })
        )

        await appState.addExistingProject(name: "Legacy", path: "/tmp/Legacy", type: .android)

        XCTAssertEqual(appState.document.projects.count, 1)
        XCTAssertEqual(appState.document.projects[0].status, .todo)
        XCTAssertEqual(store.savedDocuments.last, appState.document)
    }

    func testCreateDefaultProjectGeneratesTemplateInitializesGitAndPersistsActiveProject() async {
        let directory = temporaryDirectory()
        let store = MemoryProjectStore()
        let git = MemoryGitService(remote: RemoteInfo(platform: .github, url: "git@github.com:owner/app.git", mode: .createNew, setupState: .pushed, lastError: nil))
        let appState = AppState(
            store: store,
            projectService: ProjectService(now: { Date(timeIntervalSince1970: 1000) }),
            templateService: TemplateService(),
            gitService: git
        )

        await appState.createDefaultProject(
            name: "ClientApp",
            parentDirectory: directory,
            type: .ios,
            remoteRequest: .createNew(platform: .github, repositoryName: "owner/app")
        )

        XCTAssertEqual(git.initializedPaths, [directory.appendingPathComponent("ClientApp").path])
        XCTAssertEqual(appState.document.projects.count, 1)
        XCTAssertEqual(appState.document.projects[0].status, .active)
        XCTAssertEqual(appState.document.projects[0].remote.setupState, .pushed)
        XCTAssertTrue(FileManager.default.fileExists(atPath: directory.appendingPathComponent("ClientApp/AGENTS.md").path))
    }

    func testCreateDefaultProjectKeepsProjectWhenRemoteSetupFails() async {
        let directory = temporaryDirectory()
        let store = MemoryProjectStore()
        let git = MemoryGitService(error: GitServiceError.commandFailed("missing credentials"))
        let appState = AppState(
            store: store,
            projectService: ProjectService(now: { Date(timeIntervalSince1970: 1100) }),
            templateService: TemplateService(),
            gitService: git
        )

        await appState.createDefaultProject(
            name: "ClientApp",
            parentDirectory: directory,
            type: .android,
            remoteRequest: .createNew(platform: .github, repositoryName: "owner/app")
        )

        XCTAssertEqual(appState.document.projects.count, 1)
        XCTAssertEqual(appState.document.projects[0].status, .active)
        XCTAssertEqual(appState.document.projects[0].remote.setupState, .failed)
        XCTAssertEqual(appState.document.projects[0].remote.lastError, "Git 命令失败：missing credentials")
        XCTAssertEqual(appState.errorMessage, "Git 命令失败：missing credentials")
    }

    private func temporaryDirectory() -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ProjectPlannerAppStateTests")
            .appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}

private final class MemoryProjectStore: ProjectStoring {
    var document: ProjectDocument
    private(set) var savedDocuments: [ProjectDocument] = []

    init(document: ProjectDocument = ProjectDocument()) {
        self.document = document
    }

    func load() throws -> ProjectDocument {
        document
    }

    func save(_ document: ProjectDocument) throws {
        self.document = document
        savedDocuments.append(document)
    }
}

private final class MemoryGitService: GitManaging {
    var initializedPaths: [String] = []
    let remote: RemoteInfo
    let error: Error?

    init(remote: RemoteInfo = .none, error: Error? = nil) {
        self.remote = remote
        self.error = error
    }

    func initializeLocalRepository(at path: String) async throws {
        initializedPaths.append(path)
    }

    func existingOrigin(at path: String) async throws -> String? {
        nil
    }

    func configureRemote(at path: String, request: RemoteSetupRequest) async throws -> RemoteInfo {
        if let error {
            throw error
        }
        return remote
    }
}
