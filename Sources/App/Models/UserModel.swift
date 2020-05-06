import Fluent
import Vapor


final class UserAuthenticator: BasicAuthenticator {
    
    func authenticate(basic: BasicAuthorization,
                      for req: Request
    ) -> EventLoopFuture<Void> {
        let user = User(mail: basic.username,
                        password: basic.password)
        
        return req.eventLoop.submit{ req.auth.login(user) }
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
        
        func toUser() -> User {
            .init(mail: mail, password: password)
        }
        
        init(mail: String, password: String) {
            self.mail = mail
            self.password = password
        }
        
        func hash() -> UserContent {
            .init(mail: mail, password: try! Bcrypt.hash(password))
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
    static let modMedicin = UserRights(rawValue: 1 << 2)
}
