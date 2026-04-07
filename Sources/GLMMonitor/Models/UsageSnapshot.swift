import Foundation

struct UsageSnapshot: Codable {
    let timestamp: Date
    let sessionPercentage: Int
    let dailyPercentage: Int
    let searchPercentage: Int
}

class UsageHistory {
    private let fileURL: URL
    private static let maxAge: TimeInterval = 7 * 24 * 60 * 60 // 7 days

    var snapshots: [UsageSnapshot] = []

    init() {
        fileURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".glm-monitor/history.json")
        load()
    }

    func addSnapshot(_ snapshot: UsageSnapshot) {
        snapshots.append(snapshot)
        prune()
        save()
    }

    func snapshotsInLast24Hours() -> [UsageSnapshot] {
        let cutoff = Date().addingTimeInterval(-24 * 60 * 60)
        return snapshots.filter { $0.timestamp >= cutoff }
    }

    func snapshotsInLast7Days() -> [UsageSnapshot] {
        let cutoff = Date().addingTimeInterval(-7 * 24 * 60 * 60)
        return snapshots.filter { $0.timestamp >= cutoff }
    }

    private func prune() {
        let cutoff = Date().addingTimeInterval(-Self.maxAge)
        snapshots = snapshots.filter { $0.timestamp >= cutoff }
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        snapshots = (try? JSONDecoder().decode([UsageSnapshot].self, from: data)) ?? []
    }

    private func save() {
        let dir = fileURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        guard let data = try? JSONEncoder().encode(snapshots) else { return }
        try? data.write(to: fileURL)
    }
}
