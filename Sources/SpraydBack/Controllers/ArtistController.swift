import Vapor
import Fluent
import Foundation

struct ArtistResponse: Content {
    var id: UUID?
    var name: String
    var bio: String
    var imagePath: String?
}

struct CreateArtistRequest: Content {
    var name: String
    var bio: String
}

struct UploadAvatarRequest: Content {
    var img: Data
}

struct ArtistController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let artists = routes.grouped("artists")
        artists.get(use: index)
        artists.post(use: create)
        artists.group(":id") { artist in
            artist.post("avatar", use: uploadAvatar)
        }
    }

    // GET /artists
    func index(req: Request) async throws -> [ArtistResponse] {
        try await Artist.query(on: req.db).all().map { $0.asResponse(req: req) }
    }

    // POST /artists
    func create(req: Request) async throws -> ArtistResponse {
        let body = try req.content.decode(CreateArtistRequest.self)
        let artist = Artist(name: body.name, bio: body.bio)
        try await artist.save(on: req.db)
        return artist.asResponse(req: req)
    }

    // POST /artists/:id/avatar
    func uploadAvatar(req: Request) async throws -> ArtistResponse {
        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid ID")
        }
        guard let artist = try await Artist.find(id, on: req.db) else {
            throw Abort(.notFound)
        }
        let body = try req.content.decode(UploadAvatarRequest.self)
        let filename = try req.saveImage(body.img)
        artist.imagePath = filename
        try await artist.save(on: req.db)
        return artist.asResponse(req: req)
    }
}

extension Artist {
    func asResponse(req: Request) -> ArtistResponse {
        var imageUrl: String? = nil
        if let path = imagePath {
            let host = req.headers.first(name: .host) ?? "localhost:8080"
            let scheme = req.application.http.server.configuration.tlsConfiguration != nil ? "https" : "http"
            imageUrl = "\(scheme)://\(host)/images/\(path)"
        }
        return ArtistResponse(id: id, name: name, bio: bio, imagePath: imageUrl)
    }
}
