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

    init() {}

    init(id: UUID? = nil, email: String, passwordHash: String) {
        self.id = id
        self.email = email
        self.passwordHash = passwordHash
    }

    struct Public: Content {
        var id: UUID?
        var email: String
    }

    func asPublic() -> Public {
        Public(id: id, email: email)
    }
}

extension User: ModelAuthenticatable {
    static let usernameKey: KeyPath<User, FieldProperty<User, String>> = \User.$email
    static let passwordHashKey: KeyPath<User, FieldProperty<User, String>> = \User.$passwordHash

    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.passwordHash)
    }
}
