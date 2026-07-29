import Cocoa
import CoreData

class SnippetManager {
    static let shared = SnippetManager()
    let context = CoreDataStack.shared.viewContext
    
    func createFolder(name: String, icon: String = "folder.fill") -> CDSnippetFolder {
        let folder = CDSnippetFolder(context: context)
        folder.uuid = UUID()
        folder.name = name
        folder.sfSymbolName = icon
        folder.createdAt = Date()
        folder.updatedAt = Date()
        folder.sortOrder = 0
        context.safeSave()
        return folder
    }
    
    func createSnippet(in folder: CDSnippetFolder, title: String, content: String) -> CDSnippet {
        let snippet = CDSnippet(context: context)
        snippet.uuid = UUID()
        snippet.title = title
        snippet.rawString = content
        snippet.createdAt = Date()
        snippet.updatedAt = Date()
        snippet.folder = folder
        context.safeSave()
        return snippet
    }
    
    func delete(object: NSManagedObject) {
        context.perform {
            self.context.delete(object)
            self.context.safeSave()
        }
    }
}
