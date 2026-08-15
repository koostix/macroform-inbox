import SwiftUI
import MusicProjectsOrganizerCore

struct InboxView: View {
    @ObservedObject var viewModel: InboxViewModel

    var body: some View {
        NavigationSplitView {
            sidebar
                .frame(minWidth: 280)
                .background(Theme.sidebar)
        } detail: {
            detail
                .background(Theme.background)
        }
        .frame(minWidth: 860, minHeight: 520)
        .preferredColorScheme(.dark)
        .toolbar {
            ToolbarItemGroup {
                Button("Open…", systemImage: "folder.badge.plus") { viewModel.openFolder() }
                Button("Inbox", systemImage: "tray") { viewModel.useInbox() }
                    .disabled(viewModel.isWorkbenchMode)
                Button("Reload", systemImage: "arrow.clockwise") { viewModel.reload() }
                Button("Reveal", systemImage: "folder") { viewModel.revealSelected() }
                    .disabled(viewModel.selectedPile == nil)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .musicProjectsOrganizerReload)) { _ in
            viewModel.reload()
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(viewModel.locationTitle.uppercased())
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Theme.muted)
                    Spacer()
                    Text("\(viewModel.visiblePiles.count)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(Theme.muted)
                }
                Text(viewModel.locationPath)
                    .font(.caption2)
                    .foregroundStyle(Theme.muted)
                    .lineLimit(2)
                Toggle("Unnamed only", isOn: $viewModel.showUnnamedOnly)
                    .font(.caption)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .onChange(of: viewModel.showUnnamedOnly) { _, _ in
                        if let selected = viewModel.selectedPile,
                           viewModel.visiblePiles.contains(where: { $0.id == selected.id }) {
                            return
                        }
                        if let first = viewModel.visiblePiles.first {
                            viewModel.select(first)
                        } else {
                            viewModel.selectedPileID = nil
                        }
                    }
            }
            .padding()

