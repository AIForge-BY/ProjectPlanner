import SwiftUI

enum AppBrand {
    static let name = "星联"
    static let shortName = "星联"
}

@main
struct ProjectPlannerApp: App {
    @NSApplicationDelegateAdaptor(ProjectPlannerAppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
final class ProjectPlannerAppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private let appState = AppState()
    private var statusItem: NSStatusItem?
    private var managementWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.applicationIconImage = NSImage(named: "AppIcon")
        createMainMenu()
        createStatusItem()
        showManagementWindow()
        Task {
            await appState.load()
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showManagementWindow()
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow, window === managementWindow else {
            return
        }
        managementWindow = nil
    }

    private func createStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.title = ""
        item.button?.image = NSImage(systemSymbolName: "point.3.connected.trianglepath.dotted", accessibilityDescription: AppBrand.name)
        item.button?.imagePosition = .imageOnly
        item.button?.toolTip = AppBrand.name
        item.button?.target = self
        item.button?.action = #selector(openStatusMenu)
        statusItem = item
    }

    private func makeStatusMenu() -> NSMenu {
        let menu = NSMenu()
        let title = NSMenuItem(title: AppBrand.name, action: nil, keyEquivalent: "")
        title.isEnabled = false
        menu.addItem(title)
        let activeCount = appState.projects(with: .active).count
        let summary = NSMenuItem(title: "\(activeCount) 个执行中项目", action: nil, keyEquivalent: "")
        summary.isEnabled = false
        menu.addItem(summary)
        for project in appState.projects(with: .active) {
            let item = NSMenuItem(title: project.alias ?? project.name, action: nil, keyEquivalent: "")
            let submenu = NSMenu(title: item.title)
            submenu.addItem(projectMenuItem(title: "打开文件夹", action: #selector(openProjectFolderFromMenu), project: project))
            submenu.addItem(projectMenuItem(title: "打开 IDE", action: #selector(openProjectIDEFromMenu), project: project))
            submenu.addItem(projectMenuItem(title: "打开终端", action: #selector(openProjectTerminalFromMenu), project: project))
            submenu.addItem(.separator())
            submenu.addItem(projectMenuItem(title: "标记完成", action: #selector(completeProjectFromMenu), project: project))
            item.submenu = submenu
            menu.addItem(item)
        }
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "打开项目管理", action: #selector(openManagementWindow), keyEquivalent: "o"))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "退出", action: #selector(quit), keyEquivalent: "q"))
        for item in menu.items {
            item.target = self
        }
        return menu
    }

    private func projectMenuItem(title: String, action: Selector, project: PlannedProject) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        item.representedObject = project.id.uuidString
        return item
    }

    @objc private func openManagementWindow() {
        showManagementWindow()
    }

    @objc private func openStatusMenu() {
        Task {
            await appState.load()
            guard let statusItem else { return }
            statusItem.menu = makeStatusMenu()
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
        }
    }

    @objc private func openProjectFolderFromMenu(_ sender: NSMenuItem) {
        guard let project = project(from: sender) else { return }
        Task { await appState.openFolder(project: project) }
    }

    @objc private func openProjectIDEFromMenu(_ sender: NSMenuItem) {
        guard let project = project(from: sender) else { return }
        Task { await appState.openIDE(project: project) }
    }

    @objc private func openProjectTerminalFromMenu(_ sender: NSMenuItem) {
        guard let project = project(from: sender) else { return }
        Task { await appState.openTerminal(project: project) }
    }

    @objc private func completeProjectFromMenu(_ sender: NSMenuItem) {
        guard let project = project(from: sender) else { return }
        Task {
            await appState.completeProject(id: project.id)
        }
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }

    private func createMainMenu() {
        let mainMenu = NSMenu(title: AppBrand.name)

        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu(title: AppBrand.name)
        appMenu.addItem(NSMenuItem(title: "关于 \(AppBrand.name)", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: ""))
        appMenu.addItem(.separator())
        let quitItem = NSMenuItem(title: "退出 \(AppBrand.name)", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        appMenu.addItem(quitItem)
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        let windowMenuItem = NSMenuItem()
        let windowMenu = NSMenu(title: "窗口")
        let openItem = NSMenuItem(title: "项目管理", action: #selector(openManagementWindow), keyEquivalent: "1")
        openItem.target = self
        windowMenu.addItem(openItem)
        windowMenuItem.submenu = windowMenu
        mainMenu.addItem(windowMenuItem)

        NSApplication.shared.mainMenu = mainMenu
    }

    private func showManagementWindow() {
        if managementWindow == nil {
            let rootView = ManageProjectsView()
                .environmentObject(appState)
                .frame(minWidth: 980, minHeight: 620)
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 1040, height: 680),
                styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            window.title = AppBrand.name
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.isMovableByWindowBackground = false
            window.delegate = self
            window.contentView = NSHostingView(rootView: rootView)
            window.center()
            window.setFrameAutosaveName("ProjectPlannerManagementWindow")
            managementWindow = window
        }
        managementWindow?.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    private func project(from item: NSMenuItem) -> PlannedProject? {
        guard let rawID = item.representedObject as? String, let id = UUID(uuidString: rawID) else {
            return nil
        }
        return appState.document.projects.first { $0.id == id }
    }
}
