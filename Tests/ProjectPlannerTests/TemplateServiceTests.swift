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
        let gitIgnore = try read(directory, ".gitignore")
        XCTAssertTrue(gitIgnore.contains(".agent/"))
        XCTAssertTrue(gitIgnore.contains(".codex/"))
        XCTAssertTrue(gitIgnore.contains(".claude/"))
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
        let gitIgnore = try read(directory, ".gitignore")
        XCTAssertTrue(gitIgnore.contains(".agent/"))
        XCTAssertTrue(gitIgnore.contains(".codex/"))
        XCTAssertTrue(gitIgnore.contains(".claude/"))
        XCTAssertTrue(try read(directory, "AGENTS.md").contains("Project type: Android"))
    }

    func testGenerateHarmonyTemplateWritesDevEcoProjectAndAgentsFile() throws {
        let directory = temporaryDirectory()
        let service = TemplateService()

        let result = try service.generateTemplate(type: .harmony, name: "ClientApp", at: directory)

        XCTAssertEqual(result.id, "harmony-arkts")
        XCTAssertTrue(fileExists(directory, ".gitignore"))
        XCTAssertTrue(fileExists(directory, "build-profile.json5"))
        XCTAssertTrue(fileExists(directory, "hvigorfile.ts"))
        XCTAssertTrue(fileExists(directory, "hvigor/hvigor-config.json5"))
        XCTAssertTrue(fileExists(directory, "oh-package.json5"))
        XCTAssertTrue(fileExists(directory, "AppScope/app.json5"))
        XCTAssertTrue(fileExists(directory, "AppScope/resources/base/element/string.json"))
        XCTAssertTrue(fileExists(directory, "AppScope/resources/base/media/layered_image.json"))
        XCTAssertTrue(fileExists(directory, "AppScope/resources/base/media/background.png"))
        XCTAssertTrue(fileExists(directory, "AppScope/resources/base/media/foreground.png"))
        XCTAssertTrue(fileExists(directory, "entry/build-profile.json5"))
        XCTAssertTrue(fileExists(directory, "entry/.gitignore"))
        XCTAssertTrue(fileExists(directory, "entry/hvigorfile.ts"))
        XCTAssertTrue(fileExists(directory, "entry/oh-package.json5"))
        XCTAssertTrue(fileExists(directory, "entry/src/main/module.json5"))
        XCTAssertTrue(fileExists(directory, "entry/src/main/resources/base/profile/main_pages.json"))
        XCTAssertTrue(fileExists(directory, "entry/src/main/resources/base/profile/backup_config.json"))
        XCTAssertTrue(fileExists(directory, "entry/src/main/resources/base/element/string.json"))
        XCTAssertTrue(fileExists(directory, "entry/src/main/resources/base/element/color.json"))
        XCTAssertTrue(fileExists(directory, "entry/src/main/resources/base/element/float.json"))
        XCTAssertTrue(fileExists(directory, "entry/src/main/resources/base/media/layered_image.json"))
        XCTAssertTrue(fileExists(directory, "entry/src/main/resources/base/media/background.png"))
        XCTAssertTrue(fileExists(directory, "entry/src/main/resources/base/media/foreground.png"))
        XCTAssertTrue(fileExists(directory, "entry/src/main/resources/base/media/startIcon.png"))
        XCTAssertTrue(fileExists(directory, "entry/src/main/ets/entryability/EntryAbility.ets"))
        XCTAssertTrue(fileExists(directory, "entry/src/main/ets/entrybackupability/EntryBackupAbility.ets"))
        XCTAssertTrue(fileExists(directory, "entry/src/main/ets/pages/Index.ets"))
        XCTAssertTrue(try read(directory, "AppScope/app.json5").contains("\"bundleName\": \"com.example.clientapp\""))
        XCTAssertTrue(try read(directory, "AppScope/resources/base/element/string.json").contains("\"value\": \"ClientApp\""))
        XCTAssertTrue(try read(directory, "entry/src/main/module.json5").contains("\"pages\": \"$profile:main_pages\""))
        XCTAssertTrue(try read(directory, "entry/src/main/ets/entryability/EntryAbility.ets").contains("windowStage.loadContent('pages/Index'"))
        XCTAssertTrue(try read(directory, "entry/src/main/ets/pages/Index.ets").contains("'Hello, ClientApp'"))
        let rootGitIgnore = try read(directory, ".gitignore")
        XCTAssertTrue(rootGitIgnore.contains(".hvigor/"))
        XCTAssertTrue(rootGitIgnore.contains(".agent/"))
        XCTAssertTrue(rootGitIgnore.contains(".codex/"))
        XCTAssertTrue(rootGitIgnore.contains(".claude/"))
        XCTAssertTrue(rootGitIgnore.contains(".idea/"))
        XCTAssertTrue(rootGitIgnore.contains("oh_modules/"))
        XCTAssertTrue(rootGitIgnore.contains("oh-package-lock.json5"))
        XCTAssertTrue(rootGitIgnore.contains("build/"))
        let entryGitIgnore = try read(directory, "entry/.gitignore")
        XCTAssertTrue(entryGitIgnore.contains("build/"))
        XCTAssertTrue(entryGitIgnore.contains("oh_modules/"))
        XCTAssertTrue(entryGitIgnore.contains("oh-package-lock.json5"))
        XCTAssertTrue(try read(directory, "AGENTS.md").contains("Project type: HarmonyOS"))
    }

    func testGenerateOtherTemplateWritesVSCodeFriendlyProjectAndAgentsFile() throws {
        let directory = temporaryDirectory()
        let service = TemplateService()

        let result = try service.generateTemplate(type: .other, name: "ClientApp", at: directory)

        XCTAssertEqual(result.id, "generic-vscode")
        XCTAssertTrue(fileExists(directory, "README.md"))
        XCTAssertTrue(fileExists(directory, ".vscode/settings.json"))
        let gitIgnore = try read(directory, ".gitignore")
        XCTAssertTrue(gitIgnore.contains(".agent/"))
        XCTAssertTrue(gitIgnore.contains(".codex/"))
        XCTAssertTrue(gitIgnore.contains(".claude/"))
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
