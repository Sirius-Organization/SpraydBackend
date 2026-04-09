@testable import SpraydBack
import VaporTesting
import Testing
import Fluent

@Suite("UserService API", .serialized)
struct UserServiceTests {

    @Test("GET /users/me returns current user for valid token")
    func getCurrentUser() async throws {
        try await withTestApp { app in
            let (user, token) = try await seedUser(on: app.db)
            let userId = try user.requireID()

            try await app.testing().test(.GET, "api/v1/users/me",
                beforeRequest: { req async throws in
                    req.headers.bearerAuthorization = .init(token: token.value)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                    let payload = try res.content.decode(User.Public.self)
                    #expect(payload.id == userId)
                    #expect(payload.email == "test@example.com")
                    #expect(payload.username == "test")
                }
            )
        }
    }

    @Test("GET /users/:id returns user profile with defaults")
    func getUserById() async throws {
        try await withTestApp { app in
            let (user, _) = try await seedUser(on: app.db)
            let userId = try user.requireID()

            try await app.testing().test(.GET, "api/v1/users/\(userId)",
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                    let payload = try res.content.decode(User.Public.self)
                    #expect(payload.id == userId)
                    #expect(payload.email == "test@example.com")
                    #expect(payload.username == "test")
                    #expect(payload.bio == "")
                    #expect(payload.avatar == nil)
                    #expect(payload.posted.isEmpty)
                    #expect(payload.visited.isEmpty)
                    #expect(payload.liked.isEmpty)
                }
            )
        }
    }

    @Test("PATCH /users/me/username updates current user")
    func changeUsername() async throws {
        try await withTestApp { app in
            let (_, token) = try await seedUser(on: app.db)

            try await app.testing().test(.PATCH, "api/v1/users/me/username",
                beforeRequest: { req async throws in
                    req.headers.bearerAuthorization = .init(token: token.value)
                    try req.content.encode(UpdateUsernameRequest(username: "new_name"))
                },
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                    let payload = try res.content.decode(User.Public.self)
                    #expect(payload.username == "new_name")
                }
            )
        }
    }

    @Test("PATCH /users/me/bio updates bio")
    func changeBio() async throws {
        try await withTestApp { app in
            let (_, token) = try await seedUser(on: app.db)

            try await app.testing().test(.PATCH, "api/v1/users/me/bio",
                beforeRequest: { req async throws in
                    req.headers.bearerAuthorization = .init(token: token.value)
                    try req.content.encode(UpdateBioRequest(bio: "Street art lover"))
                },
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                    let payload = try res.content.decode(User.Public.self)
                    #expect(payload.bio == "Street art lover")
                }
            )
        }
    }

    @Test("PATCH /users/me/password changes password and revokes tokens")
    func changePassword() async throws {
        try await withTestApp { app in
            let (user, token) = try await seedUser(on: app.db)
            let userId = try user.requireID()

            try await app.testing().test(.PATCH, "api/v1/users/me/password",
                beforeRequest: { req async throws in
                    req.headers.bearerAuthorization = .init(token: token.value)
                    try req.content.encode(ChangePasswordRequest(
                        currentPassword: "password",
                        newPassword: "Newpass123!"
                    ))
                },
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                }
            )

            let updated = try await User.find(userId, on: app.db)
            #expect(updated != nil)
            let isValid = try updated?.verify(password: "Newpass123!")
            #expect(isValid == true)

            let remainingTokens = try await UserToken.query(on: app.db)
                .filter(\.$user.$id == userId)
                .count()
            #expect(remainingTokens == 0)
        }
    }

    @Test("DELETE /users/me removes account")
    func deleteAccount() async throws {
        try await withTestApp { app in
            let (user, token) = try await seedUser(on: app.db)
            let userId = try user.requireID()

            try await app.testing().test(.DELETE, "api/v1/users/me",
                beforeRequest: { req async throws in
                    req.headers.bearerAuthorization = .init(token: token.value)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .noContent)
                }
            )

            let found = try await User.find(userId, on: app.db)
            #expect(found == nil)
        }
    }
}
