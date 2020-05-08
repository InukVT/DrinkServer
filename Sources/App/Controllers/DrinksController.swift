import Vapor
import Fluent

struct DrinksController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let drinksGroup = routes.grouped("drinks")
        let tokenAuth = drinksGroup.grouped(TokenAuthenticator())
        let adminAuth = drinksGroup.grouped(AdminAuthenticator())
        
        drinksGroup.post(use: drinks)
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
}
