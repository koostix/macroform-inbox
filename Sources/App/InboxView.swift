import SwiftUI
import MacroformInboxCore

struct InboxView: View {
    @StateObject var viewModel: InboxViewModel

    var body: some View {
        NavigationSplitView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("INBOX")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Theme.muted)
                    Spacer()
                    Text("\(viewModel.piles.count)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(Theme.muted)
                }
                .padding()

                List(viewModel.piles, selection: $viewModel.selectedPileID) { pile in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(pile.displayName)
                            .lineLimit(1)
                        Text("\(pile.fileCount) file\(pile.fileCount == 1 ? "" : "s") · \(pile.origin.rawValue)")
                            .font(.caption)
                            .foregroundStyle(Theme.muted)
                    }
                    .tag(pile.id)
                }
                .listStyle(.sidebar)
                .onChange(of: viewModel.selectedPileID) { _, newID in
                    if let pile = viewModel.piles.first(where: { $0.id == newID }) {
                        viewModel.select(pile)
                    }
                }
            }
            .frame(minWidth: 260)
            .background(Theme.sidebar)
        } detail: {
            detail
                .background(Theme.background)
        }
        .frame(minWidth: 760, minHeight: 480)
        .preferredColorScheme(.dark)
        .toolbar {
            ToolbarItemGroup {
                Button("Reload", systemImage: "arrow.clockwise") { viewModel.reload() }
                Button("Reveal", systemImage: "folder") { viewModel.revealSelected() }
                    .disabled(viewModel.selectedPile == nil)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .macroformInboxReload)) { _ in
            viewModel.reload()
        }
    }

    @ViewBuilder
    private var detail: some View {
        if let pile = viewModel.selectedPile {
            Form {
                Section("Selected pile") {
                    LabeledContent("Source", value: pile.sourceURL.path)
                        .font(.caption)
                    LabeledContent("Files", value: "\(pile.fileCount)")
                }

                Section("Name this project") {
                    TextField("Date (YYMMDD)", text: $viewModel.dateText)
                        .textFieldStyle(.roundedBorder)
                    TextField("Description", text: $viewModel.descriptionText)
                        .textFieldStyle(.roundedBorder)
                    TextField("BPM", text: $viewModel.bpmText)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 140)

                    if !viewModel.proposedFolderName.isEmpty {
                        LabeledContent("Folder", value: viewModel.proposedFolderName)
                            .font(.caption.monospaced())
                            .foregroundStyle(viewModel.isNameValid ? Theme.accent : Theme.muted)
                    }
                }

                Section {
                    HStack {
                        Button("Skip") { viewModel.skip() }
                        Spacer()
                        Button("File it", action: viewModel.fileSelected)
                            .keyboardShortcut(.return, modifiers: [])
                            .buttonStyle(.borderedProminent)
                            .disabled(!viewModel.isNameValid || viewModel.isFiling)
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Process pile")
            .safeAreaInset(edge: .bottom) {
                Text(viewModel.status)
                    .font(.caption)
                    .foregroundStyle(Theme.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }
        } else {
            ContentUnavailableView(
                "Inbox is clear",
                systemImage: "checkmark.circle",
                description: Text("Drop a session folder into _Music Projects/_Inbox.")
            )
        }
    }
}
