import Foundation
import XCTest
@testable import ProjectPlanner

final class GitServiceTests: XCTestCase {
    func testInitializeLocalRepositoryRunsInitAddAndCommit() async throws {
        let runner = RecordingCommandRunner(results: [.success(), .success(), .success()])
        let service = GitService(runner: runner)

        try await service.initializeLocalRepository(at: "/tmp/App")

        XCTAssertEqual(runner.invocations.map(\.arguments), [
            ["-C", "/tmp/App", "init", "-b", "main"],
            ["-C", "/tmp/App", "add", "."],
            ["-C", "/tmp/App", "commit", "-m", "Initial project"]
        ])
    }

    func testExistingOriginReturnsRemoteURL() async throws {
        let runner = RecordingCommandRunner(results: [
            .success(stdout: "git@github.com:owner/repo.git\n")
        ])
        let service = GitService(runner: runner)

        let origin = try await service.existingOrigin(at: "/tmp/App")

        XCTAssertEqual(origin, "git@github.com:owner/repo.git")
        XCTAssertEqual(runner.invocations[0].arguments, ["-C", "/tmp/App", "remote", "get-url", "origin"])
    }

    func testMissingOriginReturnsNil() async throws {
        let runner = RecordingCommandRunner(results: [.failure(stderr: "No such remote")])
        let service = GitService(runner: runner)

        let origin = try await service.existingOrigin(at: "/tmp/App")

        XCTAssertNil(origin)
    }

    func testNoRemoteModeReturnsNoneWithoutCommands() async throws {
        let runner = RecordingCommandRunner(results: [])
        let service = GitService(runner: runner)

        let remote = try await service.configureRemote(
            at: "/tmp/App",
            request: .none
        )

        XCTAssertEqual(remote, .none)
        XCTAssertTrue(runner.invocations.isEmpty)
    }

    func testBindExistingEmptyRemotePushesInitialCommit() async throws {
        let runner = RecordingCommandRunner(results: [.success(), .success(stdout: ""), .success()])
        let service = GitService(runner: runner)

        let remote = try await service.configureRemote(
            at: "/tmp/App",
            request: .bindExisting(platform: .github, url: "git@github.com:owner/repo.git")
        )

        XCTAssertEqual(remote.setupState, .pushed)
        XCTAssertEqual(remote.url, "git@github.com:owner/repo.git")
        XCTAssertEqual(runner.invocations.map(\.arguments), [
            ["-C", "/tmp/App", "remote", "add", "origin", "git@github.com:owner/repo.git"],
            ["ls-remote", "git@github.com:owner/repo.git"],
            ["-C", "/tmp/App", "push", "-u", "origin", "main"]
        ])
    }

    func testBindExistingNonEmptyRemoteDoesNotPush() async throws {
        let runner = RecordingCommandRunner(results: [
            .success(),
            .success(stdout: "abc123\tHEAD\n")
        ])
        let service = GitService(runner: runner)

        let remote = try await service.configureRemote(
            at: "/tmp/App",
            request: .bindExisting(platform: .gitee, url: "git@gitee.com:owner/repo.git")
        )

        XCTAssertEqual(remote.setupState, .needsManualSync)
        XCTAssertEqual(remote.lastError, "远程仓库已有提交，已绑定 origin，但未推送本地模板。")
        XCTAssertEqual(runner.invocations.count, 2)
    }

    func testCreateRemoteUsesPlatformCLIThenPushes() async throws {
        let runner = RecordingCommandRunner(results: [.success(stdout: "git@github.com:owner/repo.git\n"), .success()])
        let service = GitService(runner: runner)

        let remote = try await service.configureRemote(
            at: "/tmp/App",
            request: .createNew(platform: .github, repositoryName: "owner/repo")
        )

        XCTAssertEqual(remote.setupState, .pushed)
        XCTAssertEqual(remote.platform, .github)
        XCTAssertEqual(remote.url, "git@github.com:owner/repo.git")
        XCTAssertEqual(runner.invocations[0].executableURL.path, "/usr/bin/env")
        XCTAssertEqual(runner.invocations[0].arguments, [
            "gh", "repo", "create", "owner/repo", "--private", "--source", "/tmp/App", "--remote", "origin"
        ])
        XCTAssertEqual(runner.invocations[1].arguments, ["-C", "/tmp/App", "push", "-u", "origin", "main"])
    }
}

private final class RecordingCommandRunner: CommandRunning {
    enum Stub {
        case success(stdout: String = "")
        case failure(stderr: String)
    }

    private(set) var invocations: [CommandInvocation] = []
    private var results: [Stub]

    init(results: [Stub]) {
        self.results = results
    }

    func run(_ invocation: CommandInvocation) async throws -> CommandResult {
        invocations.append(invocation)
        let result = results.isEmpty ? .success() : results.removeFirst()
        switch result {
        case .success(let stdout):
            return CommandResult(exitCode: 0, standardOutput: Data(stdout.utf8), standardError: Data())
        case .failure(let stderr):
            return CommandResult(exitCode: 1, standardOutput: Data(), standardError: Data(stderr.utf8))
        }
    }
}
