import Vapor
import Fluent
import Foundation

struct UpdateUserRequest: Content {
    var username: String?
    var bio: String?
    var avatar: Data?
    var currentPassword: String?
    var newPassword: String?
}

struct UserController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let users = routes.grouped("users")

        let tokenProtected = users.grouped(UserToken.authenticator(), UserToken.guardMiddleware())
        tokenProtected.group("me") { me in
            me.get(use: getCurrentUser)
            me.patch(use: update)
            me.delete(use: deleteAccount)
        }

        users.group(":id") { user in
            user.get(use: getUserById)
        }
    }

    // GET /users/:id
    func getUserById(req: Request) async throws -> User.Public {
        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid ID")
        }
        guard let user = try await User.find(id, on: req.db) else {
            throw Abort(.notFound)
        }
        return user.asPublic(req: req)
    }

    // GET /users/me  (requires Bearer token)
    func getCurrentUser(req: Request) async throws -> User.Public {
        let user = try req.auth.require(User.self)
        return user.asPublic(req: req)
    }

    // PATCH /users/me  (requires Bearer token)
    func update(req: Request) async throws -> User.Public {
        let user = try req.auth.require(User.self)
        let body = try req.content.decode(UpdateUserRequest.self)

        if let username = body.username {
            let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                throw Abort(.badRequest, reason: "Username cannot be empty")
            }
            if let existing = try await User.query(on: req.db)
                .filter(\.$username == trimmed)
                .first(),
               try existing.requireID() != user.requireID() {
                throw Abort(.conflict, reason: "Username already in use")
            }
            user.username = trimmed
        }

        if let bio = body.bio {
            user.bio = bio.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if let avatarData = body.avatar {
            if let oldAvatar = user.avatarPath,
               !oldAvatar.hasPrefix("http://"),
               !oldAvatar.hasPrefix("https://") {
                let filePath = req.application.directory.publicDirectory + "images/" + oldAvatar
                try? FileManager.default.removeItem(atPath: filePath)
            }
            user.avatarPath = try req.saveImage(avatarData)
        }

        switch (body.currentPassword, body.newPassword) {
        case (nil, nil):
            break
        case (let current?, let new?):
            guard try user.verify(password: current) else {
                throw Abort(.unauthorized, reason: "Current password is invalid")
            }
            guard validatePassword(new) else {
                throw Abort(.badRequest, reason: "Password must be at least 8 characters and contain at least 2 different character classes (uppercase, lowercase, digits, special)")
            }
            user.passwordHash = try Bcrypt.hash(new)
            let userId = try user.requireID()
            try await UserToken.query(on: req.db)
                .filter(\.$user.$id == userId)
                .delete()
        default:
            throw Abort(.badRequest, reason: "Provide both currentPassword and newPassword to change password")
        }

        try await user.save(on: req.db)
        return user.asPublic(req: req)
    }

    // DELETE /users/me  (requires Bearer token)
    func deleteAccount(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)

        if let avatarPath = user.avatarPath,
           !avatarPath.hasPrefix("http://"),
           !avatarPath.hasPrefix("https://") {
            let filePath = req.application.directory.publicDirectory + "images/" + avatarPath
            try? FileManager.default.removeItem(atPath: filePath)
        }

        try await user.delete(on: req.db)
        return .noContent
    }
}
