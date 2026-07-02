import Foundation

protocol ProjectStoring {
    func load() throws -> ProjectDocument
    func save(_ document: ProjectDocument) throws
}

struct ProjectStore {
    let fileURL: URL
    private let fileManager: FileManager

    init(fileURL: URL = ProjectStore.defaultFileURL(), fileManager: FileManager = .default) {
        self.fileURL = fileURL
        self.fileManager = fileManager
    }

    func load() throws -> ProjectDocument {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return ProjectDocument()
        }
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder.projectPlanner.decode(ProjectDocument.self, from: data)
    }

    func save(_ document: ProjectDocument) throws {
        let directory = fileURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let temporaryURL = directory.appendingPathComponent(".projects-\(UUID().uuidString).json.tmp")
        let data = try JSONEncoder.projectPlanner.encode(document)
        try data.write(to: temporaryURL, options: .atomic)
        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }
        try fileManager.moveItem(at: temporaryURL, to: fileURL)
    }

    static func defaultFileURL(
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
    ) -> URL {
        homeDirectory
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Application Support", isDirectory: true)
            .appendingPathComponent("ProjectPlanner", isDirectory: true)
            .appendingPathComponent("projects.json")
    }
}

extension ProjectStore: ProjectStoring {}
