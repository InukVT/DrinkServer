//
//  File.swift
//  
//
//  Created by Bastian Inuk Christensen on 06/02/2020.
//

import Fluent

final class User: Model {
    
    static var schema = "user"
    
    @ID(key: "id")
    var id: Int?
    
    @Field(key: "mail")
    var mail: String
    
    @Field(key: "password")
    var passwordHash: String
    
    @Field(key: "rights")
    var rights: UserRights
    
    // this is to conform to model
    init() {}
    
    init(id: Int? = nil, mail: String, passwordHash: String, rights: UserRights = .canOrder) {
        self.id = id
        self.mail = mail
        self.passwordHash = passwordHash
        self.rights = rights
    }
}

extension User {
    /// This is like a bitmask, but much nicer handled
    struct UserRights: OptionSet, Codable {
        let rawValue: UInt8
        
        /// The user can order
        public static let canOrder = UserRights(rawValue: 1 << 0)
    }
}
