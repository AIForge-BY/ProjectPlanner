import XCTest
@testable import ProjectPlanner

final class TemplateServiceTests: XCTestCase {
    func testGenerateIOSTemplateWritesRunnableXcodeProjectFilesAndAgentsFile() throws {
        let directory = temporaryDirectory()
        let service = TemplateService()

        let result = try service.generateTemplate(type: .ios, name: "ClientApp", at: directory)

        XCTAssertEqual(result.id, "ios-swiftui")
        XCTAssertTrue(fileExists(directory, "ClientApp.xcodeproj/project.pbxproj"))
        XCTAssertTrue(fileExists(directory, "ClientApp/App.swift"))
        XCTAssertTrue(fileExists(directory, "ClientApp/ContentView.swift"))
        XCTAssertTrue(fileExists(directory, "AGENTS.md"))
        XCTAssertTrue(try read(directory, "AGENTS.md").contains("Project type: iOS"))
    }

    func testGenerateAndroidTemplateWritesGradleProjectAndAgentsFile() throws {
        let directory = temporaryDirectory()
        let service = TemplateService()

        let result = try service.generateTemplate(type: .android, name: "ClientApp", at: directory)

        XCTAssertEqual(result.id, "android-kotlin")
        XCTAssertTrue(fileExists(directory, "settings.gradle.kts"))
        XCTAssertTrue(fileExists(directory, "build.gradle.kts"))
        XCTAssertTrue(fileExists(directory, "app/build.gradle.kts"))
        XCTAssertTrue(fileExists(directory, "app/src/main/AndroidManifest.xml"))
        XCTAssertTrue(fileExists(directory, "app/src/main/java/com/example/clientapp/MainActivity.kt"))
        XCTAssertTrue(try read(directory, "AGENTS.md").contains("Project type: Android"))
    }

    func testGenerateHarmonyTemplateWritesDevEcoProjectAndAgentsFile() throws {
        let directory = temporaryDirectory()
        let service = TemplateService()

        let result = try service.generateTemplate(type: .harmony, name: "ClientApp", at: directory)

        XCTAssertEqual(result.id, "harmony-arkts")
        XCTAssertTrue(fileExists(directory, "build-profile.json5"))
        XCTAssertTrue(fileExists(directory, "AppScope/app.json5"))
        XCTAssertTrue(fileExists(directory, "entry/src/main/module.json5"))
        XCTAssertTrue(fileExists(directory, "entry/src/main/ets/pages/Index.ets"))
        XCTAssertTrue(try read(directory, "AGENTS.md").contains("Project type: HarmonyOS"))
    }

    func testGenerateOtherTemplateWritesVSCodeFriendlyProjectAndAgentsFile() throws {
        let directory = temporaryDirectory()
        let service = TemplateService()

        let result = try service.generateTemplate(type: .other, name: "ClientApp", at: directory)

        XCTAssertEqual(result.id, "generic-vscode")
        XCTAssertTrue(fileExists(directory, "README.md"))
        XCTAssertTrue(fileExists(directory, ".vscode/settings.json"))
        XCTAssertTrue(try read(directory, "AGENTS.md").contains("Project type: Other"))
    }

    private func temporaryDirectory() -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ProjectPlannerTemplateTests")
            .appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func fileExists(_ directory: URL, _ path: String) -> Bool {
        FileManager.default.fileExists(atPath: directory.appendingPathComponent(path).path)
    }

    private func read(_ directory: URL, _ path: String) throws -> String {
        try String(contentsOf: directory.appendingPathComponent(path), encoding: .utf8)
    }
}
