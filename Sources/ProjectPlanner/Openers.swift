import Foundation

struct IDEOpener {
    func command(for project: PlannedProject) -> CommandInvocation {
        switch project.ideOverride {
        case .applicationPath(let path):
            return openApplication(path, projectPath: project.path)
        case .command(let command):
            return CommandInvocation(
                executableURL: URL(fileURLWithPath: "/usr/bin/env"),
                arguments: [command, project.path]
            )
        case .none:
            return openApplication(defaultApplicationName(for: project.type), projectPath: project.path)
        }
    }

    private func defaultApplicationName(for type: ProjectType) -> String {
        switch type {
        case .android:
            return "Android Studio"
        case .ios:
            return "Xcode"
        case .harmony:
            return "DevEco Studio"
        case .other:
            return "Visual Studio Code"
        }
    }

    private func openApplication(_ application: String, projectPath: String) -> CommandInvocation {
        CommandInvocation(
            executableURL: URL(fileURLWithPath: "/usr/bin/open"),
            arguments: ["-a", application, projectPath]
        )
    }
}

struct FinderOpener {
    func command(forDirectory directory: String) -> CommandInvocation {
        CommandInvocation(
            executableURL: URL(fileURLWithPath: "/usr/bin/open"),
            arguments: [directory]
        )
    }
}

struct TerminalOpener {
    private static let ghosttyURL = URL(fileURLWithPath: "/Applications/Ghostty.app")
    private static let codexExecutableURLs = [
        URL(fileURLWithPath: "/opt/homebrew/bin/codex"),
        URL(fileURLWithPath: "/usr/local/bin/codex")
    ]

    let fileExists: (URL) -> Bool

    init(fileExists: @escaping (URL) -> Bool = { FileManager.default.fileExists(atPath: $0.path) }) {
        self.fileExists = fileExists
    }

    func command(forDirectory directory: String) -> CommandInvocation {
        commands(forDirectory: directory)[0]
    }

    func commands(forDirectory directory: String) -> [CommandInvocation] {
        if fileExists(Self.ghosttyURL) {
            let script = """
            set targetPath to \(appleScriptStringLiteral(directory))
            set initialCommand to "codex resume --last" & linefeed
            tell application "Ghostty"
                activate
                set surfaceConfig to new surface configuration from {initial working directory:targetPath, initial input:initialCommand}
                if (count of windows) is 0 then
                    new window with configuration surfaceConfig
                else
                    new tab in front window with configuration surfaceConfig
                end if
            end tell
            """
            return [CommandInvocation(
                executableURL: URL(fileURLWithPath: "/usr/bin/osascript"),
                arguments: ["-e", script]
            )]
        }

        let codexExecutable = codexExecutablePath()
        let script = """
        set targetPath to \(appleScriptStringLiteral(directory))
        set codexPath to \(appleScriptStringLiteral(codexExecutable))
        tell application "Terminal"
            activate
            do script "cd " & quoted form of targetPath & " && " & quoted form of codexPath & " resume --last"
        end tell
        """
        return [CommandInvocation(
            executableURL: URL(fileURLWithPath: "/usr/bin/osascript"),
            arguments: ["-e", script]
        )]
    }

    private func appleScriptStringLiteral(_ value: String) -> String {
        let escaped = value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return "\"\(escaped)\""
    }

    private func codexExecutablePath() -> String {
        Self.codexExecutableURLs.first(where: fileExists)?.path ?? "codex"
    }
}
