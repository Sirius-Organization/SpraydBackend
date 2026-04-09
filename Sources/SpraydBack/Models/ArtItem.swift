import Fluent
import Vapor

final class ArtItem: Model, Content, @unchecked Sendable {
    static let schema = "art_items"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Field(key: "description")
    var itemDescription: String

    @Children(for: \.$artItem)
    var images: [ArtImage]

    @Field(key: "location")
    var location: String

    @Field(key: "latitude")
    var latitude: Double

    @Field(key: "longitude")
    var longitude: Double

    @Field(key: "author")
    var author: String

    @Field(key: "state")
    var stateRawValue: String

    @Field(key: "category")
    var category: String

    @Field(key: "created_at")
    var createdAt: Date?

    init() {}

    init(
        id: UUID? = nil,
        name: String,
        itemDescription: String,
        location: String,
        latitude: Double,
        longitude: Double,
        author: String,
        state: ArtState = .new,
        category: String
    ) {
        self.id = id
        self.name = name
        self.itemDescription = itemDescription
        self.location = location
        self.latitude = latitude
        self.longitude = longitude
        self.author = author
        self.stateRawValue = state.rawValue
        self.category = category
    }

    var state: ArtState {
        get { ArtState(rawValue: stateRawValue) ?? .new }
        set { stateRawValue = newValue.rawValue }
    }
}
