import XCTest
import CoreData
import Cocoa
@testable import PasteFlow

final class ClipboardHistoryManagerTests: XCTestCase {
    
    var coreDataStack: CoreDataStack!
    
    override func setUp() {
        super.setUp()
        coreDataStack = CoreDataStack(inMemory: true)
    }
    
    override func tearDown() {
        coreDataStack = nil
        super.tearDown()
    }
    
    func testAddPlainTextEntry() {
        let context = coreDataStack.viewContext
        
        let entry = CDClipboardEntry(context: context)
        entry.uuid = UUID()
        entry.contentType = "plainText"
        entry.createdAt = Date()
        entry.rawString = "Hello Unit Test"
        entry.isPinned = false
        
        try? context.save()
        
        let fetchRequest: NSFetchRequest<CDClipboardEntry> = CDClipboardEntry.fetchRequest()
        let results = try? context.fetch(fetchRequest)
        
        XCTAssertEqual(results?.count, 1)
        XCTAssertEqual(results?.first?.rawString, "Hello Unit Test")
    }
    
    func testThumbnailGeneration() {
        let size = NSSize(width: 100, height: 100)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.red.set()
        NSRect(origin: .zero, size: size).fill()
        image.unlockFocus()
        
        let thumbnail = image.thumbnailData(maxSize: CGSize(width: 50, height: 50))
        XCTAssertNotNil(thumbnail)
        
        if let thumbData = thumbnail, let thumbImage = NSImage(data: thumbData) {
            XCTAssertTrue(thumbImage.size.width <= 50)
            XCTAssertTrue(thumbImage.size.height <= 50)
        }
    }
}
