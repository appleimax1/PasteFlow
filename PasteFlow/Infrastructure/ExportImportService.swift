import Foundation
import CoreData

struct ExportFolder: Codable {
    var uuid: String
    var name: String
    var sfSymbolName: String
    var snippets: [ExportSnippet]
}

struct ExportSnippet: Codable {
    var uuid: String
    var title: String
    var content: String
    var shortcutTrigger: String?
}

class ExportImportService {
    static let shared = ExportImportService()
    
    func exportSnippets(folders: [CDSnippetFolder]) -> Data? {
        let exportFolders = folders.map { folder in
            ExportFolder(
                uuid: folder.uuid?.uuidString ?? UUID().uuidString,
                name: folder.name ?? "Без названия",
                sfSymbolName: folder.sfSymbolName ?? "folder.fill",
                snippets: folder.snippetsArray.map { snippet in
                    ExportSnippet(
                        uuid: snippet.uuid?.uuidString ?? UUID().uuidString,
                        title: snippet.title ?? "Без названия",
                        content: snippet.rawString ?? "",
                        shortcutTrigger: snippet.shortcutTrigger
                    )
                }
            )
        }
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return try? encoder.encode(exportFolders)
    }
    
    func importSnippetsJSON(data: Data, context: NSManagedObjectContext) -> Bool {
        var success = false
        context.performAndWait {
            let decoder = JSONDecoder()
            guard let folders = try? decoder.decode([ExportFolder].self, from: data) else {
                return
            }
            
            for exportFolder in folders {
                let folder = CDSnippetFolder(context: context)
                folder.uuid = UUID(uuidString: exportFolder.uuid) ?? UUID()
                folder.name = exportFolder.name
                folder.sfSymbolName = exportFolder.sfSymbolName
                folder.createdAt = Date()
                folder.updatedAt = Date()
                
                for exportSnippet in exportFolder.snippets {
                    let snippet = CDSnippet(context: context)
                    snippet.uuid = UUID(uuidString: exportSnippet.uuid) ?? UUID()
                    snippet.title = exportSnippet.title
                    snippet.rawString = exportSnippet.content
                    snippet.shortcutTrigger = exportSnippet.shortcutTrigger
                    snippet.createdAt = Date()
                    snippet.updatedAt = Date()
                    snippet.folder = folder
                }
            }
            
            context.safeSave()
            context.processPendingChanges()
            success = true
        }
        
        if success {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name("PasteFlowSnippetsImported"), object: nil)
            }
        }
        
        return success
    }
    
    /// Parses original Clipy XML export files safely using Apple's XMLParser
    func importClipyXML(data: Data, context: NSManagedObjectContext) -> Bool {
        let parser = XMLParser(data: data)
        let delegate = ClipyXMLParserDelegate()
        parser.delegate = delegate
        parser.shouldResolveExternalEntities = false // Безопасность против XXE
        
        guard parser.parse() else {
            print("XML Parsing error: \(String(describing: parser.parserError))")
            return false
        }
        
        var totalImported = 0
        
        context.performAndWait {
            for (index, parsedFolder) in delegate.folders.enumerated() {
                let folder = CDSnippetFolder(context: context)
                folder.uuid = UUID()
                folder.name = parsedFolder.title.isEmpty ? "Папка \(index + 1)" : parsedFolder.title
                folder.sfSymbolName = "folder.fill"
                folder.createdAt = Date()
                folder.updatedAt = Date()
                folder.sortOrder = Int32(index)
                
                for parsedSnippet in parsedFolder.snippets {
                    let snippet = CDSnippet(context: context)
                    snippet.uuid = UUID()
                    snippet.title = parsedSnippet.title.isEmpty ? "Без названия" : parsedSnippet.title
                    snippet.rawString = parsedSnippet.content
                    snippet.createdAt = Date()
                    snippet.updatedAt = Date()
                    snippet.folder = folder
                    
                    totalImported += 1
                }
            }
            
            context.safeSave()
            context.processPendingChanges()
        }
        
        if totalImported > 0 {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name("PasteFlowSnippetsImported"), object: nil)
            }
        }
        
        return totalImported > 0
    }
}

// MARK: - Safe XML Parser Delegate
private class ClipyXMLParserDelegate: NSObject, XMLParserDelegate {
    struct Folder {
        var title: String = ""
        var snippets: [Snippet] = []
    }
    
    struct Snippet {
        var title: String = ""
        var content: String = ""
    }
    
    var folders: [Folder] = []
    
    private var currentElement = ""
    private var elementAccumulator = ""
    
    private var currentFolder: Folder?
    private var currentSnippet: Snippet?
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        elementAccumulator = ""
        
        if elementName == "folder" {
            currentFolder = Folder()
        } else if elementName == "snippet" {
            currentSnippet = Snippet()
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        elementAccumulator += string
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        let value = elementAccumulator.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if elementName == "title" {
            if currentSnippet != nil {
                currentSnippet?.title = value
            } else if currentFolder != nil {
                currentFolder?.title = value
            }
        } else if elementName == "content" {
            currentSnippet?.content = value
        } else if elementName == "snippet" {
            if let snippet = currentSnippet {
                currentFolder?.snippets.append(snippet)
            }
            currentSnippet = nil
        } else if elementName == "folder" {
            if let folder = currentFolder {
                folders.append(folder)
            }
            currentFolder = nil
        }
    }
}

