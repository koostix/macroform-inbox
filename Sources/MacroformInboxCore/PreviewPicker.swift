import Foundation

public struct PreviewPicker: Sendable {
    // Duration would need AVFoundation. File size is a stable, testable stand-in
    // for "longest" among same-format recorder dumps.
    private static let audioExtensions: Set<String> = ["wav", "aif", "aiff", "mp3", "m4a", "caf"]

    public init() {}

    public func previewFile(in root: URL) throws -> URL? {
        let files = try audioFiles(in: root)
        guard !files.isEmpty else { return nil }

        if let mix = files.first(where: { $0.lastPathComponent.uppercased().hasPrefix("MIXST") }) {
            return mix
        }

        let bounces = files.filter { isInsideBounces($0, root: root) }
        if let bounce = largest(bounces) {
            return bounce
        }

        if let smart = files.first(where: {
            $0.lastPathComponent.lowercased().hasPrefix("smart tempo multitrack set")
        }) {
            return smart
        }

        return largest(files)
    }

    private func audioFiles(in root: URL) throws -> [URL] {
        let fm = FileManager.default
        var isDirectory: ObjCBool = false
        guard fm.fileExists(atPath: root.path, isDirectory: &isDirectory) else { return [] }

        if !isDirectory.boolValue {
            return isAudio(root) ? [root] : []
        }

        var results: [URL] = []
        if let enumerator = fm.enumerator(
            at: root,
            includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        ) {
            for case let fileURL as URL in enumerator {
                let values = try fileURL.resourceValues(forKeys: [.isRegularFileKey])
                guard values.isRegularFile == true, isAudio(fileURL) else { continue }
                results.append(fileURL)
            }
        }
        return results
    }

    private func isAudio(_ url: URL) -> Bool {
        Self.audioExtensions.contains(url.pathExtension.lowercased())
    }

    private func isInsideBounces(_ url: URL, root: URL) -> Bool {
        let rootParts = root.standardizedFileURL.pathComponents
        let parts = url.standardizedFileURL.deletingLastPathComponent().pathComponents
        guard parts.count >= rootParts.count else { return false }
        return parts.dropFirst(rootParts.count).contains { $0.caseInsensitiveCompare("Bounces") == .orderedSame }
    }

    private func largest(_ urls: [URL]) -> URL? {
        urls.max { lhs, rhs in
            (fileSize(lhs) ?? 0) < (fileSize(rhs) ?? 0)
        }
    }

    private func fileSize(_ url: URL) -> Int? {
        (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize
    }
}
