import Fluent

struct CreateArtist: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(Artist.schema)
            .id()
            .field("name", .string, .required)
            .field("bio", .string, .required)
            .field("image_path", .string)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(Artist.schema).delete()
    }
}
