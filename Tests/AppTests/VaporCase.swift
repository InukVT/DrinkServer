import XCTVapor
import App

/// Conform to this, when writing test classes
class VaporTestCase: XCTestCase {
    
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
        } catch {
            XCTFail("Setup failed. with \(error)")
        }
    }
    
    override func tearDown() {
        super.tearDown()
        do {
            try app
                .autoRevert()
                .wait()
        } catch {
            XCTFail("Couldn't tear down derver with error: \(error)")
        }
        app.shutdown()
    }

}
