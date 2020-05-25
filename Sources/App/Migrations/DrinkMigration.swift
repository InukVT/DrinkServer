import Fluent

extension DrinkRecipe {
    struct Migration: Fluent.Migration {
        let name = DrinkRecipe.schema
        
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

extension RecipePivot {
    struct Migration: Fluent.Migration {
        let name = RecipePivot.schema
        
        func prepare(on database: Database) -> EventLoopFuture<Void> {
            database.schema(name)
                .field("id", .uuid, .identifier(auto: true))
                .field("recipe-id", .uuid, .required)
                .field("ingredient-id", .uuid, .required)
                .create()
        }
        
        func revert(on database: Database) -> EventLoopFuture<Void> {
            database.schema(name).delete()
        }
    }
}
