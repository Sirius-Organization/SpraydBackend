import Vapor
import NIOSSL

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    let certPath = "/etc/letsencrypt/live/sprayd.ru/fullchain.pem"
    let keyPath = "/etc/letsencrypt/live/sprayd.ru/privkey.pem"

    app.http.server.configuration.tlsConfiguration = .makeServerConfiguration(
        certificateChain: try NIOSSLCertificate.fromPEMFile(certPath).map { .certificate($0) },
        privateKey: .privateKey(try NIOSSLPrivateKey(file: keyPath, format: .pem))
    )

    app.http.server.configuration.port = 443

    // register routes
    try routes(app)
}
