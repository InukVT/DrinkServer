@testable import App
import XCTVapor

final class UserTests: VaporTestCase {
    
    func testUserRights() throws {
        let plainPassword = "password"
        let passwordHash = try Bcrypt.hash(plainPassword)
        let testUser = User(mail: "inuk@ruc.dk", password: passwordHash)
        try testUser.save(on: app.db).wait()
        
        let fetchedUser = User.find(1, on: app.db) // Fetch user to get the
        guard let user = try fetchedUser.wait() else {
            XCTFail("Couldn't find user") // This should never happen, as we _just_ created the user
            return
        }
        XCTAssertTrue( user.rights.contains(.canOrder) ) // If there's no user, then they can't order
        let passwordVerified = try user.verify(password: plainPassword)
        XCTAssertTrue(passwordVerified)
        
    }
    
    func testRegisterUser() throws {
        let headers: HTTPHeaders = ["Content-Type":"application/json"]
        let user = User(mail: "my@mail.com", password: "123123")
        let encoder = JSONEncoder()
        let data = try encoder.encode(user)
        var body = ByteBufferAllocator().buffer(capacity: data.count)
            body.writeBytes(data)
        
        try app.test(.POST, "user/register", headers: headers, body: body) { res in
            XCTAssertEqual(res.status, .ok)
        }
    }
    
    func testLoginUser() throws {
        try testRegisterUser()
        let userString =  "my@mail.com:123123".data(using: .utf8)?.base64EncodedString()
        let headers: HTTPHeaders = ["Authorization":"Basic \(userString!)"]
        
        try app.test(.POST, "user/login", headers: headers) { res in
            XCTAssertEqual(res.status, .ok)
        }
    }
    
    func testLogoutUser() throws {
        try app.test(.POST, "user/logout") { res in
            
        }
    }
}
