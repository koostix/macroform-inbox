import Foundation

public struct InboxService {
    public let workbench: Workbench
    private let scanner: PileScanner
    private let picker: PreviewPicker
    private let resolver: DestinationResolver
    private let mover: PileMover

    public init(workbench: Workbench, mover: PileMover = PileMover()) {
        self.workbench = workbench
        self.scanner = PileScanner()
        self.picker = PreviewPicker()
        self.resolver = DestinationResolver()
        self.mover = mover
    }

    public func ensureInbox() throws {
        try scanner.ensureInboxExists(workbench: workbench)
    }

    public func loadPiles() throws -> [Pile] {
        try scanner.scan(workbench: workbench)
            .sorted { lhs, rhs in
                lhs.sourceURL.path.localizedStandardCompare(rhs.sourceURL.path) == .orderedAscending
            }
    }

    public func previewURL(for pile: Pile) throws -> URL? {
        try picker.previewFile(in: pile.sourceURL)
    }

    public func file(_ pile: Pile, name: ProjectName) throws -> MoveResult {
        guard name.isValid else {
            throw InboxServiceError.invalidProjectName
        }
        let destination = resolver.destination(for: pile, name: name, workbench: workbench)
        return try mover.move(from: pile.sourceURL, to: destination)
    }
}

public enum InboxServiceError: Error, Equatable, LocalizedError {
    case invalidProjectName

    public var errorDescription: String? {
        "Enter a description, a six-digit date, and a BPM from 20 to 300."
    }
}
