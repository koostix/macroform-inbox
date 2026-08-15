import SwiftUI

struct WaveformView: View {
    let samples: [Float]
    let progress: Double
    let currentTime: TimeInterval
    let duration: TimeInterval
    let onSeek: (Double) -> Void
    let onSeekEnd: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                let width = max(geo.size.width, 1)
                Canvas { context, size in
                    draw(in: &context, size: size)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            onSeek(min(max(value.location.x / width, 0), 1))
                        }
                        .onEnded { _ in
                            onSeekEnd()
                        }
                )
            }
            .frame(height: 72)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 6))

            HStack {
                Text(Self.clock(currentTime))
                Spacer()
                Text(Self.clock(duration))
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(Theme.muted)
        }
    }

    private func draw(in context: inout GraphicsContext, size: CGSize) {
        let midY = size.height / 2
        let playX = size.width * progress

        if samples.isEmpty {
            var baseline = Path()
            baseline.move(to: CGPoint(x: 0, y: midY))
            baseline.addLine(to: CGPoint(x: size.width, y: midY))
            context.stroke(baseline, with: .color(Theme.muted.opacity(0.35)), lineWidth: 1)
        } else {
            let barWidth = size.width / CGFloat(samples.count)
            for (index, sample) in samples.enumerated() {
                let x = CGFloat(index) * barWidth
                let amplitude = CGFloat(max(sample, 0.035)) * (size.height * 0.46)
                let rect = CGRect(
                    x: x,
                    y: midY - amplitude,
                    width: max(barWidth * 0.72, 0.6),
                    height: amplitude * 2
                )
                let played = x <= playX
                context.fill(
                    Path(roundedRect: rect, cornerRadius: 0.6),
                    with: .color(played ? Theme.accent : Theme.muted.opacity(0.38))
                )
            }
        }

        var playhead = Path()
        playhead.move(to: CGPoint(x: playX, y: 2))
        playhead.addLine(to: CGPoint(x: playX, y: size.height - 2))
        context.stroke(playhead, with: .color(.white.opacity(0.9)), lineWidth: 1)
    }

    static func clock(_ time: TimeInterval) -> String {
        let total = max(Int(time.rounded(.down)), 0)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
}
