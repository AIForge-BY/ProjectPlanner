import XCTest
@testable import ProjectPlanner

final class OpenersTests: XCTestCase {
    func testIDESelectionUsesProjectTypeDefaults() {
        let opener = IDEOpener()

        XCTAssertEqual(opener.command(for: project(type: .android)).arguments, ["-a", "Android Studio", "/tmp/App"])
        XCTAssertEqual(opener.command(for: project(type: .ios)).arguments, ["-a", "Xcode", "/tmp/App"])
        XCTAssertEqual(opener.command(for: project(type: .harmony)).arguments, ["-a", "DevEco Studio", "/tmp/App"])
        XCTAssertEqual(opener.command(for: project(type: .other)).arguments, ["-a", "Visual Studio Code", "/tmp/App"])
    }

    func testIDESelectionUsesApplicationOverride() {
        var item = project(type: .other)
        item.ideOverride = .applicationPath("/Applications/Cursor.app")
        let opener = IDEOpener()

        let command = opener.command(for: item)

        XCTAssertEqual(command.executableURL.path, "/usr/bin/open")
        XCTAssertEqual(command.arguments, ["-a", "/Applications/Cursor.app", "/tmp/App"])
    }

    func testIDESelectionUsesCommandOverride() {
        var item = project(type: .other)
        item.ideOverride = .command("code-insiders")
        let opener = IDEOpener()

        let command = opener.command(for: item)

        XCTAssertEqual(command.executableURL.path, "/usr/bin/env")
        XCTAssertEqual(command.arguments, ["code-insiders", "/tmp/App"])
    }

    func testTerminalOpenerUsesGhosttyWhenInstalled() {
        let opener = TerminalOpener(fileExists: { $0.path == "/Applications/Ghostty.app" })

        let commands = opener.commands(forDirectory: "/tmp/App")

        XCTAssertEqual(commands.count, 1)
        XCTAssertEqual(commands[0].executableURL.path, "/usr/bin/open")
        XCTAssertEqual(commands[0].arguments, [
            "-a",
            "/Applications/Ghostty.app",
            "--args",
            "--working-directory=/tmp/App",
            "--input=codex resume --last\n"
        ])
    }

    func testTerminalOpenerFallsBackToTerminalAppleScript() {
        let opener = TerminalOpener(fileExists: { $0.path == "/opt/homebrew/bin/codex" })

        let command = opener.command(forDirectory: "/tmp/App With Space")

        XCTAssertEqual(command.executableURL.path, "/usr/bin/osascript")
        XCTAssertEqual(command.arguments.count, 2)
        XCTAssertEqual(command.arguments[0], "-e")
        XCTAssertTrue(command.arguments[1].contains("tell application \"Terminal\""))
        XCTAssertTrue(command.arguments[1].contains("quoted form of targetPath"))
        XCTAssertTrue(command.arguments[1].contains("\"/tmp/App With Space\""))
        XCTAssertTrue(command.arguments[1].contains("set codexPath to \"/opt/homebrew/bin/codex\""))
        XCTAssertTrue(command.arguments[1].contains("quoted form of codexPath"))
        XCTAssertTrue(command.arguments[1].contains(" resume --last"))
    }

    func testFinderOpenerUsesOpenCommand() {
        let command = FinderOpener().command(forDirectory: "/tmp/App")

        XCTAssertEqual(command.executableURL.path, "/usr/bin/open")
        XCTAssertEqual(command.arguments, ["/tmp/App"])
    }

    private func project(type: ProjectType) -> PlannedProject {
        PlannedProject.existingProject(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000021")!,
            name: "App",
            path: "/tmp/App",
            type: type,
            now: Date(timeIntervalSince1970: 10)
        )
    }
}
