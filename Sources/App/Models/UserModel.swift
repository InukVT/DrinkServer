import Fluent
import Vapor

final class User: Model, Content {
    
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
    
    /// Convenience init, with build in password hasher
    convenience init (user: Create) throws {
        self.init(mail: user.mail, passwordHash: try Bcrypt.hash(user.password))
    }
}

extension User {
    struct Create: Content {
        let mail: String
        let password: String
    }
}

extension User: ModelUser {
    static let usernameKey = \User.$mail
    static let passwordHashKey = \User.$passwordHash

    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.passwordHash)
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
