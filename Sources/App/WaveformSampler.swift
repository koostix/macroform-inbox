import AVFoundation
import Foundation

enum WaveformSampler {
    static func peaks(from url: URL, count: Int) -> [Float] {
        guard count > 0, let file = try? AVAudioFile(forReading: url) else { return [] }
        let totalFrames = file.length
        guard totalFrames > 0 else { return [] }

        let format = file.processingFormat
        let framesPerBin = max(1, Int((totalFrames + Int64(count) - 1) / Int64(count)))
        let chunk = AVAudioFrameCount(min(framesPerBin, 8192))
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: chunk) else { return [] }

        var peaks = [Float](repeating: 0, count: count)
        let channels = Int(format.channelCount)

        for bin in 0..<count {
            var peak: Float = 0
            var remaining = framesPerBin
            while remaining > 0 {
                let toRead = AVAudioFrameCount(min(remaining, Int(chunk)))
                do {
                    try file.read(into: buffer, frameCount: toRead)
                } catch {
                    return normalize(peaks)
                }
                let frames = Int(buffer.frameLength)
                if frames == 0 { return normalize(peaks) }
                if let data = buffer.floatChannelData {
                    for channel in 0..<channels {
                        let samples = data[channel]
                        for index in 0..<frames {
                            peak = max(peak, abs(samples[index]))
                        }
                    }
                }
                remaining -= frames
            }
            peaks[bin] = peak
        }
        return normalize(peaks)
    }

    private static func normalize(_ peaks: [Float]) -> [Float] {
        let loudest = peaks.max() ?? 0
        guard loudest > 0.0001 else { return peaks }
        return peaks.map { $0 / loudest }
    }
}
