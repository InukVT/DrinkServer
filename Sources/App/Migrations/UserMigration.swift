import Fluent

extension User {
    struct Migtation: Fluent.Migration {
        let name = User.schema
        
        func prepare(on database: Database) -> EventLoopFuture<Void> {
            database.schema(name)
                .field("id", .uuid, .identifier(auto: true))
                .field("mail", .string, .required)
                .field("password", .string, .required)
                .field("rights", .uint64, .required)
                .create()
        }
        func revert(on database: Database) -> EventLoopFuture<Void> {
            database.schema(name).delete()
        }
    }
}

extension Token {
    struct Migration: Fluent.Migration {
        let name = Token.schema
        
        func prepare(on database: Database) -> EventLoopFuture<Void> {
            database.schema(name)
                .field("id", .uuid, .identifier(auto: true))
                .field("token", .string, .required)
                .field("user_id", .int, .required)
                .unique(on: "token")
                .create()
        }
        
        func revert(on database: Database) -> EventLoopFuture<Void> {
            database.schema(name).delete()
        }
    }
}
