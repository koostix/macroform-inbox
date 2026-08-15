import Foundation

public enum LooseFileWrapperError: Error, Equatable, LocalizedError {
    case noLooseFiles
    case destinationExists
    case crossVolume

    public var errorDescription: String? {
        switch self {
        case .noLooseFiles:
            return "There are no loose files to wrap."
        case .destinationExists:
            return "A folder with that name already exists."
        case .crossVolume:
            return "This pile is on a different volume. Copying across volumes is not enabled yet."
        }
    }
}

public struct LooseFileWrapper {
    private let volumeID: (URL) -> String

    public init() {
        self.volumeID = LooseFileWrapper.defaultVolumeID
    }

    public init(volumeID: @escaping (URL) -> String) {
        self.volumeID = volumeID
    }

    public func wrap(from directory: URL, to destination: URL) throws -> MoveResult {
        let directory = directory.standardizedFileURL
        let destination = destination.standardizedFileURL
        let fm = FileManager.default

        let files = try looseFiles(in: directory)
        guard !files.isEmpty else {
            throw LooseFileWrapperError.noLooseFiles
        }

        if fm.fileExists(atPath: destination.path) {
            throw LooseFileWrapperError.destinationExists
        }

        guard volumeID(directory) == volumeID(destination) else {
            throw LooseFileWrapperError.crossVolume
        }

        try fm.createDirectory(at: destination, withIntermediateDirectories: true)
        for file in files {
            try fm.moveItem(at: file, to: destination.appendingPathComponent(file.lastPathComponent))
        }
        return MoveResult(destination: destination, didMove: true)
    }

    private func looseFiles(in directory: URL) throws -> [URL] {
        let fm = FileManager.default
        let urls = try fm.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey],
            options: [.skipsHiddenFiles]
        )
        return try urls.filter { url in
            if url.lastPathComponent == ".DS_Store" { return false }
            let values = try url.resourceValues(forKeys: [.isRegularFileKey, .isDirectoryKey])
            return values.isRegularFile == true && values.isDirectory != true
        }
    }

    private static func defaultVolumeID(_ url: URL) -> String {
        var existing = url.standardizedFileURL
        let fm = FileManager.default
        while !fm.fileExists(atPath: existing.path), existing.path != "/" {
            existing.deleteLastPathComponent()
        }
        if let identifier = try? existing.resourceValues(forKeys: [.volumeIdentifierKey]).volumeIdentifier {
            return String(describing: identifier)
        }
        return existing.path
    }
}
