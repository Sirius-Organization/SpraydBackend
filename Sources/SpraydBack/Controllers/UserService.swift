import Vapor
import Fluent
import Foundation

private func validateNewPassword(_ password: String) -> Bool {
    guard password.count >= 8 else { return false }
    var classes = 0
    if password.contains(where: { $0.isUppercase }) { classes += 1 }
    if password.contains(where: { $0.isLowercase }) { classes += 1 }
    if password.contains(where: { $0.isNumber }) { classes += 1 }
    if password.contains(where: { !$0.isLetter && !$0.isNumber }) { classes += 1 }
    return classes >= 2
}

struct UpdateUsernameRequest: Content {
    var username: String
}

struct UpdateBioRequest: Content {
    var bio: String
}

struct UpdateUserAvatarRequest: Content {
    var img: Data
}

struct ChangePasswordRequest: Content {
    var currentPassword: String
    var newPassword: String
}

struct UserService: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let users = routes.grouped("users")

        let tokenProtected = users.grouped(UserToken.authenticator(), UserToken.guardMiddleware())
        tokenProtected.group("me") { me in
            me.get(use: getCurrentUser)
            me.patch("username", use: changeUsername)
            me.patch("bio", use: changeBio)
            me.post("avatar", use: changeAvatar)
            me.patch("password", use: changePassword)
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

    // GET /users/me (requires Bearer token)
    func getCurrentUser(req: Request) async throws -> User.Public {
        let user = try req.auth.require(User.self)
        return user.asPublic(req: req)
    }

    // PATCH /users/me/username (requires Bearer token)
    func changeUsername(req: Request) async throws -> User.Public {
        let user = try req.auth.require(User.self)
        let body = try req.content.decode(UpdateUsernameRequest.self)
        let username = body.username.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !username.isEmpty else {
            throw Abort(.badRequest, reason: "Username is required")
        }

        if let existing = try await User.query(on: req.db)
            .filter(\.$username == username)
            .first(),
           try existing.requireID() != user.requireID() {
            throw Abort(.conflict, reason: "Username already in use")
        }

        user.username = username
        try await user.save(on: req.db)
        return user.asPublic(req: req)
    }

    // PATCH /users/me/bio (requires Bearer token)
    func changeBio(req: Request) async throws -> User.Public {
        let user = try req.auth.require(User.self)
        let body = try req.content.decode(UpdateBioRequest.self)
        user.bio = body.bio.trimmingCharacters(in: .whitespacesAndNewlines)
        try await user.save(on: req.db)
        return user.asPublic(req: req)
    }

    // POST /users/me/avatar (requires Bearer token)
    func changeAvatar(req: Request) async throws -> User.Public {
        let user = try req.auth.require(User.self)
        let body = try req.content.decode(UpdateUserAvatarRequest.self)
        let filename = try req.saveImage(body.img)

        if let oldAvatar = user.avatarPath,
           !oldAvatar.hasPrefix("http://"),
           !oldAvatar.hasPrefix("https://") {
            let filePath = req.application.directory.publicDirectory + "images/" + oldAvatar
            try? FileManager.default.removeItem(atPath: filePath)
        }

        user.avatarPath = filename
        try await user.save(on: req.db)
        return user.asPublic(req: req)
    }

    // PATCH /users/me/password (requires Bearer token)
    func changePassword(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        let body = try req.content.decode(ChangePasswordRequest.self)

        guard try user.verify(password: body.currentPassword) else {
            throw Abort(.unauthorized, reason: "Current password is invalid")
        }
        guard validateNewPassword(body.newPassword) else {
            throw Abort(
                .badRequest,
                reason: "Password must be at least 8 characters and contain at least 2 different character classes (uppercase, lowercase, digits, special)"
            )
        }

        user.passwordHash = try Bcrypt.hash(body.newPassword)
        try await user.save(on: req.db)

        let userId = try user.requireID()
        try await UserToken.query(on: req.db)
            .filter(\.$user.$id == userId)
            .delete()

        return .ok
    }

    // DELETE /users/me (requires Bearer token)
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
