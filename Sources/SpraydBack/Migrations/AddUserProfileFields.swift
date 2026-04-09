import Fluent

struct AddUserProfileFields: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(User.schema)
            .field("username", .string)
            .field("bio", .string)
            .field("avatar_path", .string)
            .field("posted", .array(of: .uuid))
            .field("visited", .array(of: .uuid))
            .field("liked", .array(of: .uuid))
            .update()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(User.schema)
            .deleteField("username")
            .deleteField("bio")
            .deleteField("avatar_path")
            .deleteField("posted")
            .deleteField("visited")
            .deleteField("liked")
            .update()
    }
}
