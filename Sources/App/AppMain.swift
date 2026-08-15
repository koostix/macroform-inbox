import SwiftUI

@main
struct MacroformInboxApp: App {
    @StateObject private var viewModel = InboxViewModel()

    var body: some Scene {
        WindowGroup("Macroform Inbox") {
            InboxView(viewModel: viewModel)
                .focusable()
                .onKeyPress(.space) {
                    viewModel.player.toggle()
                    return .handled
                }
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button("File It") { viewModel.fileSelected() }
                    .keyboardShortcut(.return, modifiers: [.command])
                    .disabled(!viewModel.isNameValid || viewModel.isFiling)

                Button("Skip") { viewModel.skip() }
                    .keyboardShortcut(".", modifiers: [.command])
                    .disabled(viewModel.selectedPile == nil)

                Divider()

                Button("Play/Pause Preview") { viewModel.player.toggle() }
                    .keyboardShortcut(.space, modifiers: [])
                    .disabled(viewModel.currentPreviewURL == nil)

                Divider()

                Button("Reveal Pile in Finder") { viewModel.revealSelected() }
                    .keyboardShortcut("r", modifiers: [.command])
                    .disabled(viewModel.selectedPile == nil)

                Button("Reveal _Start in Finder") { viewModel.revealStart() }
                    .keyboardShortcut("r", modifiers: [.command, .shift])

                Button("Reload Inbox") { viewModel.reload() }
                    .keyboardShortcut("l", modifiers: [.command])
            }
        }
    }
}

extension Notification.Name {
    static let macroformInboxReload = Notification.Name("macroformInboxReload")
}
