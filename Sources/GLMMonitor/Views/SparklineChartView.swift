import SwiftUI

struct SparklineChartView: View {
    let snapshots: [UsageSnapshot]
    let keyPath: KeyPath<UsageSnapshot, Int>
    let title: String

    private func color(for percentage: Int) -> Color {
        if percentage > 90 { return .red }
        if percentage > 70 { return .orange }
        return .green
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)

            if snapshots.count < 2 {
                Text("Waiting for data...")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary.opacity(0.5))
                    .frame(height: 36)
            } else {
                GeometryReader { geo in
                    ZStack {
                        // Grid lines at 50% and 80%
                        Path { path in
                            let y50 = geo.size.height * 0.5
                            let y80 = geo.size.height * 0.2
                            path.move(to: CGPoint(x: 0, y: y50))
                            path.addLine(to: CGPoint(x: geo.size.width, y: y50))
                            path.move(to: CGPoint(x: 0, y: y80))
                            path.addLine(to: CGPoint(x: geo.size.width, y: y80))
                        }
                        .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)

                        // Filled area under curve
                        Path { path in
                            let values = snapshots.map { $0[keyPath: keyPath] }
                            let stepX = geo.size.width / CGFloat(max(values.count - 1, 1))
                            let height = geo.size.height

                            path.move(to: CGPoint(x: 0, y: height))
                            for (i, val) in values.enumerated() {
                                let x = CGFloat(i) * stepX
                                let y = height - (CGFloat(val) / 100.0 * height)
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                            path.addLine(to: CGPoint(x: CGFloat(values.count - 1) * stepX, y: height))
                            path.closeSubpath()
                        }
                        .fill(
                            LinearGradient(
                                colors: [
                                    color(for: snapshots.last?[keyPath: keyPath] ?? 0).opacity(0.15),
                                    color(for: snapshots.last?[keyPath: keyPath] ?? 0).opacity(0.02)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                        // Line
                        Path { path in
                            let values = snapshots.map { $0[keyPath: keyPath] }
                            let stepX = geo.size.width / CGFloat(max(values.count - 1, 1))
                            let height = geo.size.height

                            for (i, val) in values.enumerated() {
                                let x = CGFloat(i) * stepX
                                let y = height - (CGFloat(val) / 100.0 * height)
                                if i == 0 {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                        }
                        .stroke(
                            color(for: snapshots.last?[keyPath: keyPath] ?? 0),
                            style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
                        )
                    }
                }
                .frame(height: 36)
            }
        }
    }
}
