import Vapor
import Fluent

final class DrinkRecipe: Model, Content {
    static let schema: String = "recipe"
    
    @ID(key: "id")
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Siblings(through: RecipePivot.self, from: \.$recipe, to: \.$ingredient)
    var ingredient: [Ingredient]
    
    init() {}
    
    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}

final class RecipePivot: Model {
    static let schema: String = "recipe-pivot"
    
    @ID(key: "id")
    var id: UUID?
    
    @Parent(key: "recipe-id")
    var recipe: DrinkRecipe
    
    @Parent(key: "ingredient-id")
    var ingredient: Ingredient
    
    init() {}
    
    init(recipeID: UUID, ingredientID: UUID) {
        self.$recipe.id = recipeID
        self.$ingredient.id = ingredientID
    }
}
