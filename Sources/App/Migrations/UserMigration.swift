import Fluent

extension User {
    struct Migtation: Fluent.Migration {
        let name = User.schema
        
        func prepare(on database: Database) -> EventLoopFuture<Void> {
            database.schema(name)
                .field("id", .int, .identifier(auto: true))
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
