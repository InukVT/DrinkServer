import Vapor

struct MachineController {
    mutating func boot(routes: RoutesBuilder) {
        let machine = routes.grouped("machine")
        machine.webSocket("register",
                          onUpgrade: register)
    }
    
    struct MachineProvider {
        let webSocket: WebSocket
        let req: Request
    }
    
    private(set) var machines: [UUID: MachineProvider] = [:]
    
    mutating func register(req: Request, ws: WebSocket) {
        machines[UUID.generateRandom()] = .init(webSocket: ws, req: req)
    }
}
