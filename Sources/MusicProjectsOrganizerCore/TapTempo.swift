import Foundation

public struct TapTempo: Equatable, Sendable {
    public var taps: [TimeInterval] = []
    public var timeout: TimeInterval
    public var maxTaps: Int

    public init(timeout: TimeInterval = 2.0, maxTaps: Int = 8) {
        self.timeout = timeout
        self.maxTaps = maxTaps
    }

    public var tapCount: Int { taps.count }

    public mutating func tap(at time: TimeInterval) -> Int? {
        if let last = taps.last, time - last > timeout {
            taps = []
        }
        taps.append(time)
        if taps.count > maxTaps {
            taps.removeFirst(taps.count - maxTaps)
        }
        return bpm
    }

    public mutating func reset() {
        taps = []
    }

    public var bpm: Int? {
        guard taps.count >= 2 else { return nil }
        let intervals = zip(taps.dropFirst(), taps).map { $0 - $1 }
        let average = intervals.reduce(0, +) / Double(intervals.count)
        guard average > 0 else { return nil }
        let value = Int((60.0 / average).rounded())
        return (20...300).contains(value) ? value : nil
    }
}
