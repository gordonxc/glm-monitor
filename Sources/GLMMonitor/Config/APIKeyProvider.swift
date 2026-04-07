import Foundation

enum APIKeyProvider {
    static func resolve() -> String? {
        // 1. Environment variables (ANTHROPIC_AUTH_TOKEN is the primary source from Z.ai CLI)
        if let key = ProcessInfo.processInfo.environment["ANTHROPIC_AUTH_TOKEN"], !key.isEmpty {
            NSLog("[GLMMonitor] APIKey: found ANTHROPIC_AUTH_TOKEN in env")
            return key
        }
        if let key = ProcessInfo.processInfo.environment["ZAI_API_KEY"], !key.isEmpty {
            NSLog("[GLMMonitor] APIKey: found ZAI_API_KEY in env")
            return key
        }
        if let key = ProcessInfo.processInfo.environment["GLM_API_KEY"], !key.isEmpty {
            NSLog("[GLMMonitor] APIKey: found GLM_API_KEY in env")
            return key
        }

        NSLog("[GLMMonitor] APIKey: no env var, trying config file...")

        // 2. Config file at ~/.glm-monitor/config.json
        let configPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".glm-monitor/config.json")
        NSLog("[GLMMonitor] APIKey: config path = \(configPath.path)")
        if let data = try? Data(contentsOf: configPath) {
            NSLog("[GLMMonitor] APIKey: config file read OK, \(data.count) bytes")
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                NSLog("[GLMMonitor] APIKey: JSON keys = \(json.keys.joined(separator: ", "))")
                if let key = json["api_key"] as? String ?? json["apiKey"] as? String, !key.isEmpty {
                    NSLog("[GLMMonitor] APIKey: found key in config file")
                    return key
                }
            }
        } else {
            NSLog("[GLMMonitor] APIKey: cannot read config file")
        }

        // 3. Shell parsing of dotfiles
        let shellFiles = [".zshrc", ".bashrc", ".zprofile", ".bash_profile", ".zshenv"]
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        for file in shellFiles {
            let path = home + "/" + file
            guard let content = try? String(contentsOfFile: path) else { continue }
            for line in content.split(separator: "\n").map(String.init) {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.hasPrefix("export ") {
                    let rest = String(trimmed.dropFirst(7)).trimmingCharacters(in: .whitespaces)
                    if rest.hasPrefix("ANTHROPIC_AUTH_TOKEN=") || rest.hasPrefix("ZAI_API_KEY=") || rest.hasPrefix("GLM_API_KEY=") {
                        let value = rest.split(separator: "=", maxSplits: 1).last.map(String.init) ?? ""
                        let cleaned = value
                            .replacingOccurrences(of: "\"", with: "")
                            .replacingOccurrences(of: "'", with: "")
                            .trimmingCharacters(in: .whitespaces)
                        if !cleaned.isEmpty { return cleaned }
                    }
                }
            }
        }

        return nil
    }
}
