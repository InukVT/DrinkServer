import Vapor
import Fluent

public struct MachineController: RouteCollection {
    public func boot(routes: RoutesBuilder) {
        let machine = routes.grouped("machine")
        machine.webSocket(":name",
                          onUpgrade: register)
    }
    
    public struct MachineProvider {
        let webSocket: WebSocket
        let req: Request
    }
    
    func register(req: Request, ws: WebSocket) {
        let name = req.parameters.get("name")!
        
        _ = Machine(name: name)
            .save(on: req.db)
        
        _ = Machine.query(on: req.db)
            .filter(\.$name == name)
            .first()
            .unwrap(or: Abort(.internalServerError))
            .map { machine in
                machines[machine.id!] = .init(webSocket: ws, req: req)
                print(machine.name)
                machines[machine.id!]?.webSocket.onText(self.websocketDelegate)
                machines[machine.id!]?.webSocket.send("\(machine.id!)")
        }
    }
    
    func websocketDelegate(ws: WebSocket, body: String) {
        print(body)
        
        body.evalBody(type: User.UserContent.self) { user in
            print(user.mail)
        }
    }
}

public var machines: [UUID: MachineController.MachineProvider] = [:]

private extension String {
    func evalBody<T>(type: T.Type, callback: (T) -> ()) where T: Decodable
    {
        let decoder = JSONDecoder()
        
        let data = self.data(using: .utf8)!
                
        if let decoded = try? decoder.decode(type, from: data) {
            callback(decoded)
        }
    }
}
