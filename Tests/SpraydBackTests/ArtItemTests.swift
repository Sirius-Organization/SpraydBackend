@testable import SpraydBack
import VaporTesting
import Testing

@Suite("ArtItem API", .serialized)
struct ArtItemTests {

    @Test("GET /art-items returns empty list on fresh DB")
    func listEmpty() async throws {
        try await withTestApp { app in
            try await app.testing().test(.GET, "api/v1/art-items",
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                    let items = try res.content.decode([ArtItemListResponse].self)
                    #expect(items.isEmpty)
                }
            )
        }
    }

    @Test("POST /art-items creates an item")
    func createItem() async throws {
        try await withTestApp { app in
            let body = CreateArtItemRequest(
                name: "Graffiti Wall",
                itemDescription: "Colorful mural",
                location: "Saint Petersburg",
                latitude: 59.93,
                longitude: 30.32,
                author: "Unknown",
                state: "new",
                category: "graffiti"
            )
            try await app.testing().test(.POST, "api/v1/art-items",
                beforeRequest: { req async throws in
                    try req.content.encode(body)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                    let created = try res.content.decode(ArtItemListResponse.self)
                    #expect(created.id != nil)
                    #expect(created.name == "Graffiti Wall")
                    #expect(created.state == "new")
                }
            )
        }
    }

    @Test("DELETE /art-items/:id returns 401 without token")
    func deleteRequiresAuth() async throws {
        try await withTestApp { app in
            let item = try await seedArtItem(on: app.db)
            let id = try item.requireID()

            try await app.testing().test(.DELETE, "api/v1/art-items/\(id)",
                afterResponse: { res async throws in
                    #expect(res.status == .unauthorized)
                }
            )
        }
    }

    @Test("DELETE /art-items/:id removes item and returns 204")
    func deleteItem() async throws {
        try await withTestApp { app in
            let item = try await seedArtItem(on: app.db)
            let id = try item.requireID()
            let (_, token) = try await seedUser(on: app.db)

            try await app.testing().test(.DELETE, "api/v1/art-items/\(id)",
                beforeRequest: { req async throws in
                    req.headers.bearerAuthorization = .init(token: token.value)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .noContent)
                }
            )

            let found = try await ArtItem.find(id, on: app.db)
            #expect(found == nil)
        }
    }

    @Test("DELETE /art-items/:id returns 404 for unknown id")
    func deleteNotFound() async throws {
        try await withTestApp { app in
            let (_, token) = try await seedUser(on: app.db)

            try await app.testing().test(.DELETE, "api/v1/art-items/\(UUID())",
                beforeRequest: { req async throws in
                    req.headers.bearerAuthorization = .init(token: token.value)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .notFound)
                }
            )
        }
    }
}
