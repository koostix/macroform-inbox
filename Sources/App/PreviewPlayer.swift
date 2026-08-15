import AVFoundation
import Foundation

@MainActor
final class PreviewPlayer: ObservableObject {
    @Published private(set) var isPlaying = false
    @Published private(set) var currentURL: URL?
    @Published private(set) var currentTime: TimeInterval = 0
    @Published private(set) var duration: TimeInterval = 0
    @Published private(set) var samples: [Float] = []

    private var player: AVAudioPlayer?
    private var timer: Timer?

    var progress: Double {
        guard duration > 0 else { return 0 }
        return min(max(currentTime / duration, 0), 1)
    }

    func load(_ url: URL?) {
        stop()
        currentURL = url
        guard let url else { return }
        player = try? AVAudioPlayer(contentsOf: url)
        player?.prepareToPlay()
        duration = player?.duration ?? 0
        currentTime = 0
        loadWaveform(from: url)
    }

    func toggle() {
        guard player != nil else { return }
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    func play() {
        guard let player else { return }
        player.play()
        isPlaying = true
        startTimer()
    }

    func pause() {
        player?.pause()
        isPlaying = false
        stopTimer()
        syncTime()
    }

    func stop() {
        stopTimer()
        player?.stop()
        player = nil
        isPlaying = false
        currentURL = nil
        currentTime = 0
        duration = 0
        samples = []
    }

    func seek(toProgress progress: Double) {
        guard let player, duration > 0 else { return }
        let clamped = min(max(progress, 0), 1)
        player.currentTime = duration * clamped
        currentTime = player.currentTime
    }

    private func loadWaveform(from url: URL) {
        Task.detached(priority: .userInitiated) {
            let peaks = WaveformSampler.peaks(from: url, count: 360)
            await MainActor.run {
                guard self.currentURL == url else { return }
                self.samples = peaks
            }
        }
    }

    private func startTimer() {
        stopTimer()
        let timer = Timer(timeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.syncTime()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func syncTime() {
        currentTime = player?.currentTime ?? 0
        duration = player?.duration ?? duration
        if isPlaying, player?.isPlaying != true {
            isPlaying = false
            stopTimer()
            if duration > 0 {
                currentTime = duration
            }
        }
    }
}
