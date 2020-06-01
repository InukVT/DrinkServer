import Fluent
import FluentSQLiteDriver
import Vapor

//let machineLoop = EventLoopFuture

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    // Uncomment for psql
/*
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
*/
    // Register the database
    app
        .databases
        .use(.sqlite(.memory),
             as: .sqlite)
    
    // Create the tables.
    app
        .migrations
        .add(User.Migtation())
    
    app
        .migrations
        .add(Token.Migration())
    
    app
        .migrations
        .add(Machine.Migration())
    
    app
        .migrations
        .add(DrinkRecipe.Migration())
    
    app
        .migrations
        .add(Ingredient.Migration())
    
    app
        .migrations
        .add(MachineDrinkPivot.Migration())
    
    app
        .migrations
        .add(RecipePivot.Migration())
    
    // register routes
    try app
        .routes
        .register(collection: UserController())
    
    try app
        .routes
        .register(collection: MachineController())
    
    try app
        .routes
        .register(collection: DrinksController())
    
    
    
    app
        .http
        .server
        .configuration
        .hostname = "0.0.0.0"
    
    app
        .http
        .server
        .configuration
        .port = 80
    
    try routes(app)
    
    _ = app
    .autoMigrate()
}
