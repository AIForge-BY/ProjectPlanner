import Foundation

protocol GitManaging {
    func initializeLocalRepository(at path: String) async throws
    func existingOrigin(at path: String) async throws -> String?
    func configureRemote(at path: String, request: RemoteSetupRequest) async throws -> RemoteInfo
}

enum RemoteSetupRequest: Equatable {
    case none
    case createNew(platform: RemotePlatform, repositoryName: String)
    case bindExisting(platform: RemotePlatform, url: String)
}

enum GitServiceError: LocalizedError, Equatable {
    case commandFailed(String)
    case unsupportedRemotePlatform(RemotePlatform)

    var errorDescription: String? {
        switch self {
        case .commandFailed(let message):
            return "Git 命令失败：\(message)"
        case .unsupportedRemotePlatform(let platform):
            return "暂不支持创建远程平台：\(platform.rawValue)"
        }
    }
}

struct GitService {
    private let runner: CommandRunning

    init(runner: CommandRunning = ProcessCommandRunner()) {
        self.runner = runner
    }

    func initializeLocalRepository(at path: String) async throws {
        try await runGit(["-C", path, "init", "-b", "main"])
        try await runGit(["-C", path, "add", "."])
        try await runGit(["-C", path, "commit", "-m", "Initial project"])
    }

    func existingOrigin(at path: String) async throws -> String? {
        let result = try await runner.run(gitCommand(["-C", path, "remote", "get-url", "origin"]))
        guard result.exitCode == 0 else {
            return nil
        }
        return String(data: result.standardOutput, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nilIfEmpty
    }

    func configureRemote(at path: String, request: RemoteSetupRequest) async throws -> RemoteInfo {
        switch request {
        case .none:
            return .none
        case .bindExisting(let platform, let url):
            try await runGit(["-C", path, "remote", "add", "origin", url])
            return try await pushIfRemoteIsEmpty(path: path, platform: platform, url: url, mode: .bindExisting)
        case .createNew(let platform, let repositoryName):
            let url = try await createRemote(platform: platform, repositoryName: repositoryName, sourcePath: path)
            try await runGit(["-C", path, "push", "-u", "origin", "main"])
            return RemoteInfo(platform: platform, url: url, mode: .createNew, setupState: .pushed, lastError: nil)
        }
    }

    private func pushIfRemoteIsEmpty(
        path: String,
        platform: RemotePlatform,
        url: String,
        mode: RemoteMode
    ) async throws -> RemoteInfo {
        let result = try await runner.run(gitCommand(["ls-remote", url]))
        guard result.exitCode == 0 else {
            throw GitServiceError.commandFailed(errorMessage(from: result))
        }
        let output = String(data: result.standardOutput, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if output.isEmpty {
            try await runGit(["-C", path, "push", "-u", "origin", "main"])
            return RemoteInfo(platform: platform, url: url, mode: mode, setupState: .pushed, lastError: nil)
        }
        return RemoteInfo(
            platform: platform,
            url: url,
            mode: mode,
            setupState: .needsManualSync,
            lastError: "远程仓库已有提交，已绑定 origin，但未推送本地模板。"
        )
    }

    private func createRemote(
        platform: RemotePlatform,
        repositoryName: String,
        sourcePath: String
    ) async throws -> String {
        let invocation: CommandInvocation
        switch platform {
        case .github:
            invocation = CommandInvocation(
                executableURL: URL(fileURLWithPath: "/usr/bin/env"),
                arguments: [
                    "gh",
                    "repo",
                    "create",
                    repositoryName,
                    "--private",
                    "--source",
                    sourcePath,
                    "--remote",
                    "origin"
                ]
            )
        case .gitee:
            invocation = CommandInvocation(
                executableURL: URL(fileURLWithPath: "/usr/bin/env"),
                arguments: [
                    "gitee",
                    "repo",
                    "create",
                    repositoryName,
                    "--private",
                    "--source",
                    sourcePath,
                    "--remote",
                    "origin"
                ]
            )
        }

        let result = try await runner.run(invocation)
        guard result.exitCode == 0 else {
            throw GitServiceError.commandFailed(errorMessage(from: result))
        }
        return String(data: result.standardOutput, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nilIfEmpty ?? repositoryName
    }

    private func runGit(_ arguments: [String]) async throws {
        let result = try await runner.run(gitCommand(arguments))
        guard result.exitCode == 0 else {
            throw GitServiceError.commandFailed(errorMessage(from: result))
        }
    }

    private func gitCommand(_ arguments: [String]) -> CommandInvocation {
        CommandInvocation(executableURL: URL(fileURLWithPath: "/usr/bin/git"), arguments: arguments)
    }

    private func errorMessage(from result: CommandResult) -> String {
        let stderr = String(data: result.standardError, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let stdout = String(data: result.standardOutput, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return stderr?.isEmpty == false ? stderr! : (stdout?.isEmpty == false ? stdout! : "unknown error")
    }
}

extension GitService: GitManaging {}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
