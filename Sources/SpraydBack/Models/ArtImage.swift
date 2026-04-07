import Fluent
import Vapor
import Foundation

final class ArtImage: Model, @unchecked Sendable {
    static let schema = "art_images"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "art_item_id")
    var artItem: ArtItem

    @Field(key: "image_path")
    var imagePath: String

    @Field(key: "date")
    var date: Date

    @Field(key: "timestamp")
    var timeStamp: TimeInterval

    @Field(key: "user_id")
    var userId: UUID

    // MARK: Init

    init() {}

    init(
        id: UUID? = nil,
        artItemID: UUID,
        imagePath: String,
        date: Date = .now,
        timeStamp: TimeInterval = Date().timeIntervalSince1970,
        userId: UUID
    ) {
        self.id = id
        self.$artItem.id = artItemID
        self.imagePath = imagePath
        self.date = date
        self.timeStamp = timeStamp
        self.userId = userId
    }
}

// MARK: Data + Image Extension

extension Data {
    var imageFileExtension: String? {
        guard count >= 4 else { return nil }
        let bytes = [UInt8](prefix(12))
        switch true {
        case bytes.starts(with: [0xFF, 0xD8, 0xFF]):
            return "jpg"
        case bytes.starts(with: [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]):
            return "png"
        case bytes.starts(with: [0x47, 0x49, 0x46, 0x38]):
            return "gif"
        case bytes.starts(with: [0x52, 0x49, 0x46, 0x46]) && bytes[8...11].starts(with: [0x57, 0x45, 0x42, 0x50]):
            return "webp"
        default:
            return nil
        }
    }
}

// MARK: ArtImage + Response

struct ArtImageResponse: Content {
    var id: UUID?
    var artItemId: UUID
    var url: String
    var date: Date
    var timeStamp: TimeInterval
    var userId: UUID
}

extension ArtImage {
    func asResponse(req: Request) -> ArtImageResponse {
        let host = req.headers.first(name: .host) ?? "localhost:8080"
        let scheme = req.application.http.server.configuration.tlsConfiguration != nil ? "https" : "http"
        return ArtImageResponse(
            id: self.id,
            artItemId: self.$artItem.id,
            url: "\(scheme)://\(host)/images/\(self.imagePath)",
            date: self.date,
            timeStamp: self.timeStamp,
            userId: self.userId
        )
    }
}
