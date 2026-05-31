import Foundation
import Observation

struct SessionRecord: Codable, Identifiable {
    let id: UUID
    let date: Date
    let focusMinutes: Int

    init(focusMinutes: Int) {
        id = UUID()
        date = Date()
        self.focusMinutes = focusMinutes
    }
}

@MainActor
@Observable
final class SessionStore {
    private(set) var records: [SessionRecord] = []

    init() { load() }

    func logFocusSession(minutes: Int) {
        records.append(SessionRecord(focusMinutes: minutes))
        save()
    }

    // MARK: - Aggregations

    func dailyMinutes(weeks: Int) -> [Date: Int] {
        let calendar = Calendar.current
        let cutoff = calendar.date(byAdding: .weekOfYear, value: -weeks, to: Date()) ?? Date()
        return Dictionary(
            grouping: records.filter { $0.date >= cutoff },
            by: { calendar.startOfDay(for: $0.date) }
        ).mapValues { $0.reduce(0) { $0 + $1.focusMinutes } }
    }

    var todayMinutes: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return records
            .filter { calendar.startOfDay(for: $0.date) == today }
            .reduce(0) { $0 + $1.focusMinutes }
    }

    var weekMinutes: Int {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        let weekStart = calendar.date(from: comps) ?? Date()
        return records
            .filter { $0.date >= weekStart }
            .reduce(0) { $0 + $1.focusMinutes }
    }

    // MARK: - Persistence

    private func save() {
        guard let data = try? JSONEncoder().encode(records) else { return }
        UserDefaults.standard.set(data, forKey: "sessionRecords")
    }

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: "sessionRecords"),
            let decoded = try? JSONDecoder().decode([SessionRecord].self, from: data)
        else { return }
        records = decoded
    }
}
