import SwiftUI

struct UsageSectionView: View {
    let title: String
    let subtitle: String?
    let percentage: Int
    let resetTime: Date?

    init(title: String, subtitle: String? = nil, percentage: Int, resetTime: Date? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.percentage = percentage
        self.resetTime = resetTime
    }

    var barColor: Color {
        if percentage > 90 { return .red }
        if percentage > 70 { return .orange }
        return .green
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Text("\(percentage)%")
                    .font(.headline)
                    .foregroundColor(barColor)
            }

            ProgressView(value: Double(percentage), total: 100)
                .progressViewStyle(BarProgressStyle(color: barColor))
                .frame(height: 8)

            HStack {
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if let reset = resetTime {
                    HStack(spacing: 2) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.caption2)
                        Text(formatResetTime(reset))
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
    }

    private func formatResetTime(_ date: Date) -> String {
        let interval = date.timeIntervalSinceNow
        if interval <= 0 { return "now" }
        let hours = Int(interval) / 3600
        let minutes = Int(interval) % 3600 / 60
        if hours >= 24 {
            let days = hours / 24
            let remainHours = hours % 24
            return "\(days)d \(remainHours)h"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct BarProgressStyle: ProgressViewStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        let fraction = configuration.fractionCompleted ?? 0

        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
                    .frame(width: geo.size.width * CGFloat(fraction))
            }
        }
    }
}
