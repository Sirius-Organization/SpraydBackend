import Vapor
import NIOSSL
import Fluent
import FluentPostgresDriver

// configures your application
public func configure(_ app: Application) async throws {
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    let certPath = "/etc/letsencrypt/live/sprayd.ru/fullchain.pem"
    let keyPath = "/etc/letsencrypt/live/sprayd.ru/privkey.pem"

    app.http.server.configuration.tlsConfiguration = .makeServerConfiguration(
        certificateChain: try NIOSSLCertificate.fromPEMFile(certPath).map { .certificate($0) },
        privateKey: .privateKey(try NIOSSLPrivateKey(file: keyPath, format: .pem))
    )
    app.http.server.configuration.port = 443

    app.routes.defaultMaxBodySize = "10mb"

    // configure PostgreSQL
    let dbHost = Environment.get("DB_HOST") ?? "localhost"
    let dbPort = Int(Environment.get("DB_PORT") ?? "5432") ?? 5432
    let dbUser = Environment.get("DB_USERNAME") ?? "vapor"
    let dbPass = Environment.get("DB_PASSWORD") ?? ""
    let dbName = app.environment == .testing
        ? (Environment.get("DB_TEST_NAME") ?? "spraydback_test")
        : (Environment.get("DB_NAME") ?? "spraydback")

    app.databases.use(
        .postgres(configuration: SQLPostgresConfiguration(
            hostname: dbHost,
            port: dbPort,
            username: dbUser,
            password: dbPass,
            database: dbName,
            tls: .disable
        )),
        as: .psql
    )

    // register migrations
    app.migrations.add(CreateArtItem())
    app.migrations.add(CreateArtImage())
    app.migrations.add(CreateArtist())
    app.migrations.add(CreateCategory())
    app.migrations.add(CreateUser())
    app.migrations.add(CreateUserToken())

    // wipe and recreate schema on each test run for isolation
    if app.environment == .testing {
        try await app.autoRevert()
    }
    try await app.autoMigrate()

    // register routes
    try routes(app)
}
