import Vapor

func routes(_ app: Application) throws {
    let api = app.grouped("api", "v1")
    let collections: [any RouteCollection] = [
        AuthController(),
        ArtItemController(),
        ArtistController(),
        CategoryController()
    ]
    for collection in collections {
        try api.register(collection: collection)
    }
}
