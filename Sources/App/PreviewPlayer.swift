import AVFoundation
import Foundation

@MainActor
final class PreviewPlayer: ObservableObject {
    @Published private(set) var isPlaying = false
    @Published private(set) var currentURL: URL?

    private var player: AVAudioPlayer?

    func load(_ url: URL?) {
        stop()
        currentURL = url
        guard let url else { return }
        player = try? AVAudioPlayer(contentsOf: url)
        player?.prepareToPlay()
    }

    func toggle() {
        guard player != nil else { return }
        if isPlaying {
            player?.pause()
            isPlaying = false
        } else {
            player?.play()
            isPlaying = true
        }
    }

    func play() {
        guard player != nil else { return }
        player?.play()
        isPlaying = true
    }

    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
        currentURL = nil
    }
}
