import Foundation

public enum UnnamedDetector {
    public static func isUnnamed(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        let withoutLogic = trimmed.lowercased().hasSuffix(".logicx")
            ? String(trimmed.dropLast(".logicx".count))
            : trimmed
        let candidate = withoutLogic.trimmingCharacters(in: .whitespacesAndNewlines)
        let folded = candidate.lowercased()

        if folded.contains("_unnamed-") || folded.hasPrefix("unnamed-") || folded == "unnamed" {
            return true
        }

        if untitledPattern.firstMatch(in: candidate, options: [], range: NSRange(location: 0, length: (candidate as NSString).length)) != nil {
            return true
        }

        let newFolderNames: Set<String> = [
            "new folder",
            "new folder with items",
            "untitled folder",
        ]
        return newFolderNames.contains(folded)
    }

    private static let untitledPattern = try! NSRegularExpression(
        pattern: #"^untitled(?:\s+\d+)?$"#,
        options: [.caseInsensitive]
    )
}
