import Vapor
import Fluent

final class Ingredient: Model, Content {
    static let schema: String = "ingridient"
    
    @ID(key: "id")
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    init() {}
    
    init(id: UUID?, name: String) {
        self.id = id
        self.name = name
    }
}
