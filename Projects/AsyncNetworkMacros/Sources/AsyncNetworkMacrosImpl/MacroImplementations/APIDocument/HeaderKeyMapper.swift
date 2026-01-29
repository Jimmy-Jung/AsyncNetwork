enum HeaderKeyMapper {
    static func map(_ key: String) -> String {
        switch key.lowercased() {
        case "authorization":
            return "Authorization"
        case "contenttype", "content":
            return "Content-Type"
        case "useragent", "agent":
            return "User-Agent"
        case "accept":
            return "Accept"
        case "acceptlanguage", "language":
            return "Accept-Language"
        case "cookie":
            return "Cookie"
        case "setcookie":
            return "Set-Cookie"
        case "cachecontrol", "cache":
            return "Cache-Control"
        default:
            return key
                .split(separator: " ")
                .map { $0.capitalized }
                .joined(separator: "-")
        }
    }
}
