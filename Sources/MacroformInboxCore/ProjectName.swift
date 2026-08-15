import Foundation

public struct ProjectName: Equatable, Sendable {
    public var yymmdd: String
    public var description: String
    public var bpm: Int

    public init(yymmdd: String, description: String, bpm: Int) {
        self.yymmdd = yymmdd
        self.description = description
        self.bpm = bpm
    }

    public var sanitizedDescription: String {
        Self.sanitize(description)
    }

    public var folderName: String {
        "\(yymmdd)_\(sanitizedDescription)_\(bpm)"
    }

    public var isValid: Bool {
        yymmdd.range(of: #"^\d{6}$"#, options: .regularExpression) != nil
            && !sanitizedDescription.isEmpty
            && (20...300).contains(bpm)
    }

    public static func sanitize(_ raw: String) -> String {
        let stripped = raw
            .replacingOccurrences(of: "/", with: " ")
            .replacingOccurrences(of: "\\", with: " ")
            .replacingOccurrences(of: ":", with: " ")
            .replacingOccurrences(of: "\0", with: " ")
            .replacingOccurrences(of: "\u{202F}", with: " ")
        let collapsed = stripped
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")
        return collapsed
    }

    public static func yymmdd(from date: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        let year = (parts.year ?? 0) % 100
        let month = parts.month ?? 0
        let day = parts.day ?? 0
        return String(format: "%02d%02d%02d", year, month, day)
    }

    public static func defaultDate(
        fromDisplayName displayName: String,
        oldest: Date,
        calendar: Calendar = .current
    ) -> String {
        let prefix = String(displayName.prefix(6))
        if prefix.range(of: #"^\d{6}$"#, options: .regularExpression) != nil,
           displayName.count == 6 || displayName.dropFirst(6).first == "_" {
            return prefix
        }
        return yymmdd(from: oldest, calendar: calendar)
    }
}
