import Vapor
import Fluent

struct DrinksController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let drinksGroup = routes.grouped("drinks")
        
        drinksGroup.get(use: drinks)
        
        // The following routes requires a logged in user
        let tokenAuth = drinksGroup.grouped(TokenAuthenticator())
        tokenAuth.post("order", use: orderDrink)
        
        // The following routes requires a user with the role "Can create drink"
        let adminAuth = drinksGroup.grouped(AdminAuthenticator())
        adminAuth.post(use: newDrink) // New drink on /drinks
        adminAuth.post("ingredient", use: newIngredient) // New ingredient on /drinks/ingredient
        
    }
    
    func drinks(req: Request) throws -> EventLoopFuture<[DrinkRecipe]> {
        // Get Machine UUID from string, if this header is not passed in,
        // then available drinks can't get queried, therefore it is necessary
        // and without it, throw a bad request.
        guard let machineString = req.headers.first(name: "machine") else {
            throw Abort(.badRequest)
        }
        
        // Check if machine ID is a UUID, if it's not, then something went wrong
        // client side, and throw bad request.
        guard let desiredMachine: UUID = UUID.init(uuidString: machineString )
        else {
            throw Abort(.badRequest)
        }
        
        // Get the desired machine
        return Machine.query(on: req.db)
            .filter(\.$id == desiredMachine)
            .with(\.$ingredient) // Fuzzy loading ingredient allows to check against all drinks which are able to be made
            .first()
            .unwrap(or: Abort(.notFound)) // First returns optional, if the machine is not found, then return 404
            .flatMap { machine in
                // Impicit return because it looks better. When there's only a single statement,
                // the return keyword is not needed
                DrinkRecipe.query(on: req.db)
                    .join(RecipePivot.self,
                          on: \DrinkRecipe.$id == \RecipePivot.$recipe.$id)
                    .join(Ingredient.self,
                          on: \RecipePivot.$ingredient.$id == \Ingredient.$id)
                    // Check for drinks based on available ingredients on the given machine
                    .filter(Ingredient.self,
                            \Ingredient.$id ~~ machine.ingredient.map { $0.id! })
                    .unique()
                    .all()
        }
                
    }
    
    func orderDrink(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let requestedDrink = try req.content.decode(DrinkOrderer.self) // Get drink ID from request
        return DrinkRecipe.query(on: req.db)                           // Start a Drinks recipe query
            .filter(\.$id == requestedDrink.drinkID)                   // Query the ID from request
            .with(\.$ingredient)                                       // Also get the ingridients
            .first()                                                   // Get the first drink
            .unwrap(or: Abort(.notFound))                              // Return not found, if there isn't any drinks
            .flatMapThrowing { drink in
                // Check to see if the requested machine exists
                guard let machine = machines[requestedDrink.machineID]
                    else {
                        throw Abort(.notFound)
                    }
                
                let jsonEncoder = JSONEncoder()
                let drinkJson = try jsonEncoder.encode(drink)
                let drinkString = String(data: drinkJson, encoding: .utf8)
                if let drinkString = drinkString {
                    machine.webSocket
                        .send(drinkString)
                } else {
                    throw Abort(.internalServerError)
                }
                return .ok
        }
    }
    
    func newDrink(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        try req.content               // Get the content of HTTP request
            .decode(DrinkRecipe.self) // Decode it as DrinkRecipe
            .save(on: req.db)         // Save the request to DB
            .map { .created }         // return a http created to the client
    }
    
    func newIngredient(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        try req.content              // Get the content of HTTP request
            .decode(Ingredient.self) // Decode it as DrinkRecipe
            .save(on: req.db)        // Save the request to DB
            .map { .created }        // return a http created to the client
    }
    
    private struct DrinkOrderer: Content {
        let drinkID: UUID
        let machineID: UUID
    }
}

