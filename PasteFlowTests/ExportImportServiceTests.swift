import XCTest
import CoreData
@testable import PasteFlow

final class ExportImportServiceTests: XCTestCase {
    
    var coreDataStack: CoreDataStack!
    
    override func setUp() {
        super.setUp()
        coreDataStack = CoreDataStack(inMemory: true)
    }
    
    override func tearDown() {
        coreDataStack = nil
        super.tearDown()
    }
    
    func testExportAndImportSnippets() {
        let context = coreDataStack.viewContext
        
        let folder = CDSnippetFolder(context: context)
        folder.uuid = UUID()
        folder.name = "Test Folder"
        folder.createdAt = Date()
        
        let snippet = CDSnippet(context: context)
        snippet.uuid = UUID()
        snippet.title = "Test Snippet"
        snippet.rawString = "Test Content"
        snippet.createdAt = Date()
        snippet.folder = folder
        
        try? context.save()
        
        guard let data = ExportImportService.shared.exportSnippets(folders: [folder]) else {
            XCTFail("Export failed")
            return
        }
        
        let success = ExportImportService.shared.importSnippetsJSON(data: data, context: context)
        XCTAssertTrue(success, "Import failed")
        
        let fetchRequest: NSFetchRequest<CDSnippetFolder> = CDSnippetFolder.fetchRequest()
        let folders = (try? context.fetch(fetchRequest)) ?? []
        // Expecting 2 folders because it imports new ones without deleting the old ones in this test setup
        XCTAssertEqual(folders.count, 2)
    }
}