            List(viewModel.visiblePiles, selection: $viewModel.selectedPileID) { pile in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(pile.displayName)
                            .lineLimit(1)
                        if pile.isUnnamed {
                            Text("unnamed")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(Theme.accent)
                        }
                    }
                    Text(pileSubtitle(pile))
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
    }

    @ViewBuilder
    private var detail: some View {
        if let pile = viewModel.selectedPile {
            Form {
                Section("Inspect") {
                    LabeledContent("Source", value: pile.sourceURL.path)
                        .font(.caption)
                    LabeledContent("Kind", value: kindLabel(pile))
                    LabeledContent("Contents", value: contentsLabel(pile))

                    if !contentRows.isEmpty {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 2) {
                                ForEach(contentRows) { row in
                                    Button {
                                        if row.isAudio {
                                            viewModel.choosePreview(row.url)
                                        } else {
                                            viewModel.revealItem(row.url)
                                        }
                                    } label: {
                                        HStack(spacing: 8) {
                                            Image(systemName: row.isAudio ? "waveform" : (row.isDirectory ? "folder" : "doc"))
                                                .frame(width: 12)
                                            Text(row.name)
                                                .lineLimit(1)
                                            Spacer()
                                            Text(row.kindLabel)
                                            if row.fileSize > 0, !row.isDirectory {
                                                Text(byteString(row.fileSize))
                                                    .monospacedDigit()
                                            }
                                        }
                                        .font(.caption)
                                        .foregroundStyle(isSelectedPreview(row.url) ? Theme.accent : Theme.muted)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.vertical, 3)
                                        .padding(.horizontal, 4)
                                        .background(
                                            isSelectedPreview(row.url)
                                                ? Theme.accent.opacity(0.12)
                                                : Color.clear,
                                            in: RoundedRectangle(cornerRadius: 4)
                                        )
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .frame(maxHeight: 220)
                    }

                    if viewModel.selectedPreviewURL != nil {
                        PreviewControls(
                            player: viewModel.player,
                            filename: viewModel.selectedPreviewURL?.lastPathComponent ?? ""
                        )
                    } else if contentRows.contains(where: \.isAudio) {
                        Text("Click a file to preview it.")
                            .font(.caption)
                            .foregroundStyle(Theme.muted)
                    } else {
                        Text("No preview audio in this pile.")
                            .font(.caption)
                            .foregroundStyle(Theme.muted)
                    }

                    if viewModel.inventory?.hasLogicProject == true || pile.kind == .logicPackage {
                        Text("Logic project in this pile — close it in Logic before filing.")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }

                Section("Name this project") {
                    TextField("Date (YYMMDD)", text: $viewModel.dateText)
                        .textFieldStyle(.roundedBorder)
                    HStack(alignment: .center, spacing: 8) {
                        TextField("Description", text: $viewModel.descriptionText)
                            .textFieldStyle(.roundedBorder)
                        Button("Auto rename") { viewModel.autoRenameSelected() }
                            .disabled(!viewModel.canAutoRename || viewModel.isFiling)
                            .help("Remove spaces and capitalize each word, like UnderwaterGuitar.")
                    }
                    TextField("BPM or 000", text: $viewModel.bpmText)
                        .textFieldStyle(.roundedBorder)
                    Button(viewModel.tapCount > 0 ? "Tap (\(viewModel.tapCount))" : "Tap") {
                        viewModel.tapBeat()
                    }
                    .help("Space: tap a quarter note. Leave 000 if there is no tempo. Click a file to play.")

                    if !viewModel.proposedFolderName.isEmpty {
                        LabeledContent("Folder", value: viewModel.proposedFolderName)
                            .font(.caption.monospaced())
                            .foregroundStyle(viewModel.isNameValid ? Theme.accent : Theme.muted)
                    }
                    if let destination = viewModel.proposedDestinationURL {
                        LabeledContent("Lands in", value: destination.deletingLastPathComponent().path)
                            .font(.caption)
                            .foregroundStyle(Theme.muted)
                    }
                }

                Section("Organize") {
                    Picker("Destination", selection: $viewModel.destination) {
                        Text(FileDestination.inPlace.title).tag(FileDestination.inPlace)
                        Text(FileDestination.start.title).tag(FileDestination.start)
                        if viewModel.customDestination != nil {
                            Text(viewModel.customDestination?.lastPathComponent ?? "Other")
                                .tag(FileDestination.custom)
                        }
                    }
                    .pickerStyle(.segmented)
                    Button("Choose folder…") {
                        viewModel.chooseCustomDestination()
                    }
                    if viewModel.destination == .custom, let folder = viewModel.customDestination {
                        Text(folder.path)
                            .font(.caption)
                            .foregroundStyle(Theme.muted)
                            .textSelection(.enabled)
                    }
                    if pile.kind == .looseFiles {
                        Text("Loose files will be wrapped into the new folder. Subfolders stay put.")
                            .font(.caption)
                            .foregroundStyle(Theme.muted)
                    }

                    HStack {
                        Button("Skip") { viewModel.skip() }
                        Spacer()
                        Button(fileButtonTitle(pile), action: viewModel.fileSelected)
                            .keyboardShortcut(.return, modifiers: [])
                            .buttonStyle(.borderedProminent)
                            .disabled(!viewModel.canFile)
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(pile.kind == .looseFiles ? "Wrap files" : "Organize")
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
                viewModel.isWorkbenchMode ? "Inbox is clear" : "Nothing to organize",
                systemImage: "checkmark.circle",
                description: Text(
                    viewModel.isWorkbenchMode
                        ? "Drop a session folder into _Music Projects/_Inbox, or open any folder."
                        : "Open another folder, or turn off Unnamed only."
                )
            )
        }
    }

    private var contentRows: [ContentRow] {
        var rows: [ContentRow] = (viewModel.inventory?.entries ?? []).map(ContentRow.init)
        let listed = Set(rows.map { $0.url.standardizedFileURL })
        for url in viewModel.audioFiles where !listed.contains(url.standardizedFileURL) {
            rows.append(
                ContentRow(
                    url: url,
                    name: url.lastPathComponent,
                    kindLabel: url.pathExtension.lowercased(),
                    fileSize: 0,
                    isAudio: true,
                    isDirectory: false
                )
            )
        }
        return rows
    }

    private func isSelectedPreview(_ url: URL) -> Bool {
        viewModel.selectedPreviewURL?.standardizedFileURL == url.standardizedFileURL
    }

    private func pileSubtitle(_ pile: Pile) -> String {
        let files = "\(pile.fileCount) file\(pile.fileCount == 1 ? "" : "s")"
        let size = pile.byteSize > 0 ? " · \(byteString(pile.byteSize))" : ""
        let origin = pile.origin == .folder ? pile.kind.rawValue : pile.origin.rawValue
        return "\(files)\(size) · \(origin)"
    }

    private func kindLabel(_ pile: Pile) -> String {
        switch pile.kind {
        case .looseFiles: return "Loose files"
        case .logicPackage: return "Logic project"
        case .folder: return "Folder"
        }
    }

    private func contentsLabel(_ pile: Pile) -> String {
        if let inventory = viewModel.inventory {
            return "\(inventory.summary) · \(byteString(inventory.totalBytes))"
        }
        return "\(pile.fileCount) file\(pile.fileCount == 1 ? "" : "s")"
    }

    private func fileButtonTitle(_ pile: Pile) -> String {
        switch (pile.kind, viewModel.destination) {
        case (.looseFiles, _): return "Wrap files"
        case (_, .inPlace): return "Rename"
        default: return "File it"
        }
    }

    private func byteString(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}

private struct ContentRow: Identifiable {
    var id: URL { url }
    var url: URL
    var name: String
    var kindLabel: String
    var fileSize: Int64
    var isAudio: Bool
    var isDirectory: Bool

    init(url: URL, name: String, kindLabel: String, fileSize: Int64, isAudio: Bool, isDirectory: Bool) {
        self.url = url
        self.name = name
        self.kindLabel = kindLabel
        self.fileSize = fileSize
        self.isAudio = isAudio
        self.isDirectory = isDirectory
    }

    init(_ entry: InventoryEntry) {
        url = entry.url
        name = entry.name
        kindLabel = entry.kindLabel
        fileSize = entry.fileSize
        isAudio = entry.isAudio
        isDirectory = entry.isDirectory
    }
}

private struct PreviewControls: View {
    @ObservedObject var player: PreviewPlayer
    let filename: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            WaveformView(
                samples: player.samples,
                progress: player.progress,
                currentTime: player.currentTime,
                duration: player.duration,
                onSeek: { player.seek(toProgress: $0) },
                onSeekEnd: { player.play() }
            )
            HStack {
                Button(player.isPlaying ? "Pause" : "Play") {
                    player.toggle()
                }
                Text(filename)
                    .font(.caption)
                    .foregroundStyle(Theme.muted)
                    .lineLimit(1)
            }
        }
    }
}
