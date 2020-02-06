@testable import App
import XCTVapor

final class UserTests: VaporTester {
    func testUserRights() throws {
        let testUser = User(mail: "inuk@ruc.dk", password: "hello")
        testUser.save(on: app.db)
        
        let fetchedUser = User.find(1, on: app.db) // Fetch user to get the
        fetchedUser.map { user -> Void in // Explicit void, because void can't be inferred
            XCTAssertTrue( user?.rights.contains(.canOrder) ?? false ) // If there's no user, then they can't order
            
            user?.delete(force: true, on: self.app.db) // Cleanly remove the user after use
        }
    }
}
