import Fluent
import Vapor

final class Category: Model, Content, @unchecked Sendable {
    static let schema: String = "category"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Field(key: "slug")
    var slug: String

    init() {}

    init(
        id: UUID? = nil,
        name: String,
        slug: String
    ) {
        self.id = id
        self.name = name
        self.slug = slug
    }
}
