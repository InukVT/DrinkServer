//
//  File.swift
//  
//
//  Created by Bastian Inuk Christensen on 05/03/2020.
//

import Fluent
import Vapor

final class Drink: Model, Content {
    static var schema: String = "drink"
    
    @ID(key: "id")
    var id: Int?
}
