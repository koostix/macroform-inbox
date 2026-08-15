import Foundation

public enum MediaTypes {
    public static let audioExtensions: Set<String> = ["wav", "aif", "aiff", "mp3", "m4a", "caf"]
    public static let imageExtensions: Set<String> = ["jpg", "jpeg", "png", "webp", "heic", "heif", "tif", "tiff", "gif", "bmp"]

    public static func isAudio(_ url: URL) -> Bool {
        audioExtensions.contains(url.pathExtension.lowercased())
    }

    public static func isImage(_ url: URL) -> Bool {
        imageExtensions.contains(url.pathExtension.lowercased())
    }

    public static func isLogicPackage(_ url: URL) -> Bool {
        url.pathExtension.lowercased() == "logicx"
    }
}
