import Foundation

public struct CoverPicker: Sendable {
    private static let preferredNames = ["cover", "folder", "artwork", "album", "front", "art"]

    public init() {}

    public func coverFile(in root: URL) throws -> URL? {
        let files = try imageFiles(in: root)
        guard !files.isEmpty else { return nil }

        if let named = files.first(where: { isPreferredName($0) }) {
            return named
        }
        return files.max { lhs, rhs in
            (fileSize(lhs) ?? 0) < (fileSize(rhs) ?? 0)
        }
    }

    public func imageFiles(in root: URL) throws -> [URL] {
        let fm = FileManager.default
        var isDirectory: ObjCBool = false
        guard fm.fileExists(atPath: root.path, isDirectory: &isDirectory) else { return [] }

        if !isDirectory.boolValue {
            return MediaTypes.isImage(root) ? [root] : []
        }

        var results: [URL] = []
        if let enumerator = fm.enumerator(
            at: root,
            includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        ) {
            for case let fileURL as URL in enumerator {
                let values = try fileURL.resourceValues(forKeys: [.isRegularFileKey])
                guard values.isRegularFile == true, MediaTypes.isImage(fileURL) else { continue }
                results.append(fileURL)
            }
        }
        return results
    }

    private func isPreferredName(_ url: URL) -> Bool {
        let name = url.deletingPathExtension().lastPathComponent.lowercased()
        return Self.preferredNames.contains { name.contains($0) }
    }

    private func fileSize(_ url: URL) -> Int? {
        (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize
    }
}
