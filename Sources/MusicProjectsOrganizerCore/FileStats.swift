import Foundation

public enum FileStats {
    public static func collect(at root: URL) throws -> (count: Int, bytes: Int64, oldest: Date, newest: Date) {
        let fm = FileManager.default
        var isDirectory: ObjCBool = false
        guard fm.fileExists(atPath: root.path, isDirectory: &isDirectory) else {
            let now = Date()
            return (0, 0, now, now)
        }

        if !isDirectory.boolValue {
            let values = try root.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey])
            let date = values.contentModificationDate ?? Date()
            return (1, Int64(values.fileSize ?? 0), date, date)
        }

        var count = 0
        var bytes: Int64 = 0
        var oldest: Date?
        var newest: Date?
        if let enumerator = fm.enumerator(
            at: root,
            includingPropertiesForKeys: [.isRegularFileKey, .contentModificationDateKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        ) {
            for case let fileURL as URL in enumerator {
                if fileURL.lastPathComponent == ".DS_Store" { continue }
                let values = try fileURL.resourceValues(
                    forKeys: [.isRegularFileKey, .contentModificationDateKey, .fileSizeKey]
                )
                guard values.isRegularFile == true else { continue }
                count += 1
                bytes += Int64(values.fileSize ?? 0)
                if let date = values.contentModificationDate {
                    oldest = min(oldest ?? date, date)
                    newest = max(newest ?? date, date)
                }
            }
        }

        if let oldest, let newest {
            return (count, bytes, oldest, newest)
        }
        let folderValues = try root.resourceValues(forKeys: [.contentModificationDateKey])
        let date = folderValues.contentModificationDate ?? Date()
        return (count, bytes, date, date)
    }
}
