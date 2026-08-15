import Foundation

public enum MediaTypes {
    public static let audioExtensions: Set<String> = ["wav", "aif", "aiff", "mp3", "m4a", "caf"]

    public static func isAudio(_ url: URL) -> Bool {
        audioExtensions.contains(url.pathExtension.lowercased())
    }

    public static func isLogicPackage(_ url: URL) -> Bool {
        url.pathExtension.lowercased() == "logicx"
    }
}
