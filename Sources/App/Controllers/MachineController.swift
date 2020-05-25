import Vapor
import Fluent

public struct MachineController: RouteCollection {
    
    // Register the websocket endpoint as an endpoint
    public func boot(routes: RoutesBuilder) {
        let machine = routes.grouped("machine")
        machine.get(use: getMachines)
        machine.put(use: putIngredient)
        machine.webSocket(":name",
                          onUpgrade: register)
    }
    
    func putIngredient(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        try req.content.decode(MachineDrink.self)
            .toPivot()
            .save(on: req.db)
            .map { .created }
    }
    
    struct MachineDrink: Decodable {
        let machineID: UUID
        let ingredientID: UUID
        
        func toPivot() -> MachineDrinkPivot {
            .init(machineID: machineID, ingredientID: ingredientID)
        }
    }
    
    func getMachines(req: Request) -> EventLoopFuture<[Machine]> {
        Machine.query(on: req.db)
            .all()
    }
    
    // Struct to store the essentials for a websocket connection
    public struct MachineProvider {
        let webSocket: WebSocket
        let req: Request // The request can also use request for e.g. DB
    }
    
    // Register a new machine on the system
    func register(req: Request, ws: WebSocket) {
        // Not entirely type safe, but get name from URL
        // Name should probably be the name of the location
        // or something unique to the machine
        let name = req.parameters.get("name")!
        
        // Save the machine to the Database
        _ = Machine(name: name)
            .save(on: req.db)
        
        // The save function doesn't return machine, and we need the UUID later
        _ = Machine.query(on: req.db)
            .filter(\.$name == name)                 // Get the newly created machine
            .first()                                 // Get the first with the name, we don't have other parameters to base this off.
            .unwrap(or: Abort(.internalServerError)) // We just created the machine, if it doesn't exist, then something wrong happened
            .map { machine in
                // Register the machine to memory, so we can retrieve it later and elsewhere
                machines[machine.id!] = .init(webSocket: ws, req: req)
                // For debug purposes, print the machine name. Also nice to know which machines are registered at runtime without needing debugger
                print(machine.name)
                // Set delegate as the function to handle received texts
                machines[machine.id!]?.webSocket.onText(self.websocketDelegate)
                // When all is good, tell the machine what's it's ID is. This is needed for some requests.
                machines[machine.id!]?.webSocket.send("\(machine.id!)")
        }
    }
    
    // Delegate for handling incomming messages from a machine
    func websocketDelegate(ws: WebSocket, body: String) {
        // Print the message - no privacy
        print(body)
        
        // If the message is a registration form, print the mail.
        body.evalBody(type: User.UserContent.self) { user in
            print(user.mail)
        }
        
        // Evaluate liquor which ran out.
        body.evalBody(type: RanOut.self) { liquor in
            let machineID = liquor.machineID
            let liquorID =  liquor.liqourID
            
            // Delete the given liquor - only on the given machine, tell the machine it has been done.
            // This will use the machines db,
            // this has the interesting side affect, that we can have different db's for different machines.
            MachineDrinkPivot.query(on: machines[machineID]!.req.db)
                .filter(\.$ingredient.$id == liquorID)
                .filter(\.$machine.$id == machineID)
                .delete()
                .map{
                    ws.send("Ingredient removed")
                }
        }
        
    }
    
    // The websocketDelegate doesn't have knowledge about which machine makes the call, so we make the machine tell it, itself.
    struct RanOut: Decodable {
        let liqourID: UUID
        let machineID: UUID
    }
}

// All registered machines in memory.
public var machines: [UUID: MachineController.MachineProvider] = [:]

// Extend String only for this file
private extension String {
    func evalBody<T>(type: T.Type, callback: (T) -> ()) where T: Decodable
    {
        let decoder = JSONDecoder()
        
        let data = self.data(using: .utf8)!
        
        // Call callback, if body can be decoded as T.
        // Interesting quirk of how decodable and throwing works,
        // allows us to callback only if it can be decoded safely,
        // without explicitly checking, and having long try-catch chains.
        if let decoded = try? decoder.decode(type, from: data) {
            callback(decoded)
        }
    }
}
