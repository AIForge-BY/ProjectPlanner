import Foundation

enum ProjectSortField: String, CaseIterable, Identifiable {
    case time
    case name

    var id: String { rawValue }

    var title: String {
        switch self {
        case .time:
            return "时间"
        case .name:
            return "名称"
        }
    }
}

enum ProjectSortDirection: String, CaseIterable, Identifiable {
    case ascending
    case descending

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ascending:
            return "升序"
        case .descending:
            return "降序"
        }
    }

    var systemImage: String {
        switch self {
        case .ascending:
            return "arrow.up"
        case .descending:
            return "arrow.down"
        }
    }

    mutating func toggle() {
        self = self == .ascending ? .descending : .ascending
    }
}

struct ProjectGroupSection: Identifiable, Equatable {
    var id: String { name }
    let name: String
    let projects: [PlannedProject]
}

struct ProjectSorter {
    static func groupedProjects(
        _ projects: [PlannedProject],
        status: ProjectStatus,
        sortField: ProjectSortField,
        direction: ProjectSortDirection
    ) -> [ProjectGroupSection] {
        let filtered = projects.filter { $0.status == status }
        let groups = Dictionary(grouping: filtered) { project in
            displayGroupName(for: project)
        }
        return groups
            .map { name, projects in
                ProjectGroupSection(
                    name: name,
                    projects: projects.sorted {
                        compare($0, $1, status: status, sortField: sortField, direction: direction)
                    }
                )
            }
            .sorted { compareGroupName($0.name, $1.name) }
    }

    static func time(for project: PlannedProject, status: ProjectStatus) -> Date {
        switch status {
        case .todo:
            return project.createdAt
        case .active:
            return project.startedAt ?? project.createdAt
        case .completed:
            return project.completedAt ?? project.updatedAt
        case .trash:
            return project.updatedAt
        }
    }

    static func displayName(for project: PlannedProject) -> String {
        project.alias ?? project.name
    }

    static func displayGroupName(for project: PlannedProject) -> String {
        let groupName = project.groupName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return groupName.isEmpty ? "未分组" : groupName
    }

    private static func compare(
        _ lhs: PlannedProject,
        _ rhs: PlannedProject,
        status: ProjectStatus,
        sortField: ProjectSortField,
        direction: ProjectSortDirection
    ) -> Bool {
        let primaryResult: ComparisonResult
        switch sortField {
        case .time:
            primaryResult = time(for: lhs, status: status).compare(time(for: rhs, status: status))
        case .name:
            primaryResult = displayName(for: lhs).localizedStandardCompare(displayName(for: rhs))
        }

        if primaryResult != .orderedSame {
            switch direction {
            case .ascending:
                return primaryResult == .orderedAscending
            case .descending:
                return primaryResult == .orderedDescending
            }
        }

        let nameResult = displayName(for: lhs).localizedStandardCompare(displayName(for: rhs))
        if nameResult != .orderedSame {
            return nameResult == .orderedAscending
        }

        return lhs.id.uuidString < rhs.id.uuidString
    }

    private static func compareGroupName(_ lhs: String, _ rhs: String) -> Bool {
        if lhs == "未分组" { return true }
        if rhs == "未分组" { return false }
        return lhs.localizedStandardCompare(rhs) == .orderedAscending
    }
}
