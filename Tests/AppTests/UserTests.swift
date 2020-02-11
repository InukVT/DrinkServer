@testable import App
import XCTVapor

final class UserTests: VaporTestCase {
    func testUserRights() throws {
        let plainPassword = "password"
        let passwordHash = try Bcrypt.hash(plainPassword)
        let testUser = User(mail: "inuk@ruc.dk", passwordHash: passwordHash)
        try testUser.save(on: app.db).wait()
        
        let fetchedUser = User.find(1, on: app.db) // Fetch user to get the
        guard let user = try fetchedUser.wait() else {
            XCTFail("Couldn't find user") // This should never happen
            return
        }
        XCTAssertTrue( user.rights.contains(.canOrder) ) // If there's no user, then they can't order
        let passwordVerified = try user.verify(password: plainPassword)
        XCTAssertTrue(passwordVerified)
        
    }
}
