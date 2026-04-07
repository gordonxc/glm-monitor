import Foundation

actor ZAIClient {
    private let baseURL = "https://api.z.ai"
    private let apiKey: String

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func fetchSubscription() async throws -> SubscriptionResponse {
        let url = URL(string: "\(baseURL)/api/biz/subscription/list")!
        return try await request(url)
    }

    func fetchQuotaLimits() async throws -> QuotaLimitResponse {
        let url = URL(string: "\(baseURL)/api/monitor/usage/quota/limit")!
        return try await request(url)
    }

    private func request<T: Decodable>(_ url: URL) async throws -> T {
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw ZAIError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            throw ZAIError.httpError(http.statusCode)
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw ZAIError.decodingError(error)
        }
    }
}

enum ZAIError: LocalizedError {
    case invalidResponse
    case httpError(Int)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: "Invalid response from server"
        case .httpError(let code): "HTTP error \(code)"
        case .decodingError(let error): "Failed to parse response: \(error.localizedDescription)"
        }
    }
}
