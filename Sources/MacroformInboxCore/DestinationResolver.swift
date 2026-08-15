import Foundation

public struct DestinationResolver: Sendable {
    public init() {}

    public func destination(for pile: Pile, name: ProjectName, workbench: Workbench) -> URL {
        let parent: URL
        switch pile.origin {
        case .start:
            parent = pile.sourceURL.deletingLastPathComponent()
        case .revise:
            parent = pile.sourceURL.deletingLastPathComponent()
        case .inbox, .logic:
            parent = workbench.start
        }

        let base = name.folderName
        var candidate = parent.appendingPathComponent(base, isDirectory: true)
        var suffix = 2
        while destinationExists(candidate, otherThan: pile.sourceURL) {
            candidate = parent.appendingPathComponent("\(base)-\(suffix)", isDirectory: true)
            suffix += 1
        }
        return candidate
    }

    private func destinationExists(_ url: URL, otherThan source: URL) -> Bool {
        let fm = FileManager.default
        guard fm.fileExists(atPath: url.path) else { return false }
        return url.standardizedFileURL != source.standardizedFileURL
    }
}
