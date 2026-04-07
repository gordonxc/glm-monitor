import Foundation
import SwiftUI
import ServiceManagement
import os

private let logger = Logger(subsystem: "com.glm.monitor", category: "main")

enum StatusBarMode: String, CaseIterable {
    case number = "number"
    case pie = "pie"

    var label: String {
        switch self {
        case .number: return "Number"
        case .pie: return "Pie Chart"
        }
    }
}

enum RefreshInterval: Int, CaseIterable {
    case oneMinute = 60
    case fiveMinutes = 300
    case tenMinutes = 600
    case thirtyMinutes = 1800

    var label: String {
        switch self {
        case .oneMinute: return "1m"
        case .fiveMinutes: return "5m"
        case .tenMinutes: return "10m"
        case .thirtyMinutes: return "30m"
        }
    }
}

@MainActor
class MonitorViewModel: ObservableObject {
    @Published var planName: String = ""
    @Published var sessionLimit: TokenLimit?
    @Published var weeklyLimit: TokenLimit?
    @Published var searchLimit: SearchLimit?
    @Published var nextRenewal: Date?
    @Published var lastUpdated: Date?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var launchAtLogin: Bool = false
    @Published var statusBarMode: StatusBarMode {
        didSet { UserDefaults.standard.set(statusBarMode.rawValue, forKey: "statusBarMode") }
    }
    @Published var refreshInterval: RefreshInterval {
        didSet {
            UserDefaults.standard.set(refreshInterval.rawValue, forKey: "refreshInterval")
            restartTimer()
        }
    }
    @Published var isDarkMode: Bool = false
    @Published var usageSnapshots: [UsageSnapshot] = []

    private let usageHistory = UsageHistory()

    var checkForUpdates: (() -> Void)?

    private var client: ZAIClient?
    private var refreshTimer: Timer?
    private var appearanceObservation: NSKeyValueObservation?
    private var previousSessionPercentage: Int?
    private var previousDailyPercentage: Int?

