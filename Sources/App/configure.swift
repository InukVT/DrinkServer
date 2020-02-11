import Fluent
import FluentPostgresDriver
import Vapor

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    let hostname: String
    #if os(Linux)
    hostname = "psql"
    #else
    hostname = "localhost"
    #endif
    
    app.databases.use(.postgres(
        hostname: Environment.get("POSTGRES_HOST") ?? hostname,
        username: Environment.get("POSTGRES_USER") ?? "vapor_username",
        password: Environment.get("POSTGRES_PASSWORD") ?? "vapor_password",
        database: Environment.get("POSTGRES_DB") ?? "vapor_database"
    ), as: .psql)

    app.migrations.add(CreateTodo())
    app.migrations.add(User.Migtation())
    // register routes
    try routes(app)
}
