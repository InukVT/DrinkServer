//
//  File.swift
//  
//
//  Created by Bastian Inuk Christensen on 21/02/2020.
//

import Vapor

struct UserController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let userCollection = routes.grouped("user")
        userCollection.post("register", use: registerUser)
    }
    
    func registerUser(req: Request) throws -> EventLoopFuture<User> {
        try User(user: try req.content.decode(User.Create.self))
            .save(on: req.db)
            .map{_ in
                try! User(user: try req.content.decode(User.Create.self))
        }
    }
}
