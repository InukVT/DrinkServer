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
        
        let passwordProtected = userCollection.grouped(User.authenticator().middleware())
        passwordProtected.post("login", use: loginUser)
        
        let tokenProtected = userCollection.grouped(Token.authenticator().middleware())
        tokenProtected.delete("logout", use: logoutUser)
    }
    
    func registerUser(req: Request) throws -> HTTPResponseStatus {
        let userContent = try req.content.decode(User.UserContent.self)
            
        let _ = userContent//User(user: user)
            .hash()
            .toUser()
            .save(on: req.db)
        return .ok
    }
    
    func loginUser(req: Request) throws -> EventLoopFuture<Token> {
        let user = try req.auth.require(User.self)
        let token = try user.generateToken()
        req.auth.login(user.self)
        return  token
            .save(on: req.db)
            .map{ token }
    }
    
    func logoutUser(req: Request) throws -> HTTPResponseStatus {
        req.auth.logout(User.self)
        return .ok
    }
}
