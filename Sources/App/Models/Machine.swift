import Vapor
import Fluent

final class Machine: Model, Content {
    static let schema: String = "machine"

    @ID(key: "id")
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Siblings(through: MachineDrinkPivot.self, from: \.$machine, to: \.$ingredient)
    var ingredient: [Ingredient]
    
    init(){}
    
    init(id: UUID? = nil, name:String)
    {
        self.id = id
        self.name = name
    }
}

// Machine drink relations
final class MachineDrinkPivot: Model {
    init() {}
    
    static let schema: String = "machine-pivot"
    
    @ID(key: "id")
    var id: UUID?
    
    @Parent(key: "machine-id")
    var machine: Machine
    
    @Parent(key: "ingredient-id")
    var ingredient: Ingredient
    
    init(id: UUID? = nil, machineID: UUID, ingredientID: UUID) {
        self.$machine.id = machineID
        self.$ingredient.id = ingredientID
    }
}
