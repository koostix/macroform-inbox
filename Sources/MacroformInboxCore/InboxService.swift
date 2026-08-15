import Foundation

public struct InboxService {
    public let workbench: Workbench
    private let scanner: PileScanner
    private let directoryScanner: DirectoryScanner
    private let inspector: FolderInspector
    private let picker: PreviewPicker
    private let resolver: DestinationResolver
    private let mover: PileMover
    private let wrapper: LooseFileWrapper

    public init(
        workbench: Workbench,
        mover: PileMover = PileMover(),
        wrapper: LooseFileWrapper = LooseFileWrapper()
    ) {
        self.workbench = workbench
        self.scanner = PileScanner()
        self.directoryScanner = DirectoryScanner()
        self.inspector = FolderInspector()
        self.picker = PreviewPicker()
        self.resolver = DestinationResolver()
        self.mover = mover
        self.wrapper = wrapper
    }

    public func ensureInbox() throws {
        try scanner.ensureInboxExists(workbench: workbench)
    }

    public func loadPiles(in directory: URL? = nil) throws -> [Pile] {
        let piles: [Pile]
        if let directory {
            piles = try directoryScanner.scan(directory)
        } else {
            piles = try scanner.scan(workbench: workbench)
        }
        return piles.sorted { lhs, rhs in
            lhs.sourceURL.path.localizedStandardCompare(rhs.sourceURL.path) == .orderedAscending
        }
    }

    public func inspect(_ pile: Pile) throws -> FolderInventory {
        try inspector.inspect(pile)
    }

    public func previewURL(for pile: Pile) throws -> URL? {
        try picker.previewFile(in: pile.sourceURL)
    }

    public func audioFiles(in pile: Pile) throws -> [URL] {
        if pile.kind == .looseFiles {
            return try inspector.inspect(pile).audioEntries.map(\.url)
        }
        return try picker.audioFiles(in: pile.sourceURL)
    }

    public func proposedDestination(for pile: Pile, name: ProjectName, parent: URL? = nil) -> URL {
        resolver.destination(for: pile, name: name, workbench: workbench, parent: parent)
    }

    public func file(_ pile: Pile, name: ProjectName, into parent: URL? = nil) throws -> MoveResult {
        guard name.isValid else {
            throw InboxServiceError.invalidProjectName
        }
        let destination = resolver.destination(for: pile, name: name, workbench: workbench, parent: parent)
        if pile.kind == .looseFiles {
            return try wrapper.wrap(from: pile.sourceURL, to: destination)
        }
        return try mover.move(from: pile.sourceURL, to: destination)
    }
}

public enum InboxServiceError: Error, Equatable, LocalizedError {
    case invalidProjectName

    public var errorDescription: String? {
        "Enter a description, a six-digit date, and a BPM from 20 to 300."
    }
}
