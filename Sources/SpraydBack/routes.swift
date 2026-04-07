import Vapor

func routes(_ app: Application) throws {
    try app.register(collection: ArtItemController())
    try app.register(collection: ArtistController())
}
