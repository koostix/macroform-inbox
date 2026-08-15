import SwiftUI

@main
struct MacroformInboxApp: App {
    var body: some Scene {
        WindowGroup("Macroform Inbox") {
            InboxView(viewModel: InboxViewModel())
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button("Reload Inbox") {
                    NotificationCenter.default.post(name: .macroformInboxReload, object: nil)
                }
                .keyboardShortcut("l", modifiers: [.command])
            }
        }
    }
}

extension Notification.Name {
    static let macroformInboxReload = Notification.Name("macroformInboxReload")
}
