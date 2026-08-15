import Foundation

public struct InventoryEntry: Equatable, Identifiable, Sendable {
    public var id: URL { url }
    public var url: URL
    public var name: String
    public var isDirectory: Bool
    public var fileSize: Int64
    public var modified: Date
    public var isAudio: Bool
    public var isLogic: Bool
    public var isImage: Bool

    public init(
        url: URL,
        name: String,
        isDirectory: Bool,
        fileSize: Int64,
        modified: Date,
        isAudio: Bool,
        isLogic: Bool,
        isImage: Bool = false
    ) {
        self.url = url
        self.name = name
        self.isDirectory = isDirectory
        self.fileSize = fileSize
        self.modified = modified
        self.isAudio = isAudio
        self.isLogic = isLogic
        self.isImage = isImage
    }

    public var kindLabel: String {
        if isLogic { return "logicx" }
        if isDirectory { return "folder" }
        let ext = url.pathExtension.lowercased()
        return ext.isEmpty ? "file" : ext
    }
}

public struct FolderInventory: Equatable, Sendable {
    public var root: URL
    public var entries: [InventoryEntry]
    public var fileCount: Int
    public var totalBytes: Int64
    public var oldestDate: Date
    public var newestDate: Date
    public var hasLogicProject: Bool

    public init(
        root: URL,
        entries: [InventoryEntry],
        fileCount: Int,
        totalBytes: Int64,
        oldestDate: Date,
        newestDate: Date,
        hasLogicProject: Bool
    ) {
        self.root = root
        self.entries = entries
        self.fileCount = fileCount
        self.totalBytes = totalBytes
        self.oldestDate = oldestDate
        self.newestDate = newestDate
        self.hasLogicProject = hasLogicProject
    }

    public var audioEntries: [InventoryEntry] {
        entries.filter(\.isAudio)
    }

    public var summary: String {
        var parts: [String] = []
        let audioCount = entries.filter(\.isAudio).count
        let folderCount = entries.filter { $0.isDirectory && !$0.isLogic }.count
        let imageCount = entries.filter(\.isImage).count
        if audioCount > 0 { parts.append("\(audioCount) audio") }
        if imageCount > 0 { parts.append("\(imageCount) image\(imageCount == 1 ? "" : "s")") }
        if folderCount > 0 { parts.append("\(folderCount) folder\(folderCount == 1 ? "" : "s")") }
        if hasLogicProject { parts.append("Logic") }
        if parts.isEmpty { parts.append("\(fileCount) file\(fileCount == 1 ? "" : "s")") }
        return parts.joined(separator: " · ")
    }
}

public struct FolderInspector: Sendable {
    public init() {}

    public func inspect(_ pile: Pile) throws -> FolderInventory {
        if pile.kind == .looseFiles {
            return try inspect(at: pile.sourceURL, looseFilesOnly: true)
        }
        return try inspect(at: pile.sourceURL, looseFilesOnly: false)
    }

    public func inspect(at root: URL, looseFilesOnly: Bool = false) throws -> FolderInventory {
        let fm = FileManager.default
        var isDirectory: ObjCBool = false
        guard fm.fileExists(atPath: root.path, isDirectory: &isDirectory) else {
            let now = Date()
            return FolderInventory(
                root: root,
                entries: [],
                fileCount: 0,
                totalBytes: 0,
                oldestDate: now,
                newestDate: now,
                hasLogicProject: false
            )
        }

        if !isDirectory.boolValue {
            let entry = try makeEntry(at: root)
            return FolderInventory(
                root: root,
                entries: [entry],
                fileCount: 1,
                totalBytes: entry.fileSize,
                oldestDate: entry.modified,
                newestDate: entry.modified,
                hasLogicProject: entry.isLogic
            )
        }

        let urls = try fm.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: [
                .isDirectoryKey,
                .isRegularFileKey,
                .fileSizeKey,
                .contentModificationDateKey,
            ],
            options: [.skipsHiddenFiles]
        )

        var entries: [InventoryEntry] = []
        var hasLogic = MediaTypes.isLogicPackage(root)
        for url in urls.sorted(by: { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }) {
            if url.lastPathComponent == ".DS_Store" { continue }
            let values = try url.resourceValues(forKeys: [.isDirectoryKey, .isRegularFileKey])
            let isDir = values.isDirectory == true
            if looseFilesOnly && isDir { continue }
            if !looseFilesOnly || values.isRegularFile == true {
                let entry = try makeEntry(at: url)
                entries.append(entry)
                if entry.isLogic { hasLogic = true }
            }
        }

        let stats = try FileStats.collect(at: root)
        return FolderInventory(
            root: root,
            entries: entries,
            fileCount: looseFilesOnly ? entries.count : stats.count,
            totalBytes: looseFilesOnly ? entries.reduce(0) { $0 + $1.fileSize } : stats.bytes,
            oldestDate: looseFilesOnly ? (entries.map(\.modified).min() ?? stats.oldest) : stats.oldest,
            newestDate: looseFilesOnly ? (entries.map(\.modified).max() ?? stats.newest) : stats.newest,
            hasLogicProject: hasLogic
        )
    }

    private func makeEntry(at url: URL) throws -> InventoryEntry {
        let values = try url.resourceValues(
            forKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey]
        )
        let isDir = values.isDirectory == true
        return InventoryEntry(
            url: url,
            name: url.lastPathComponent,
            isDirectory: isDir,
            fileSize: Int64(values.fileSize ?? 0),
            modified: values.contentModificationDate ?? Date(),
            isAudio: MediaTypes.isAudio(url),
            isLogic: MediaTypes.isLogicPackage(url),
            isImage: MediaTypes.isImage(url)
        )
    }
}
