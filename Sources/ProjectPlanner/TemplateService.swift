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
        let bundleName = "com.example.\(sanitizedIdentifier(name).lowercased())"
        let appName = jsonStringLiteral(name)
        let pageGreeting = arkTSStringLiteral("Hello, \(name)")
        let placeholderPNG = Self.placeholderPNGData

        try write("build-profile.json5", """
        {
          "app": {
            "signingConfigs": [],
            "products": [
              {
                "name": "default",
                "signingConfig": "default",
                "targetSdkVersion": "6.1.0(23)",
                "compatibleSdkVersion": "6.1.0(23)",
                "runtimeOS": "HarmonyOS",
                "buildOption": {
                  "strictMode": {
                    "caseSensitiveCheck": true,
                    "useNormalizedOHMUrl": true
                  }
                }
              }
            ],
            "buildModeSet": [
              {
                "name": "debug"
              },
              {
                "name": "release"
              }
            ]
          },
          "modules": [
            {
              "name": "entry",
              "srcPath": "./entry",
              "targets": [
                {
                  "name": "default",
                  "applyToProducts": [
                    "default"
                  ]
                }
              ]
            }
          ]
        }
        """, at: directory)
        try write("hvigorfile.ts", """
        import { appTasks } from '@ohos/hvigor-ohos-plugin';

        export default {
          system: appTasks,
          plugins: []
        }
        """, at: directory)
        try write("hvigor/hvigor-config.json5", """
        {
          "modelVersion": "6.1.0",
          "dependencies": {},
          "execution": {},
          "logging": {},
          "debugging": {},
          "nodeOptions": {}
        }
        """, at: directory)
        try write("oh-package.json5", """
        {
          "modelVersion": "6.1.0",
          "description": "HarmonyOS project created by ProjectPlanner.",
          "dependencies": {},
          "devDependencies": {
            "@ohos/hypium": "1.0.25",
            "@ohos/hamock": "1.0.0"
          }
        }
        """, at: directory)
        try write("code-linter.json5", """
        {
          "files": [
            "**/*.ets"
          ],
          "ignore": [
            "**/src/ohosTest/**/*",
            "**/src/test/**/*",
            "**/src/mock/**/*",
            "**/node_modules/**/*",
            "**/oh_modules/**/*",
            "**/build/**/*",
            "**/.preview/**/*"
          ],
          "ruleSet": [
            "plugin:@performance/recommended",
            "plugin:@typescript-eslint/recommended"
          ],
          "rules": {}
        }
        """, at: directory)
        try write("AppScope/app.json5", """
        {
          "app": {
            "bundleName": "\(bundleName)",
            "vendor": "example",
            "versionCode": 1000000,
            "versionName": "1.0.0",
            "buildVersion": "1",
            "icon": "$media:layered_image",
            "label": "$string:app_name"
          }
        }
        """, at: directory)
        try write("AppScope/resources/base/element/string.json", """
        {
          "string": [
            {
              "name": "app_name",
              "value": \(appName)
            }
          ]
        }
        """, at: directory)
        try write("AppScope/resources/base/media/layered_image.json", Self.layeredImageJSON, at: directory)
        try writeData("AppScope/resources/base/media/background.png", placeholderPNG, at: directory)
        try writeData("AppScope/resources/base/media/foreground.png", placeholderPNG, at: directory)
        try write("entry/build-profile.json5", """
        {
          "apiType": "stageMode",
          "buildOption": {
            "resOptions": {
              "copyCodeResource": {
                "enable": false
              }
            }
          },
          "buildOptionSet": [
            {
              "name": "release",
              "arkOptions": {
                "obfuscation": {
                  "ruleOptions": {
                    "enable": false,
                    "files": [
                      "./obfuscation-rules.txt"
                    ]
                  }
                }
              }
            }
          ],
          "targets": [
            {
              "name": "default"
            },
            {
              "name": "ohosTest"
            }
          ]
        }
        """, at: directory)
        try write("entry/hvigorfile.ts", """
        import { hapTasks } from '@ohos/hvigor-ohos-plugin';

        export default {
          system: hapTasks,
          plugins: []
        }
        """, at: directory)
        try write("entry/oh-package.json5", """
        {
          "name": "entry",
          "version": "1.0.0",
          "description": "HarmonyOS entry module.",
          "main": "",
          "author": "",
          "license": "",
          "dependencies": {}
        }
        """, at: directory)
        try write("entry/obfuscation-rules.txt", """
        # Define project specific obfuscation rules here.
        -enable-property-obfuscation
        -enable-toplevel-obfuscation
        -enable-filename-obfuscation
        -enable-export-obfuscation
        """, at: directory)
        try write("entry/src/main/module.json5", """
        {
          "module": {
            "name": "entry",
            "type": "entry",
            "description": "$string:module_desc",
            "mainElement": "EntryAbility",
            "deviceTypes": [
              "phone"
            ],
            "deliveryWithInstall": true,
            "installationFree": false,
            "pages": "$profile:main_pages",
            "abilities": [
              {
                "name": "EntryAbility",
                "srcEntry": "./ets/entryability/EntryAbility.ets",
                "description": "$string:EntryAbility_desc",
                "icon": "$media:layered_image",
                "label": "$string:EntryAbility_label",
                "startWindowIcon": "$media:startIcon",
                "startWindowBackground": "$color:start_window_background",
                "exported": true,
                "skills": [
                  {
                    "entities": [
                      "entity.system.home"
                    ],
                    "actions": [
                      "ohos.want.action.home"
                    ]
                  }
                ]
              }
            ],
            "extensionAbilities": [
              {
                "name": "EntryBackupAbility",
                "srcEntry": "./ets/entrybackupability/EntryBackupAbility.ets",
                "type": "backup",
                "exported": false,
                "metadata": [
                  {
                    "name": "ohos.extension.backup",
                    "resource": "$profile:backup_config"
                  }
                ]
              }
            ]
          }
        }
        """, at: directory)
        try write("entry/src/main/resources/base/profile/main_pages.json", """
        {
          "src": [
            "pages/Index"
          ]
        }
        """, at: directory)
        try write("entry/src/main/resources/base/profile/backup_config.json", """
        {
          "allowToBackupRestore": true
        }
        """, at: directory)
        try write("entry/src/main/resources/base/element/string.json", """
        {
          "string": [
            {
              "name": "module_desc",
              "value": "module description"
            },
            {
              "name": "EntryAbility_desc",
              "value": "description"
            },
            {
              "name": "EntryAbility_label",
              "value": \(appName)
            }
          ]
        }
        """, at: directory)
        try write("entry/src/main/resources/base/element/color.json", """
        {
          "color": [
            {
              "name": "start_window_background",
              "value": "#FFFFFF"
            }
          ]
        }
        """, at: directory)
        try write("entry/src/main/resources/base/element/float.json", """
        {
          "float": [
            {
              "name": "page_text_font_size",
              "value": "24fp"
            }
          ]
        }
        """, at: directory)
        try write("entry/src/main/resources/base/media/layered_image.json", Self.layeredImageJSON, at: directory)
        try writeData("entry/src/main/resources/base/media/background.png", placeholderPNG, at: directory)
        try writeData("entry/src/main/resources/base/media/foreground.png", placeholderPNG, at: directory)
        try writeData("entry/src/main/resources/base/media/startIcon.png", placeholderPNG, at: directory)
        try write("entry/src/main/ets/pages/Index.ets", """
        @Entry
        @Component
        struct Index {
          @State message: string = \(pageGreeting);

          build() {
            RelativeContainer() {
              Text(this.message)
                .id('HelloWorld')
                .fontSize($r('app.float.page_text_font_size'))
                .fontWeight(FontWeight.Bold)
                .alignRules({
                  center: { anchor: '__container__', align: VerticalAlign.Center },
                  middle: { anchor: '__container__', align: HorizontalAlign.Center }
                })
            }
            .height('100%')
            .width('100%')
          }
        }
        """, at: directory)
        try write("entry/src/main/ets/entryability/EntryAbility.ets", """
        import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
        import { hilog } from '@kit.PerformanceAnalysisKit';
        import { window } from '@kit.ArkUI';

        const DOMAIN = 0x0000;

        export default class EntryAbility extends UIAbility {
          onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
            try {
              this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
            } catch (err) {
              hilog.error(DOMAIN, 'ProjectPlanner', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
            }
            hilog.info(DOMAIN, 'ProjectPlanner', '%{public}s', 'Ability onCreate');
          }

          onDestroy(): void {
            hilog.info(DOMAIN, 'ProjectPlanner', '%{public}s', 'Ability onDestroy');
          }

          onWindowStageCreate(windowStage: window.WindowStage): void {
            windowStage.loadContent('pages/Index', (err) => {
              if (err.code) {
                hilog.error(DOMAIN, 'ProjectPlanner', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
                return;
              }
              hilog.info(DOMAIN, 'ProjectPlanner', 'Succeeded in loading the content.');
            });
          }

          onWindowStageDestroy(): void {
            hilog.info(DOMAIN, 'ProjectPlanner', '%{public}s', 'Ability onWindowStageDestroy');
          }

          onForeground(): void {
            hilog.info(DOMAIN, 'ProjectPlanner', '%{public}s', 'Ability onForeground');
          }

          onBackground(): void {
            hilog.info(DOMAIN, 'ProjectPlanner', '%{public}s', 'Ability onBackground');
          }
        }
        """, at: directory)
        try write("entry/src/main/ets/entrybackupability/EntryBackupAbility.ets", """
        import { hilog } from '@kit.PerformanceAnalysisKit';
        import { BackupExtensionAbility, BundleVersion } from '@kit.CoreFileKit';

        const DOMAIN = 0x0000;

        export default class EntryBackupAbility extends BackupExtensionAbility {
          async onBackup() {
            hilog.info(DOMAIN, 'ProjectPlanner', 'onBackup ok');
            await Promise.resolve();
          }

          async onRestore(bundleVersion: BundleVersion) {
            hilog.info(DOMAIN, 'ProjectPlanner', 'onRestore ok %{public}s', JSON.stringify(bundleVersion));
            await Promise.resolve();
          }
        }
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

    private func writeData(_ relativePath: String, _ data: Data, at root: URL) throws {
        let fileURL = root.appendingPathComponent(relativePath)
        try fileManager.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: fileURL, options: .atomic)
    }

    private func sanitizedIdentifier(_ value: String) -> String {
        let scalars = value.unicodeScalars.map { CharacterSet.alphanumerics.contains($0) ? Character($0) : Character("_") }
        let joined = String(scalars)
        let prefixed = joined.first?.isNumber == true ? "_\(joined)" : joined
        return prefixed.isEmpty ? "ClientApp" : prefixed
    }

    private func jsonStringLiteral(_ value: String) -> String {
        let data = try? JSONEncoder().encode(value)
        return data.flatMap { String(data: $0, encoding: .utf8) } ?? "\"\(value)\""
    }

    private func arkTSStringLiteral(_ value: String) -> String {
        let escaped = value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
        return "'\(escaped)'"
    }

    private static let layeredImageJSON = """
    {
      "layered-image": {
        "background": "$media:background",
        "foreground": "$media:foreground"
      }
    }
    """

    private static let placeholderPNGData = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII=")!

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
