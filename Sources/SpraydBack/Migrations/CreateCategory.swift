import Fluent

struct CreateCategory: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(Category.schema)
            .id()
            .field("name", .string, .required)
            .field("slug", .string, .required)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(Category.schema).delete()
    }
}
