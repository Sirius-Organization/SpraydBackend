import Fluent

struct CreateArtItem: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(ArtItem.schema)
            .id()
            .field("name", .string, .required)
            .field("description", .string, .required)
            .field("location", .string, .required)
            .field("latitude", .double, .required)
            .field("longitude", .double, .required)
            .field("author", .string, .required)
            .field("state", .string, .required)
            .field("category", .string, .required)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(ArtItem.schema).delete()
    }
}
