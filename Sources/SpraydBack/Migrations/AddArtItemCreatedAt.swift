import Fluent

struct AddArtItemCreatedAt: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(ArtItem.schema)
            .field("created_at", .datetime)
            .update()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(ArtItem.schema)
            .deleteField("created_at")
            .update()
    }
}
