import Vapor
import Fluent

private func validatePassword(_ password: String) -> Bool {
    guard password.count >= 8 else { return false }
    var classes = 0
    if password.contains(where: { $0.isUppercase }) { classes += 1 }
    if password.contains(where: { $0.isLowercase }) { classes += 1 }
    if password.contains(where: { $0.isNumber }) { classes += 1 }
    if password.contains(where: { !$0.isLetter && !$0.isNumber }) { classes += 1 }
    return classes >= 2
}

struct AuthController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let auth = routes.grouped("auth")
        auth.post("register", use: register)

        let basicAuth = auth.grouped(User.authenticator(), User.guardMiddleware())
        basicAuth.post("login", use: login)
    }

    // POST /auth/register
    func register(req: Request) async throws -> Response {
        struct RegisterRequest: Content {
            var email: String
            var password: String
        }
        let body = try req.content.decode(RegisterRequest.self)

        guard !body.email.isEmpty else {
            throw Abort(.badRequest, reason: "Email is required")
        }
        guard validatePassword(body.password) else {
            throw Abort(.badRequest, reason: "Password must be at least 8 characters and contain at least 2 different character classes (uppercase, lowercase, digits, special)")
        }

        let existing = try await User.query(on: req.db)
            .filter(\.$email == body.email)
            .first()
        guard existing == nil else {
            throw Abort(.conflict, reason: "Email already registered")
        }

        let hash = try Bcrypt.hash(body.password)
        let user = User(email: body.email, passwordHash: hash)
        try await user.save(on: req.db)

        return try await user.asPublic().encodeResponse(status: .created, for: req)
    }

    // POST /auth/login  (Basic Auth: email:password)
    func login(req: Request) async throws -> UserTokenResponse {
        let user = try req.auth.require(User.self)
        let token = try UserToken.generate(for: user)
        try await token.save(on: req.db)
        return UserTokenResponse(token: token.value)
    }
}
