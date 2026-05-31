import SwiftUI

struct ActivityView: View {
    let store: SessionStore

    private let weeksToShow = 16
    private let cellSize: CGFloat = 11
    private let cellGap: CGFloat = 2

    private static let monthFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM"
        return f
    }()

    private static let tooltipFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()

    // 16 columns (weeks), each column Mon[0]…Sun[6], nil = future
    private var weekColumns: [[Date?]] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let weekday = cal.component(.weekday, from: today)  // 1=Sun…7=Sat
        let daysSinceMon = (weekday - 2 + 7) % 7
        let thisMon = cal.date(byAdding: .day, value: -daysSinceMon, to: today)!
        let gridStart = cal.date(byAdding: .weekOfYear, value: -(weeksToShow - 1), to: thisMon)!

        return (0..<weeksToShow).map { w in
            let weekStart = cal.date(byAdding: .weekOfYear, value: w, to: gridStart)!
            return (0..<7).map { d in
                let day = cal.date(byAdding: .day, value: d, to: weekStart)!
                return day <= today ? day : nil
            }
        }
    }

    private var dailyData: [Date: Int] {
        store.dailyMinutes(weeks: weeksToShow + 1)
    }

    private var maxMinutes: Int {
        max(dailyData.values.max() ?? 0, 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Activity")
                .font(.headline)

            heatmapSection

            legendView

            Divider()

            statsRow
        }
        .padding(24)
    }

    // MARK: - Heatmap

    private var heatmapSection: some View {
        VStack(alignment: .leading, spacing: 3) {
            monthLabelRow

            HStack(alignment: .top, spacing: cellGap) {
                // Mon / Wed / Fri labels
                VStack(alignment: .trailing, spacing: cellGap) {
                    ForEach(["M", "", "W", "", "F", "", "S"], id: \.self) { lbl in
                        Text(lbl)
                            .font(.system(size: 8))
                            .foregroundStyle(.tertiary)
                            .frame(width: 8, height: cellSize)
                    }
                }

                ForEach(0..<weekColumns.count, id: \.self) { col in
                    VStack(spacing: cellGap) {
                        ForEach(0..<7, id: \.self) { row in
                            cell(for: weekColumns[col][row])
                        }
                    }
                }
            }
        }
    }

    private var monthLabelRow: some View {
        HStack(alignment: .top, spacing: cellGap) {
            Color.clear.frame(width: 8 + cellGap, height: 1) // align with day labels

            ForEach(0..<weekColumns.count, id: \.self) { col in
                let label = monthLabel(for: weekColumns[col])
                Text(label)
                    .font(.system(size: 8))
                    .foregroundStyle(Color.secondary.opacity(label.isEmpty ? 0 : 0.6))
                    .frame(width: cellSize, height: 10, alignment: .leading)
            }
        }
    }

    private func monthLabel(for week: [Date?]) -> String {
        guard let first = week.compactMap({ $0 }).first else { return "" }
        let day = Calendar.current.component(.day, from: first)
        // Show month name only on the week that contains the 1st–7th of the month
        return day <= 7 ? Self.monthFmt.string(from: first) : ""
    }

    @ViewBuilder
    private func cell(for date: Date?) -> some View {
        if let date {
            let minutes = dailyData[date] ?? 0
            let intensity = Double(minutes) / Double(maxMinutes)
            RoundedRectangle(cornerRadius: 2)
                .fill(cellColor(intensity: intensity, hasData: minutes > 0))
                .frame(width: cellSize, height: cellSize)
                .help(tooltip(date: date, minutes: minutes))
        } else {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.clear)
                .frame(width: cellSize, height: cellSize)
        }
    }

    private func cellColor(intensity: Double, hasData: Bool) -> Color {
        hasData ? Color.red.opacity(0.2 + intensity * 0.75) : Color.secondary.opacity(0.12)
    }

    private func tooltip(date: Date, minutes: Int) -> String {
        let d = Self.tooltipFmt.string(from: date)
        return minutes == 0 ? "\(d): no sessions" : "\(d): \(minutes) min"
    }

    // MARK: - Legend

    private var legendView: some View {
        HStack(spacing: 4) {
            Text("Less")
                .font(.system(size: 9))
                .foregroundStyle(.tertiary)
            ForEach([0.0, 0.25, 0.5, 0.75, 1.0], id: \.self) { v in
                RoundedRectangle(cornerRadius: 2)
                    .fill(cellColor(intensity: v, hasData: v > 0))
                    .frame(width: cellSize, height: cellSize)
            }
            Text("More")
                .font(.system(size: 9))
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Stats

    private var statsRow: some View {
        HStack {
            StatBox(label: "Today",     value: fmt(store.todayMinutes))
            Divider().frame(height: 28)
            StatBox(label: "This week", value: fmt(store.weekMinutes))
            Divider().frame(height: 28)
            StatBox(label: "All time",  value: "\(store.records.count) sessions")
        }
        .frame(maxWidth: .infinity)
    }

    private func fmt(_ minutes: Int) -> String {
        guard minutes > 0 else { return "—" }
        let h = minutes / 60, m = minutes % 60
        if h == 0 { return "\(m)m" }
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }
}

private struct StatBox: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.subheadline, design: .rounded).weight(.medium))
            Text(label)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }
}
