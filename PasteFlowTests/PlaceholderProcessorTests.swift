import XCTest
@testable import PasteFlow

final class PlaceholderProcessorTests: XCTestCase {
    
    var processor: PlaceholderProcessor!
    
    override func setUp() {
        super.setUp()
        processor = PlaceholderProcessor()
    }
    
    override func tearDown() {
        processor = nil
        super.tearDown()
    }
    
    func testDatePlaceholder() {
        let text = "Сегодня {DATE}."
        let result = processor.process(text)
        XCTAssertFalse(result.contains("{DATE}"))
    }
    
    func testTimePlaceholder() {
        let text = "Время {TIME}."
        let result = processor.process(text)
        XCTAssertFalse(result.contains("{TIME}"))
    }
    
    func testUUIDPlaceholder() {
        let text = "ID: {UUID}"
        let result = processor.process(text)
        XCTAssertFalse(result.contains("{UUID}"))
        XCTAssertEqual(result.count, "ID: ".count + 36)
    }
    
    func testMultiplePlaceholders() {
        let text = "{DATE} - {TIME}"
        let result = processor.process(text)
        XCTAssertFalse(result.contains("{DATE}"))
        XCTAssertFalse(result.contains("{TIME}"))
    }
}
