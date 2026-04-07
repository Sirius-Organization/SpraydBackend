import Fluent

struct CreateArtImage: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(ArtImage.schema)
            .id()
            .field("art_item_id", .uuid, .required, .references(ArtItem.schema, "id", onDelete: .cascade))
            .field("image_path", .string, .required)
            .field("date", .datetime, .required)
            .field("timestamp", .double, .required)
            .field("user_id", .uuid, .required)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(ArtImage.schema).delete()
    }
}
