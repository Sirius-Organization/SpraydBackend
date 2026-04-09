import Vapor
import Fluent
import Foundation

struct CreateArtItemRequest: Content {
    var name: String
    var itemDescription: String
    var location: String
    var latitude: Double
    var longitude: Double
    var author: String
    var state: String
    var category: String
}

struct UploadArtImageRequest: Content {
    var img: Data
}

struct AddImageUrlRequest: Content {
    var url: String
}

struct ArtItemListResponse: Content {
    var id: UUID?
    var name: String
    var itemDescription: String
    var location: String
    var latitude: Double
    var longitude: Double
    var author: String
    var state: String
    var category: String
    var firstImageUrl: String?

    init(item: ArtItem, req: Request) {
        self.id = item.id
        self.name = item.name
        self.itemDescription = item.itemDescription
        self.location = item.location
        self.latitude = item.latitude
        self.longitude = item.longitude
        self.author = item.author
        self.state = item.stateRawValue
        self.category = item.category
        self.firstImageUrl = item.$images.value?.first?.asResponse(req: req).url
    }
}

struct ArtItemResponse: Content {
    var id: UUID?
    var name: String
    var itemDescription: String
    var location: String
    var latitude: Double
    var longitude: Double
    var author: String
    var state: String
    var category: String
    var images: [ArtImageResponse]

    init(item: ArtItem, req: Request) {
        self.id = item.id
        self.name = item.name
        self.itemDescription = item.itemDescription
        self.location = item.location
        self.latitude = item.latitude
        self.longitude = item.longitude
        self.author = item.author
        self.state = item.stateRawValue
        self.category = item.category
        self.images = item.$images.value?.map { $0.asResponse(req: req) } ?? []
    }
}

struct ArtItemController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let artItems = routes.grouped("art-items")
        artItems.get(use: index)
        artItems.get("in-box", use: inBox)
        artItems.get("search", use: search)
        artItems.post(use: create)
        artItems.group(":id") { item in
            item.get(use: show)
        }

        let tokenProtected = artItems.grouped(UserToken.authenticator(), UserToken.guardMiddleware())
        tokenProtected.group(":id") { item in
            item.post("images", use: uploadImage)
            item.post("image-url", use: addImageUrl)
            item.delete(use: deleteItem)
        }
    }

    // GET /art-items
    func index(req: Request) async throws -> [ArtItemListResponse] {
        let items = try await ArtItem.query(on: req.db).with(\.$images).all()
        return items.map { ArtItemListResponse(item: $0, req: req) }
    }

    // GET /art-items/in-box?bbox=minLng,minLat,maxLng,maxLat
    func inBox(req: Request) async throws -> [ArtItemListResponse] {
        guard let bbox = req.query[String.self, at: "bbox"] else {
            throw Abort(.badRequest, reason: "Required query param: bbox (minLng,minLat,maxLng,maxLat)")
        }
        let parts = bbox.split(separator: ",").compactMap { Double($0) }
        guard parts.count == 4 else {
            throw Abort(.badRequest, reason: "bbox must have 4 comma-separated values: minLng,minLat,maxLng,maxLat")
        }
        let minLng = parts[0]
        let minLat = parts[1]
        let maxLng = parts[2]
        let maxLat = parts[3]
        let items = try await ArtItem.query(on: req.db)
            .filter(\.$latitude >= minLat)
            .filter(\.$latitude <= maxLat)
            .filter(\.$longitude >= minLng)
            .filter(\.$longitude <= maxLng)
            .with(\.$images)
            .all()
        return items.map { ArtItemListResponse(item: $0, req: req) }
    }

    // GET /art-items/search?q=<query>
    func search(req: Request) async throws -> [ArtItemListResponse] {
        guard let query = req.query[String.self, at: "q"], !query.isEmpty else {
            throw Abort(.badRequest, reason: "Required query param: q")
        }
        let pattern = "%\(query)%"
        let items = try await ArtItem.query(on: req.db)
            .group(.or) { group in
                group.filter(\.$name, .custom("ILIKE"), pattern)
                group.filter(\.$itemDescription, .custom("ILIKE"), pattern)
            }
            .with(\.$images)
            .all()
        return items.map { ArtItemListResponse(item: $0, req: req) }
    }

    // GET /art-items/:id
    func show(req: Request) async throws -> ArtItemResponse {
        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid ID")
        }
        guard let item = try await ArtItem.query(on: req.db)
            .filter(\.$id == id)
            .with(\.$images)
            .first()
        else {
            throw Abort(.notFound)
        }
        return ArtItemResponse(item: item, req: req)
    }

    // POST /art-items
    func create(req: Request) async throws -> ArtItemListResponse {
        let body = try req.content.decode(CreateArtItemRequest.self)
        guard let state = ArtState(rawValue: body.state) else {
            throw Abort(.badRequest, reason: "Invalid state value")
        }
        let item = ArtItem(
            name: body.name,
            itemDescription: body.itemDescription,
            location: body.location,
            latitude: body.latitude,
            longitude: body.longitude,
            author: body.author,
            state: state,
            category: body.category
        )
        try await item.save(on: req.db)
        return ArtItemListResponse(item: item, req: req)
    }

    // POST /art-items/:id/image-url  (requires Bearer token)
    func addImageUrl(req: Request) async throws -> ArtImageResponse {
        let user = try req.auth.require(User.self)
        let userId = try user.requireID()
        guard let itemId = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid ID")
        }
        guard try await ArtItem.find(itemId, on: req.db) != nil else {
            throw Abort(.notFound, reason: "ArtItem not found")
        }
        let body = try req.content.decode(AddImageUrlRequest.self)
        guard body.url.hasPrefix("http://") || body.url.hasPrefix("https://"),
              URL(string: body.url) != nil else {
            throw Abort(.badRequest, reason: "url must be a valid http/https URL")
        }
        let image = ArtImage(artItemID: itemId, imagePath: body.url, userId: userId)
        try await image.save(on: req.db)
        return image.asResponse(req: req)
    }

    // DELETE /art-items/:id  (requires Bearer token)
    func deleteItem(req: Request) async throws -> HTTPStatus {
        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid ID")
        }
        guard let item = try await ArtItem.query(on: req.db)
            .filter(\.$id == id)
            .with(\.$images)
            .first()
        else {
            throw Abort(.notFound)
        }
        let imagesDir = req.application.directory.publicDirectory + "images/"
        for image in item.images {
            guard !image.imagePath.hasPrefix("http://"), !image.imagePath.hasPrefix("https://") else { continue }
            let filePath = imagesDir + image.imagePath
            try? FileManager.default.removeItem(atPath: filePath)
        }
        try await item.delete(on: req.db)
        return .noContent
    }

    // POST /art-items/:id/images  (requires Bearer token)
    func uploadImage(req: Request) async throws -> ArtImageResponse {
        let user = try req.auth.require(User.self)
        let userId = try user.requireID()
        guard let itemId = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid ID")
        }
        guard try await ArtItem.find(itemId, on: req.db) != nil else {
            throw Abort(.notFound, reason: "ArtItem not found")
        }
        let body = try req.content.decode(UploadArtImageRequest.self)
        let filename = try req.saveImage(body.img)
        let image = ArtImage(
            artItemID: itemId,
            imagePath: filename,
            userId: userId
        )
        try await image.save(on: req.db)
        return image.asResponse(req: req)
    }
}
