import Foundation

public enum PileMoverError: Error, Equatable, LocalizedError {
    case sourceMissing
    case destinationInsideSource
    case crossVolume

    public var errorDescription: String? {
        switch self {
        case .sourceMissing:
            return "The source pile no longer exists."
        case .destinationInsideSource:
            return "The destination cannot be inside the source pile."
        case .crossVolume:
            return "This pile is on a different volume. Copying across volumes is not enabled yet."
        }
    }
}

public struct MoveResult: Equatable, Sendable {
    public var destination: URL
    public var didMove: Bool

    public init(destination: URL, didMove: Bool) {
        self.destination = destination
        self.didMove = didMove
    }
}

public struct PileMover {
    private let volumeID: (URL) -> String

    public init() {
        self.volumeID = PileMover.defaultVolumeID
    }

    public init(volumeID: @escaping (URL) -> String) {
        self.volumeID = volumeID
    }

    public func move(from source: URL, to destination: URL) throws -> MoveResult {
        let source = source.standardizedFileURL
        let destination = destination.standardizedFileURL

        guard FileManager.default.fileExists(atPath: source.path) else {
            throw PileMoverError.sourceMissing
        }

        if source == destination {
            return MoveResult(destination: destination, didMove: false)
        }

        guard !isInside(destination, of: source) else {
            throw PileMoverError.destinationInsideSource
        }

        guard volumeID(source) == volumeID(destination) else {
            throw PileMoverError.crossVolume
        }

        try FileManager.default.moveItem(at: source, to: destination)
        return MoveResult(destination: destination, didMove: true)
    }

    private func isInside(_ candidate: URL, of source: URL) -> Bool {
        let sourceParts = source.pathComponents
        let candidateParts = candidate.pathComponents
        guard candidateParts.count > sourceParts.count else { return false }
        return candidateParts.starts(with: sourceParts)
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
