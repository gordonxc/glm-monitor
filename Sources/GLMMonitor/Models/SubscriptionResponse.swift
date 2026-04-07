import Foundation

struct SubscriptionResponse: Codable {
    let code: Int
    let data: [Subscription]?
    let success: Bool
}

struct Subscription: Codable {
    let productName: String
    let status: String
    let nextRenewTime: String?
    let billingCycle: String?
    let inCurrentPeriod: Bool?
}
