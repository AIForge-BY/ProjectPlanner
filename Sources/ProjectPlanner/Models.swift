import Foundation

enum ProjectType: String, Codable, CaseIterable, Identifiable {
    case android
    case ios
    case harmony
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .android:
            return "Android"
        case .ios:
            return "iOS"
        case .harmony:
            return "HarmonyOS"
        case .other:
            return "Other"
        }
    }
}

enum ProjectStatus: String, Codable, CaseIterable, Identifiable {
    case todo
    case active
    case completed
    case trash

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .todo:
            return "待办项目"
        case .active:
            return "执行中"
        case .completed:
            return "完成"
        case .trash:
            return "回收站"
        }
    }
}

enum RemotePlatform: String, Codable, CaseIterable, Identifiable {
    case github
    case gitee

    var id: String { rawValue }
}

enum RemoteMode: String, Codable, CaseIterable, Identifiable {
    case none
    case createNew
    case bindExisting

    var id: String { rawValue }
}

enum RemoteSetupState: String, Codable, Equatable {
    case none
    case pending
    case bound
    case pushed
    case needsManualSync
    case failed
}

struct RemoteInfo: Codable, Equatable {
    var platform: RemotePlatform?
    var url: String?
    var mode: RemoteMode
    var setupState: RemoteSetupState
    var lastError: String?

    static let none = RemoteInfo(
        platform: nil,
        url: nil,
        mode: .none,
        setupState: .none,
        lastError: nil
    )
}

enum IDEOverride: Codable, Equatable {
    case applicationPath(String)
    case command(String)
}

struct TemplateInfo: Codable, Equatable {
    var id: String
    var version: Int
}

struct ProjectGroup: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var createdAt: Date

    init(id: UUID = UUID(), name: String, createdAt: Date) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
    }
}

struct PlannedProject: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var alias: String?
    var path: String
    var type: ProjectType
    var customType: String?
    var groupName: String?
    var sortOrder: Double?
    var isCollapsed: Bool?
    var status: ProjectStatus
    var statusBeforeTrash: ProjectStatus?
    var createdAt: Date
    var updatedAt: Date
    var completedAt: Date?
    var remote: RemoteInfo
    var ideOverride: IDEOverride?
    var template: TemplateInfo?

    static func templateProject(
        id: UUID = UUID(),
        name: String,
        path: String,
        type: ProjectType,
        templateID: String,
        templateVersion: Int,
        now: Date
    ) -> PlannedProject {
        PlannedProject(
            id: id,
            name: name,
            alias: nil,
            path: path,
            type: type,
            customType: nil,
            groupName: nil,
            sortOrder: now.timeIntervalSince1970,
            isCollapsed: true,
            status: .active,
            statusBeforeTrash: nil,
            createdAt: now,
            updatedAt: now,
            completedAt: nil,
            remote: .none,
            ideOverride: nil,
            template: TemplateInfo(id: templateID, version: templateVersion)
        )
    }

    static func existingProject(
        id: UUID = UUID(),
        name: String,
        path: String,
        type: ProjectType,
        now: Date
    ) -> PlannedProject {
        PlannedProject(
            id: id,
            name: name,
            alias: nil,
            path: path,
            type: type,
            customType: nil,
            groupName: nil,
            sortOrder: now.timeIntervalSince1970,
            isCollapsed: false,
            status: .todo,
            statusBeforeTrash: nil,
            createdAt: now,
            updatedAt: now,
            completedAt: nil,
            remote: .none,
            ideOverride: nil,
            template: nil
        )
    }

    var typeLabel: String {
        if type == .other, let customType, !customType.isEmpty {
            return customType
        }
        return type.displayName
    }
}

struct ProjectDocument: Codable, Equatable {
    var schemaVersion: Int
    var projects: [PlannedProject]
    var groups: [ProjectGroup]?

    init(schemaVersion: Int = 1, projects: [PlannedProject] = [], groups: [ProjectGroup] = []) {
        self.schemaVersion = schemaVersion
        self.projects = projects
        self.groups = groups
    }
}

extension JSONEncoder {
    static var projectPlanner: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}

extension JSONDecoder {
    static var projectPlanner: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
