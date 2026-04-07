import Foundation

struct QuotaLimitResponse: Codable {
    let code: Int
    let data: QuotaLimitData?
    let success: Bool
}

struct QuotaLimitData: Codable {
    let limits: [QuotaLimit]?
    let level: String?
}

struct QuotaLimit: Codable {
    let type: String
    let unit: Int
    let number: Int
    let usage: Int64?
    let currentValue: Int64?
    let remaining: Int64?
    let percentage: Int
    let nextResetTime: Int64?
    let usageDetails: [UsageDetail]?
}

struct UsageDetail: Codable {
    let modelCode: String
    let usage: Int
}
