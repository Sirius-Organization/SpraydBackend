import Vapor
import Foundation

extension Request {
    /// Saves image data to `public/images/` and returns the stored filename.
    func saveImage(_ data: Data) throws -> String {
        guard let ext = data.imageFileExtension else {
            throw Abort(.unsupportedMediaType, reason: "Unsupported image type. Allowed: jpg, png, gif, webp")
        }
        let filename = "\(UUID().uuidString).\(ext)"
        let imagesDir = application.directory.publicDirectory + "images/"
        try FileManager.default.createDirectory(atPath: imagesDir, withIntermediateDirectories: true)
        try data.write(to: URL(fileURLWithPath: imagesDir + filename))
        return filename
    }
}
