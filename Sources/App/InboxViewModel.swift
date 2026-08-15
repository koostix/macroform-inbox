import AppKit
import Foundation
import MacroformInboxCore
import SwiftUI

@MainActor
final class InboxViewModel: ObservableObject {
    @Published private(set) var piles: [Pile] = []
    @Published var selectedPileID: URL?
    @Published var dateText = ""
    @Published var descriptionText = ""
    @Published var bpmText = ""
    @Published private(set) var status = "Ready"
    @Published private(set) var isFiling = false
    let player = PreviewPlayer()

    let service: InboxService

    init(service: InboxService = InboxService(workbench: .live())) {
        self.service = service
        reload()
    }

    var selectedPile: Pile? {
        piles.first(where: { $0.id == selectedPileID })
    }

    var currentPreviewURL: URL? {
        guard let selectedPile else { return nil }
        return try? service.previewURL(for: selectedPile)
    }

    var proposedName: ProjectName {
        ProjectName(
            yymmdd: dateText,
            description: descriptionText,
            bpm: Int(bpmText) ?? 0
        )
    }

    var proposedFolderName: String { proposedName.folderName }

    var isNameValid: Bool { proposedName.isValid }

    func reload() {
        do {
            try service.ensureInbox()
            piles = try service.loadPiles()
            if let selectedPileID, piles.contains(where: { $0.id == selectedPileID }) {
                applyForm(for: piles.first(where: { $0.id == selectedPileID })!)
            } else if let first = piles.first {
                select(first)
            } else {
                selectedPileID = nil
                clearForm()
            }
            status = piles.isEmpty ? "No unnamed piles." : "Ready"
        } catch {
            status = error.localizedDescription
        }
    }

    func select(_ pile: Pile) {
        selectedPileID = pile.id
        applyForm(for: pile)
        player.load(currentPreviewURL)
    }

    func skip() {
        guard let selectedPile else { return }
        let skippedName = selectedPile.displayName
        player.stop()
        if let index = piles.firstIndex(where: { $0.id == selectedPile.id }) {
            let nextIndex = index + 1
            if nextIndex < piles.count {
                select(piles[nextIndex])
            } else if index > 0 {
                select(piles[index - 1])
            } else {
                selectedPileID = nil
                clearForm()
            }
        }
        status = "Skipped \(skippedName)."
    }

    func fileSelected() {
        guard let selectedPile, isNameValid else { return }
        isFiling = true
        defer { isFiling = false }
        player.stop()
        do {
            let result = try service.file(selectedPile, name: proposedName)
            status = result.didMove
                ? "Filed → \(result.destination.lastPathComponent)"
                : "Already filed."
            descriptionText = ""
            bpmText = ""
            reloadKeepingStatus()
        } catch {
            status = error.localizedDescription
        }
    }

    func revealSelected() {
        guard let selectedPile else { return }
        NSWorkspace.shared.activateFileViewerSelecting([selectedPile.sourceURL])
    }

    func revealStart() {
        NSWorkspace.shared.activateFileViewerSelecting([service.workbench.start])
    }

    private func reloadKeepingStatus() {
        let previous = status
        reload()
        status = previous
    }

    private func applyForm(for pile: Pile) {
        dateText = ProjectName.defaultDate(fromDisplayName: pile.displayName, oldest: pile.oldestFileDate)
        descriptionText = suggestedDescription(for: pile.displayName)
        bpmText = ""
    }

    private func clearForm() {
        dateText = ""
        descriptionText = ""
        bpmText = ""
    }

    private func suggestedDescription(for displayName: String) -> String {
        var value = displayName
        if let range = value.range(of: #"^\d{6}[_-]"#, options: .regularExpression) {
            value.removeSubrange(range)
        }
        value = value.replacingOccurrences(of: ".logicx", with: "", options: [.caseInsensitive])
        if UnnamedDetector.isUnnamed(value) { return "" }
        return ProjectName.sanitize(value)
    }
}
