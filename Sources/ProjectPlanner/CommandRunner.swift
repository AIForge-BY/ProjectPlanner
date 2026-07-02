import Foundation

struct CommandInvocation: Equatable {
    var executableURL: URL
    var arguments: [String]
}

struct CommandResult: Equatable {
    var exitCode: Int32
    var standardOutput: Data
    var standardError: Data
}

protocol CommandRunning {
    func run(_ invocation: CommandInvocation) async throws -> CommandResult
}

struct ProcessCommandRunner: CommandRunning {
    func run(_ invocation: CommandInvocation) async throws -> CommandResult {
        let process = Process()
        process.executableURL = invocation.executableURL
        process.arguments = invocation.arguments

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        try process.run()
        process.waitUntilExit()

        return CommandResult(
            exitCode: process.terminationStatus,
            standardOutput: stdout.fileHandleForReading.readDataToEndOfFile(),
            standardError: stderr.fileHandleForReading.readDataToEndOfFile()
        )
    }
}
