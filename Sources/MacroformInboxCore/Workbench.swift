import Foundation

public struct Workbench: Equatable, Sendable {
    public var root: URL
    public var logicProjects: URL

    public var inbox: URL { root.appendingPathComponent("_Inbox", isDirectory: true) }
    public var start: URL { root.appendingPathComponent("_Start", isDirectory: true) }
    public var revise: URL { root.appendingPathComponent("2_Revise", isDirectory: true) }

    public init(root: URL, logicProjects: URL) {
        self.root = root
        self.logicProjects = logicProjects
    }

    public static func live() -> Workbench {
        Workbench(
            root: FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Desktop/_Music Projects", isDirectory: true),
            logicProjects: FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Music/Logic", isDirectory: true)
        )
    }
}
