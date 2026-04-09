import Vapor
import Fluent

final class User: Model, @unchecked Sendable {
    static let schema = "users"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "email")
    var email: String

    @Field(key: "password_hash")
    var passwordHash: String

    @OptionalField(key: "username")
    var username: String?

    @OptionalField(key: "bio")
    var bio: String?

    @OptionalField(key: "avatar_path")
    var avatarPath: String?

    @OptionalField(key: "posted")
    var posted: [UUID]?

    @OptionalField(key: "visited")
    var visited: [UUID]?

    @OptionalField(key: "liked")
    var liked: [UUID]?

    init() {}

    init(
        id: UUID? = nil,
        email: String,
        passwordHash: String,
        username: String? = nil,
        bio: String? = nil,
        avatarPath: String? = nil,
        posted: [UUID]? = nil,
        visited: [UUID]? = nil,
        liked: [UUID]? = nil
    ) {
        self.id = id
        self.email = email
        self.passwordHash = passwordHash
        self.username = username
        self.bio = bio
        self.avatarPath = avatarPath
        self.posted = posted
        self.visited = visited
        self.liked = liked
    }

    struct Public: Content {
        var id: UUID?
        var email: String
        var username: String
        var bio: String
        var avatar: String?
        var posted: [UUID]
        var visited: [UUID]
        var liked: [UUID]
    }

    func asPublic(req: Request? = nil) -> Public {
        let avatarUrl: String?
        if let avatarPath {
            if avatarPath.hasPrefix("http://") || avatarPath.hasPrefix("https://") {
                avatarUrl = avatarPath
            } else if let req {
                let host = req.headers.first(name: .host) ?? "localhost:8080"
                let scheme = req.application.http.server.configuration.tlsConfiguration != nil ? "https" : "http"
                avatarUrl = "\(scheme)://\(host)/images/\(avatarPath)"
            } else {
                avatarUrl = avatarPath
            }
        } else {
            avatarUrl = nil
        }

        return Public(
            id: id,
            email: email,
            username: username ?? email.components(separatedBy: "@").first ?? email,
            bio: bio ?? "",
            avatar: avatarUrl,
            posted: posted ?? [],
            visited: visited ?? [],
            liked: liked ?? []
        )
    }
}

extension User: ModelAuthenticatable {
    static let usernameKey: KeyPath<User, FieldProperty<User, String>> = \User.$email
    static let passwordHashKey: KeyPath<User, FieldProperty<User, String>> = \User.$passwordHash

    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.passwordHash)
    }
}
