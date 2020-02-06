import XCTVapor
import App

/// Conform to this, when writing test classes
class VaporTester: XCTestCase {
    
    // MARK: Properties
    
    let app = Application(.testing)
    
    // MARK: Setup
    
    override func setUp() {
        super.setUp()
        
        do {
            try configure(app)
            try app
                .autoRevert()
                .wait()
            try app
                .autoMigrate()
                .wait()
        }
        catch {
            XCTFail("Setup failed. with \(error)")
        }
    }
    
    override func tearDown() {
        super.tearDown()
        
        app.shutdown()
    }

}
