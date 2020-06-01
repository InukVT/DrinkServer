import Fluent
import Vapor

// Checks if user exists and their password is correct
struct UserAuthenticator: BasicAuthenticator {
    
    func authenticate(basic: BasicAuthorization,
                      for req: Request
    ) -> EventLoopFuture<Void> {
        User.query(on: req.db)
            .filter(\.$mail == basic.username)
            .first()
            .unwrap(or: Abort(.unauthorized))
            .flatMapThrowing { user in
                if try user.verify(password: basic.password) {
                    req.auth.login(user)
                } else {
                    throw Abort(.unauthorized)
                }
        }
    }
}

final class User: Model, Content {
    
    static var schema = "user"
    
    @ID(key: "id")
    var id: UUID?
    
    @Field(key: "mail")
    var mail: String
    
    @Field(key: "password")
    var password: String
    
    @Field(key: "rights")
    var rights: UserRights
    
    // this is to conform to model
    init() {}
    
    init(id: UUID? = nil, mail: String, password: String, rights: UserRights = .canOrder) {
        self.id = id
        self.mail = mail
        self.password = password
        self.rights = rights
    }
}

extension User {
    final class UserContent: Content {
        let mail: String
        let password: String
        
        /// Turns this struct into a user struct
        func toUser() -> User {
            .init(mail: mail, password: password)
        }
        
        init(mail: String, password: String) {
            self.mail = mail
            self.password = password
        }
        
        /// Hash the password for better security
        func hash() -> UserContent {
            .init(mail: mail, password: try! Bcrypt.hash(password))
        }
    }
}

// Checks if token is valid
struct TokenAuthenticator: BearerAuthenticator {
    
    func authenticate(bearer: BearerAuthorization,
                      for req: Request) -> EventLoopFuture<Void> {
        Token.query(on: req.db)
            .filter(\.$token == bearer.token)
            .first()
            .unwrap(or: Abort(.unauthorized))
            .flatMap { token in
                token
                    .$user
                    .get(on: req.db)
                    .map { user in
                        req.auth.login( user )
                }
        }
    }
}

final class Token: Model, Content {
    static var schema = "user_token"
    
    @ID(key: "id")
    var id: UUID?
    
    @Field(key: "token")
    var token: String
    
    @Parent(key: "user_id")
    var user: User
    
    init() {}
    
    init(id: UUID? = nil, token: String, userID: User.IDValue) {
        self.id = id
        self.token = token
        self.$user.id = userID
    }
}
extension User {
    /// Generate a random token for a given user
    func generateToken() throws -> Token {
        try .init(
            token: [UInt8].random(count: 16).base64,
            userID: self.requireID())
    }
}

extension Token: ModelTokenAuthenticatable {
    
    static let valueKey = \Token.$token
    static let userKey = \Token.$user

    var isValid: Bool {
        true
    }
}

extension User: ModelAuthenticatable {
    static let usernameKey = \User.$mail
    static let passwordHashKey = \User.$password

    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.password)
    }
}

enum UserError: Error {
    case billy
}

/// This is like a bitmask, but much nicer handled
struct UserRights: Codable, OptionSet  {
    init(rawValue: UInt64) {
        self.rawValue = rawValue
    }
    
    let rawValue: UInt64

    func encode(to encoder: Encoder) throws {
        try rawValue.encode(to: encoder)
    }
    
    init(from decoder: Decoder) throws {
      rawValue = try .init(from: decoder)
    }
    
    /// This is a given user, used for default Init in User
    static let everyone: UserRights = []
    /// The user can order medicine
    static let canOrder = UserRights(rawValue: 1 << 0)
    /// Anyone with this priv can change a different user
    static let modUser = UserRights(rawValue: 1 << 1)
    /// This user can edit and add medicine to the system
    static let modDrinks = UserRights(rawValue: 1 << 2)
}

// Check if user is admin or return unauthorized
struct AdminAuthenticator: BearerAuthenticator {
    
    func authenticate(bearer: BearerAuthorization,
                      for req: Request) -> EventLoopFuture<Void> {
        Token.query(on: req.db)
            .filter(\.$token == bearer.token)
            .first()
            .unwrap(or: Abort(.unauthorized))
            .flatMap { token in
                token
                    .$user
                    .get(on: req.db)
                    .flatMapThrowing { user in
                        if (user.rights.contains(.modDrinks))
                        {
                            req.auth.login( user )
                        } else {
                            throw Abort(.unauthorized)
                        }
                }
        }
    }
}