    private let logFile = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".glm-monitor/debug.log")

    private func debugLog(_ msg: String) {
        logger.info("GLMMonitor: \(msg)")
        let ts = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let line = "[\(ts)] \(msg)\n"
        if let data = line.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: logFile.path) {
                if let handle = try? FileHandle(forWritingTo: logFile) {
                    handle.seekToEndOfFile()
                    handle.write(data)
                    handle.closeFile()
                }
            } else {
                try? data.write(to: logFile)
            }
        }
    }

    struct TokenLimit {
        let percentage: Int
        let resetTime: Date?
        let periodDescription: String
    }

    struct SearchLimit {
        let current: Int
        let total: Int
        let percentage: Int
        let usageDetails: [UsageDetail]
        let resetTime: Date?
    }

    func initialize() {
        // Check current launch-at-login state
        launchAtLogin = SMAppService.mainApp.status == .enabled

        // Detect dark mode
        updateDarkMode()
        appearanceObservation = NSApp.observe(\.effectiveAppearance, options: [.new]) { [weak self] _, _ in
            Task { @MainActor in
                self?.updateDarkMode()
            }
        }

        let apiKey = APIKeyProvider.resolve()
        debugLog("initialize - apiKey: \(apiKey != nil ? "found (\(apiKey!.prefix(10))...)" : "nil")")
        guard let apiKey else {
            errorMessage = "No API key found. Set ANTHROPIC_AUTH_TOKEN or ZAI_API_KEY."
            debugLog("ERROR: \(errorMessage!)")
            return
        }
        client = ZAIClient(apiKey: apiKey)
        Task { await refresh() }
        restartTimer()
    }

    init() {
        let saved = UserDefaults.standard.string(forKey: "statusBarMode") ?? "number"
        _statusBarMode = Published(initialValue: StatusBarMode(rawValue: saved) ?? .number)

        let savedInterval = UserDefaults.standard.integer(forKey: "refreshInterval")
        _refreshInterval = Published(initialValue: RefreshInterval(rawValue: savedInterval) ?? .fiveMinutes)

        DispatchQueue.main.async { [weak self] in
            self?.initialize()
        }
    }

    func refresh() async {
        guard let client else {
            debugLog("refresh - no client")
            return
        }
        isLoading = true
        errorMessage = nil
        debugLog("refresh - fetching quota...")

        do {
            let quotaResp = try await client.fetchQuotaLimits()
            debugLog("quota response - code: \(quotaResp.code), success: \(quotaResp.success), limits: \(quotaResp.data?.limits?.count ?? -1)")

            // Try subscription separately (may fail with 401)
            if let subResp = try? await client.fetchSubscription(),
               let sub = subResp.data?.first(where: { $0.inCurrentPeriod == true }) ?? subResp.data?.first {
                planName = sub.productName
                if let renewStr = sub.nextRenewTime {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    formatter.timeZone = TimeZone(identifier: "UTC")
                    nextRenewal = formatter.date(from: renewStr)
                }
            }

            // Parse quota limits
            if let limits = quotaResp.data?.limits {
                // Use level from quota as fallback plan name
                if planName.isEmpty, let level = quotaResp.data?.level {
                    planName = level.prefix(1).uppercased() + level.dropFirst() + " Plan"
                }

                for limit in limits {
                    switch limit.type {
                    case "TOKENS_LIMIT":
                        let resetTime = limit.nextResetTime.map { Date(timeIntervalSince1970: TimeInterval($0 / 1000)) }
                        // unit 3 = hours (session), unit 6 = days (daily/weekly)
                        let periodDesc: String
                        if limit.unit == 3 {
                            periodDesc = "\(limit.number)h session"
                        } else if limit.unit == 6 {
                            periodDesc = limit.number == 1 ? "Daily" : "\(limit.number)d"
                        } else {
                            periodDesc = "Period"
                        }

                        let tokenLimit = TokenLimit(
                            percentage: limit.percentage,
                            resetTime: resetTime,
                            periodDescription: periodDesc
                        )
                        if limit.unit == 3 {
                            sessionLimit = tokenLimit
                        } else if limit.unit == 6 {
                            weeklyLimit = tokenLimit
                        }
                    case "TIME_LIMIT":
                        let resetTime = limit.nextResetTime.map { Date(timeIntervalSince1970: TimeInterval($0 / 1000)) }
                        searchLimit = SearchLimit(
                            current: Int(limit.currentValue ?? 0),
                            total: Int(limit.usage ?? 0),
                            percentage: limit.percentage,
                            usageDetails: limit.usageDetails ?? [],
                            resetTime: resetTime
                        )
                        if let reset = resetTime {
                            nextRenewal = reset
                        }
                    default:
                        break
                    }
                }
            }

            lastUpdated = Date()
            debugLog("refresh done - plan: \(planName), session: \(sessionLimit != nil), weekly: \(weeklyLimit != nil), search: \(searchLimit != nil)")

            // Check for usage alert notifications
            if let sessionPct = sessionLimit?.percentage {
                NotificationManager.shared.checkAndNotify(
                    metric: "session",
                    percentage: sessionPct,
                    previousPercentage: previousSessionPercentage
                )
                previousSessionPercentage = sessionPct
            }
            if let dailyPct = weeklyLimit?.percentage {
                NotificationManager.shared.checkAndNotify(
                    metric: "daily",
                    percentage: dailyPct,
                    previousPercentage: previousDailyPercentage
                )
                previousDailyPercentage = dailyPct
            }

            // Record history snapshot
            let snapshot = UsageSnapshot(
                timestamp: Date(),
                sessionPercentage: sessionLimit?.percentage ?? 0,
                dailyPercentage: weeklyLimit?.percentage ?? 0,
                searchPercentage: searchLimit?.percentage ?? 0
            )
            usageHistory.addSnapshot(snapshot)
            usageSnapshots = usageHistory.snapshots

        } catch {
            errorMessage = error.localizedDescription
            debugLog("ERROR: \(error.localizedDescription)")
        }

        isLoading = false
    }

    func toggleLaunchAtLogin() {
        do {
            if launchAtLogin {
                try SMAppService.mainApp.unregister()
                launchAtLogin = false
            } else {
                try SMAppService.mainApp.register()
                launchAtLogin = true
            }
        } catch {
            debugLog("Launch at login error: \(error.localizedDescription)")
        }
    }

    private func restartTimer() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(refreshInterval.rawValue), repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.refresh()
            }
        }
    }

    private func updateDarkMode() {
        let bestMatch = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua])
        isDarkMode = (bestMatch == .darkAqua)
    }

    deinit {
        refreshTimer?.invalidate()
        appearanceObservation?.invalidate()
    }
}
