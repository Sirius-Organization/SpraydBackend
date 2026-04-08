import Vapor
import Fluent

final class UserToken: Model, @unchecked Sendable {
    static let schema = "user_tokens"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "value")
    var value: String

    @Parent(key: "user_id")
    var user: User

    init() {}

    init(id: UUID? = nil, value: String, userID: User.IDValue) {
        self.id = id
        self.value = value
        self.$user.id = userID
    }

    static func generate(for user: User) throws -> UserToken {
        let value = [UInt8].random(count: 32).hex
        return try UserToken(value: value, userID: user.requireID())
    }
}

extension UserToken: ModelTokenAuthenticatable {
    static let valueKey: KeyPath<UserToken, FieldProperty<UserToken, String>> = \UserToken.$value
    static let userKey: KeyPath<UserToken, ParentProperty<UserToken, User>> = \UserToken.$user

    var isValid: Bool { true }
}

struct UserTokenResponse: Content {
    var token: String
}
