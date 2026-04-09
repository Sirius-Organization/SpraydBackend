@testable import SpraydBack
import VaporTesting
import Fluent
import Vapor

// MARK: - App bootstrap

/// Boots the app in .testing mode (uses DB_TEST_NAME, auto-reverts on startup).
/// Create the test DB once (must be owned by the vapor user):
///   psql postgres -c "CREATE DATABASE spraydback_test OWNER vapor;"
func withTestApp(_ test: (Application) async throws -> Void) async throws {
    try await withApp(configure: configure, test)
}

// MARK: - Seed helpers

func seedUser(on db: any Database) async throws -> (user: User, token: UserToken) {
    let user = User(email: "test@example.com", passwordHash: try Bcrypt.hash("password"))
    try await user.save(on: db)
    let token = try UserToken.generate(for: user)
    try await token.save(on: db)
    return (user, token)
}

func seedArtItem(on db: any Database) async throws -> ArtItem {
    let item = ArtItem(
        name: "Test Mural",
        itemDescription: "A test piece",
        location: "Moscow",
        latitude: 55.75,
        longitude: 37.62,
        author: "Banksy",
        state: .new,
        category: "mural"
    )
    try await item.save(on: db)
    return item
}
