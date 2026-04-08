import Vapor
import Fluent

struct CategoryResponse: Content {
    var id: UUID?
    var name: String
    var slug: String
}

struct CreateCategoryRequest: Content {
    var name: String
    var slug: String
}

struct CategoryController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let categories = routes.grouped("categories")
        categories.get(use: index)
        categories.post(use: create)
    }

    func index(req: Request) async throws -> [CategoryResponse] {
        try await Category.query(on: req.db)
            .sort(\.$name)
            .all()
            .map { $0.asResponse() }
    }

    func create(req: Request) async throws -> CategoryResponse {
        let body = try req.content.decode(CreateCategoryRequest.self)
        let category = Category(
            name: body.name,
            slug: body.slug
        )
        try await category.save(on: req.db)
        return category.asResponse()
    }
}

extension Category {
    func asResponse() -> CategoryResponse {
        CategoryResponse(
            id: id,
            name: name,
            slug: slug
        )
    }
}
