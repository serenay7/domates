import SwiftUI

struct ActivityView: View {
    let store: SessionStore

    private static let tooltipFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()

    private var weekDays: [DayData] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let weekday = cal.component(.weekday, from: today) // 1=Sun…7=Sat
        let daysSinceMon = (weekday - 2 + 7) % 7
        let thisMon = cal.date(byAdding: .day, value: -daysSinceMon, to: today)!
        let data = store.dailyMinutes(weeks: 1)

        return (0..<7).map { offset in
            let day = cal.date(byAdding: .day, value: offset, to: thisMon)!
            return DayData(
                date: day,
                minutes: day <= today ? (data[day] ?? 0) : 0,
                isToday: day == today,
                isFuture: day > today
            )
        }
    }

    private var maxMinutes: Int { max(weekDays.map(\.minutes).max() ?? 0, 1) }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("This Week")
                .font(.headline)

            weekChart

            Divider()

            statsRow
        }
        .padding(24)
    }

    // MARK: - Bar chart

    private var weekChart: some View {
        HStack(alignment: .bottom, spacing: 6) {
            ForEach(weekDays) { day in
                DayColumn(day: day, maxMinutes: maxMinutes)
            }
        }
        .frame(maxWidth: .infinity)
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

// MARK: - Data model

private struct DayData: Identifiable {
    let id = UUID()
    let date: Date
    let minutes: Int
    let isToday: Bool
    let isFuture: Bool

    // M T W T F S S
    static let letters = ["S","M","T","W","T","F","S"]
    var letter: String {
        let wd = Calendar.current.component(.weekday, from: date) // 1=Sun
        return Self.letters[wd - 1]
    }

    var tooltip: String {
        let d = DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none)
        return minutes == 0 ? "\(d): no sessions" : "\(d): \(minutes) min"
    }
}

// MARK: - Single day column

private struct DayColumn: View {
    let day: DayData
    let maxMinutes: Int

    private let maxBarHeight: CGFloat = 72

    private var barHeight: CGFloat {
        guard day.minutes > 0 else { return 0 }
        return max(CGFloat(day.minutes) / CGFloat(maxMinutes) * maxBarHeight, 5)
    }

    private var barColor: Color {
        day.isToday ? .red : .red.opacity(0.45)
    }

    var body: some View {
        VStack(spacing: 4) {
            // bar track + fill
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.secondary.opacity(0.1))
                    .frame(height: maxBarHeight)

                if barHeight > 0 {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor)
                        .frame(height: barHeight)
                        .animation(.spring(duration: 0.4), value: barHeight)
                }
            }

            // minutes (only when > 0)
            Text(day.minutes > 0 ? fmtMin(day.minutes) : "")
                .font(.system(size: 8))
                .foregroundStyle(.tertiary)
                .frame(height: 10)

            // day letter
            Text(day.letter)
                .font(.system(size: 11, weight: day.isToday ? .bold : .regular))
                .foregroundStyle(day.isFuture ? Color.secondary.opacity(0.35) : (day.isToday ? .primary : .secondary))
        }
        .frame(maxWidth: .infinity)
        .help(day.tooltip)
    }

    private func fmtMin(_ m: Int) -> String {
        m < 60 ? "\(m)m" : "\(m/60)h\(m%60 > 0 ? "\(m%60)m" : "")"
    }
}

// MARK: - Stat box

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
