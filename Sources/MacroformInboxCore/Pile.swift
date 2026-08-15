import Foundation

public enum Origin: String, Sendable, Equatable {
    case inbox
    case start
    case revise
    case logic
}

public struct Pile: Equatable, Identifiable, Sendable {
    public var id: URL { sourceURL }
    public var sourceURL: URL
    public var origin: Origin
    public var displayName: String
    public var fileCount: Int
    public var oldestFileDate: Date

    public init(
        sourceURL: URL,
        origin: Origin,
        displayName: String,
        fileCount: Int,
        oldestFileDate: Date
    ) {
        self.sourceURL = sourceURL
        self.origin = origin
        self.displayName = displayName
        self.fileCount = fileCount
        self.oldestFileDate = oldestFileDate
    }
}
