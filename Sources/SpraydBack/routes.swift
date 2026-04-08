import Vapor

func routes(_ app: Application) throws {
    try app.register(collection: AuthController())
    try app.register(collection: ArtItemController())
    try app.register(collection: ArtistController())
    try app.register(collection: CategoryController())
}
