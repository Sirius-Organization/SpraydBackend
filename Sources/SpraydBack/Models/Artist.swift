import Fluent
import Vapor

final class Artist: Model, Content, @unchecked Sendable {
    static let schema: String = "artist"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Field(key: "image_path")
    var imagePath: String?

    @Field(key: "bio")
    var bio: String

    // MARK: Init

    init() {}

    init(
        id: UUID? = nil,
        name: String,
        bio: String = "",
        imagePath: String? = nil
    ) {
        self.id = id
        self.name = name
        self.bio = bio
        self.imagePath = imagePath
    }
}
	
