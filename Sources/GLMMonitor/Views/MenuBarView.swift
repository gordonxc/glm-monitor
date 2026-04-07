import SwiftUI

struct MenuBarView: View {
    @ObservedObject var viewModel: MonitorViewModel
    @State private var trendRange: TrendRange = .day

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("GLM Monitor")
                    .font(.headline)
                Spacer()
                if !viewModel.planName.isEmpty {
                    Text(viewModel.planName)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.15))
                        .cornerRadius(4)
                }
                Button(action: {
                    Task { await viewModel.refresh() }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .rotationEffect(.degrees(viewModel.isLoading ? 360 : 0))
                        .animation(viewModel.isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: viewModel.isLoading)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isLoading)
            }
            .padding(.bottom, 8)

            Divider()

            // Error banner
            if let error = viewModel.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                .padding(.vertical, 6)
                Divider()
            }

            // Session tokens
            if let session = viewModel.sessionLimit {
                UsageSectionView(
                    title: "Session",
                    subtitle: session.periodDescription,
                    percentage: session.percentage,
                    resetTime: session.resetTime
                )
                .padding(.vertical, 8)
                Divider()
            }

            // Weekly/Daily tokens
            if let weekly = viewModel.weeklyLimit {
                UsageSectionView(
                    title: weekly.periodDescription,
                    percentage: weekly.percentage,
                    resetTime: weekly.resetTime
                )
                .padding(.vertical, 8)
                Divider()
            }

            // Web searches
            if let search = viewModel.searchLimit {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Web Searches")
                            .font(.headline)
                        Spacer()
                        Text("\(search.current)/\(search.total)")
                            .font(.headline)
                            .foregroundColor(search.percentage > 90 ? .red : search.percentage > 70 ? .orange : .primary)
                    }

                    ForEach(search.usageDetails, id: \.modelCode) { detail in
                        HStack {
                            Text("  \(detail.modelCode)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(detail.usage)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    HStack {
                        if let renewal = viewModel.nextRenewal {
                            HStack(spacing: 2) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.caption2)
                                Text("resets \(renewal, style: .date)")
                                    .font(.caption2)
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.vertical, 8)
                Divider()
            }

            // Usage trend
            if viewModel.usageSnapshots.count >= 2 {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Usage Trend")
                            .font(.headline)
                        Spacer()
                        Picker("", selection: $trendRange) {
                            ForEach(TrendRange.allCases, id: \.self) { range in
                                Text(range.label).tag(range)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 100)
                    }

                    let filtered = trendRange == .day
                        ? viewModel.usageSnapshots.filter { $0.timestamp >= Date().addingTimeInterval(-24 * 60 * 60) }
                        : viewModel.usageSnapshots

                    HStack(spacing: 12) {
                        SparklineChartView(
                            snapshots: filtered,
                            keyPath: \UsageSnapshot.sessionPercentage,
                            title: "Session"
                        )
                        SparklineChartView(
                            snapshots: filtered,
                            keyPath: \UsageSnapshot.dailyPercentage,
                            title: "Daily"
                        )
                    }
                }
                .padding(.vertical, 8)
                Divider()
            }

            // Footer
            VStack(spacing: 6) {
                HStack {
                    Text("Status Bar Style")
                        .font(.caption)
                    Spacer()
                    Picker("", selection: $viewModel.statusBarMode) {
                        ForEach(StatusBarMode.allCases, id: \.self) { mode in
                            Text(mode.label).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 160)
                }

                HStack {
                    Text("Refresh Interval")
                        .font(.caption)
                    Spacer()
                    Picker("", selection: $viewModel.refreshInterval) {
                        ForEach(RefreshInterval.allCases, id: \.self) { interval in
                            Text(interval.label).tag(interval)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 160)
                }

                HStack {
                    Text("Launch at Login")
                        .font(.caption)
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { viewModel.launchAtLogin },
                        set: { _ in viewModel.toggleLaunchAtLogin() }
                    ))
                    .toggleStyle(.switch)
                    .scaleEffect(0.7)
                }

                HStack {
                    if let updated = viewModel.lastUpdated {
                        Text("Updated \(updated, style: .time)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button("Check for Updates") {
                        viewModel.checkForUpdates?()
                    }
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    Button("Restart") {
                        restartApp()
                    }
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    Button("Quit") {
                        NSApplication.shared.terminate(nil)
                    }
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            .padding(.top, 6)
        }
        .padding(12)
        .frame(width: 320)
    }
}

private func restartApp() {
    guard let bundleURL = Bundle.main.bundleURL.absoluteString.removingPercentEncoding,
          let url = URL(string: bundleURL) else { return }
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
    task.arguments = [url.path]
    try? task.run()
    NSApplication.shared.terminate(nil)
}

enum TrendRange: String, CaseIterable {
    case day = "24h"
    case week = "7d"

    var label: String {
        switch self {
        case .day: return "24h"
        case .week: return "7d"
        }
    }
}
