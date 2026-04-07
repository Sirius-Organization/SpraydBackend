import Foundation

enum ArtState: String, Codable, CaseIterable {
    case new
    case exists
    case moderated
}
