import Foundation

protocol TemplateGenerating {
    func generateTemplate(type: ProjectType, name: String, at directory: URL) throws -> GeneratedTemplate
}

struct GeneratedTemplate: Equatable {
    var id: String
    var version: Int
}

struct TemplateService {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func generateTemplate(type: ProjectType, name: String, at directory: URL) throws -> GeneratedTemplate {
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        switch type {
        case .ios:
            try generateIOS(name: name, at: directory)
            try writeAgents(projectType: "iOS", at: directory)
            return GeneratedTemplate(id: "ios-swiftui", version: 1)
        case .android:
            try generateAndroid(name: name, at: directory)
            try writeAgents(projectType: "Android", at: directory)
            return GeneratedTemplate(id: "android-kotlin", version: 1)
        case .harmony:
            try generateHarmony(name: name, at: directory)
            try writeAgents(projectType: "HarmonyOS", at: directory)
            return GeneratedTemplate(id: "harmony-arkts", version: 1)
        case .other:
            try generateOther(name: name, at: directory)
            try writeAgents(projectType: "Other", at: directory)
            return GeneratedTemplate(id: "generic-vscode", version: 1)
        }
    }

    private func generateIOS(name: String, at directory: URL) throws {
        let module = sanitizedIdentifier(name)
        try write("ClientApp.xcodeproj/project.pbxproj", iosPBXProj(module: module), at: directory)
        try write("ClientApp/App.swift", """
        import SwiftUI

        @main
        struct \(module)App: App {
            var body: some Scene {
                WindowGroup {
                    ContentView()
                }
            }
        }
        """, at: directory)
        try write("ClientApp/ContentView.swift", """
        import SwiftUI

        struct ContentView: View {
            var body: some View {
                Text("Hello, \(name)")
                    .padding()
            }
        }
        """, at: directory)
    }

    private func generateAndroid(name: String, at directory: URL) throws {
        let packageName = "com.example.\(sanitizedIdentifier(name).lowercased())"
        let packagePath = packageName.replacingOccurrences(of: ".", with: "/")
        try write("settings.gradle.kts", """
        pluginManagement {
            repositories {
                google()
                mavenCentral()
                gradlePluginPortal()
            }
        }
        dependencyResolutionManagement { repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS); repositories { google(); mavenCentral() } }
        rootProject.name = "\(name)"
        include(":app")
        """, at: directory)
        try write("build.gradle.kts", """
        plugins {
            id("com.android.application") version "8.5.2" apply false
            id("org.jetbrains.kotlin.android") version "1.9.24" apply false
        }
        """, at: directory)
        try write("app/build.gradle.kts", """
        plugins {
            id("com.android.application")
            id("org.jetbrains.kotlin.android")
        }

        android {
            namespace = "\(packageName)"
            compileSdk = 35

            defaultConfig {
                applicationId = "\(packageName)"
                minSdk = 24
                targetSdk = 35
                versionCode = 1
                versionName = "1.0"
            }
        }
        """, at: directory)
        try write("app/src/main/AndroidManifest.xml", """
        <manifest xmlns:android="http://schemas.android.com/apk/res/android">
            <application android:theme="@style/AppTheme" android:label="\(name)">
                <activity android:name=".MainActivity" android:exported="true">
                    <intent-filter>
                        <action android:name="android.intent.action.MAIN" />
                        <category android:name="android.intent.category.LAUNCHER" />
                    </intent-filter>
                </activity>
            </application>
        </manifest>
        """, at: directory)
        try write("app/src/main/res/values/styles.xml", """
        <resources>
            <style name="AppTheme" parent="android:style/Theme.Material.Light.NoActionBar" />
        </resources>
        """, at: directory)
        try write("app/src/main/java/\(packagePath)/MainActivity.kt", """
        package \(packageName)

        import android.app.Activity
        import android.os.Bundle
        import android.widget.TextView

        class MainActivity : Activity() {
            override fun onCreate(savedInstanceState: Bundle?) {
                super.onCreate(savedInstanceState)
                setContentView(TextView(this).apply { text = "Hello, \(name)" })
            }
        }
        """, at: directory)
    }

    private func generateHarmony(name: String, at directory: URL) throws {
        try write("build-profile.json5", """
        {
          app: {
            products: [{ name: "default", signingConfig: "default" }]
          },
          modules: [{ name: "entry", srcPath: "./entry" }]
        }
        """, at: directory)
        try write("AppScope/app.json5", """
        {
          app: {
            bundleName: "com.example.\(sanitizedIdentifier(name).lowercased())",
            vendor: "example",
            versionCode: 1000000,
            versionName: "1.0.0"
          }
        }
        """, at: directory)
        try write("entry/src/main/module.json5", """
        {
          module: {
            name: "entry",
            type: "entry",
            srcEntry: "./ets/Application/AbilityStage.ets",
            abilities: [{
              name: "EntryAbility",
              srcEntry: "./ets/entryability/EntryAbility.ets",
              exported: true,
              startWindowIcon: "$media:app_icon",
              startWindowBackground: "$color:start_window_background"
            }]
          }
        }
        """, at: directory)
        try write("entry/src/main/ets/pages/Index.ets", """
        @Entry
        @Component
        struct Index {
          build() {
            Row() {
              Text('Hello, \(name)')
                .fontSize(24)
            }
            .height('100%')
            .width('100%')
            .justifyContent(FlexAlign.Center)
          }
        }
        """, at: directory)
        try write("entry/src/main/ets/Application/AbilityStage.ets", """
        export default class AbilityStage {}
        """, at: directory)
        try write("entry/src/main/ets/entryability/EntryAbility.ets", """
        export default class EntryAbility {}
        """, at: directory)
    }

    private func generateOther(name: String, at directory: URL) throws {
        try write("README.md", """
        # \(name)

        Generic project created by ProjectPlanner.
        """, at: directory)
        try write(".vscode/settings.json", """
        {
          "files.trimTrailingWhitespace": true,
          "files.insertFinalNewline": true
        }
        """, at: directory)
    }

    private func writeAgents(projectType: String, at directory: URL) throws {
        try write("AGENTS.md", """
        # AGENTS.md

        Project type: \(projectType)

        ## Collaboration Rules

        - Keep changes minimal and focused.
        - Check existing project structure before adding new patterns.
        - Run the relevant build or test command before reporting completion.
        - Do not overwrite user changes without explicit approval.

        ## Commands

        - Build: fill in after the first successful local build.
        - Test: fill in after tests are added.
        """, at: directory)
    }

    private func write(_ relativePath: String, _ content: String, at root: URL) throws {
        let fileURL = root.appendingPathComponent(relativePath)
        try fileManager.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    private func sanitizedIdentifier(_ value: String) -> String {
        let scalars = value.unicodeScalars.map { CharacterSet.alphanumerics.contains($0) ? Character($0) : Character("_") }
        let joined = String(scalars)
        let prefixed = joined.first?.isNumber == true ? "_\(joined)" : joined
        return prefixed.isEmpty ? "ClientApp" : prefixed
    }

    private func iosPBXProj(module: String) -> String {
        """
        // !$*UTF8*$!
        {
          archiveVersion = 1;
          classes = {};
          objectVersion = 56;
          objects = {};
          rootObject = 000000000000000000000000;
        }
        """
    }
}

extension TemplateService: TemplateGenerating {}
