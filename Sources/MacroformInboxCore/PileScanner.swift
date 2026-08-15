import Foundation

public struct PileScanner: Sendable {
    public init() {}

    public func ensureInboxExists(workbench: Workbench) throws {
        try FileManager.default.createDirectory(at: workbench.inbox, withIntermediateDirectories: true)
    }

    public func scan(workbench: Workbench) throws -> [Pile] {
        var piles: [Pile] = []
        piles += try children(of: workbench.inbox, origin: .inbox, unnamedOnly: false)
        piles += try children(of: workbench.start, origin: .start, unnamedOnly: true)
        piles += try children(of: workbench.revise, origin: .revise, unnamedOnly: true)
        piles += try children(of: workbench.logicProjects, origin: .logic, unnamedOnly: true, logicPackagesOnly: true)
        return piles
    }

    private func children(
        of directory: URL,
        origin: Origin,
        unnamedOnly: Bool,
        logicPackagesOnly: Bool = false
    ) throws -> [Pile] {
        let fm = FileManager.default
        var isDirectory: ObjCBool = false
        guard fm.fileExists(atPath: directory.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            return []
        }

        let urls = try fm.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey, .isRegularFileKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )

        var piles: [Pile] = []
        for url in urls {
            if url.lastPathComponent == ".DS_Store" { continue }
            if logicPackagesOnly && url.pathExtension.lowercased() != "logicx" { continue }
            if unnamedOnly && !UnnamedDetector.isUnnamed(url.lastPathComponent) { continue }

            let stats = try fileStats(at: url)
            piles.append(
                Pile(
                    sourceURL: url,
                    origin: origin,
                    displayName: url.lastPathComponent,
                    fileCount: stats.count,
                    oldestFileDate: stats.oldest
                )
            )
        }
        return piles
    }

    private func fileStats(at root: URL) throws -> (count: Int, oldest: Date) {
        let fm = FileManager.default
        var isDirectory: ObjCBool = false
        guard fm.fileExists(atPath: root.path, isDirectory: &isDirectory) else {
            return (0, Date())
        }

        if !isDirectory.boolValue {
            let values = try root.resourceValues(forKeys: [.contentModificationDateKey])
            return (1, values.contentModificationDate ?? Date())
        }

        var count = 0
        var oldest: Date?
        if let enumerator = fm.enumerator(
            at: root,
            includingPropertiesForKeys: [.isRegularFileKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) {
            for case let fileURL as URL in enumerator {
                if fileURL.lastPathComponent == ".DS_Store" { continue }
                let values = try fileURL.resourceValues(forKeys: [.isRegularFileKey, .contentModificationDateKey])
                guard values.isRegularFile == true else { continue }
                count += 1
                if let date = values.contentModificationDate {
                    oldest = min(oldest ?? date, date)
                }
            }
        }

        if let oldest {
            return (count, oldest)
        }
        let folderValues = try root.resourceValues(forKeys: [.contentModificationDateKey])
        return (count, folderValues.contentModificationDate ?? Date())
    }
}
