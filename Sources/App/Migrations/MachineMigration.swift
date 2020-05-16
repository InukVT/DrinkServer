import Fluent

extension Machine {
    struct Migration: Fluent.Migration {
        let name = Machine.schema
        
        func prepare(on database: Database) -> EventLoopFuture<Void> {
            database.schema(name)
                .field("id", .uuid, .identifier(auto: true))
                .field("name", .string, .required)
                .create()
        }
        
        func revert(on database: Database) -> EventLoopFuture<Void> {
            database.schema(name).delete()
        }
    }
}
