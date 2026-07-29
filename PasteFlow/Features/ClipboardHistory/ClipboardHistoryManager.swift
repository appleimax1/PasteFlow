import Cocoa
import CoreData

class ClipboardHistoryManager: ObservableObject {
    static let shared = ClipboardHistoryManager()
    let context = CoreDataStack.shared.viewContext
    
    var maxHistorySize: Int {
        let stored = UserDefaults.standard.integer(forKey: "PasteFlow.MaxHistorySize")
        return stored > 0 ? stored : 40
    }
    
    func addTextEntry(text: String, appName: String, appBundleID: String) {
        CoreDataStack.shared.persistentContainer.performBackgroundTask { context in
            let entry = CDClipboardEntry(context: context)
            entry.uuid = UUID()
            entry.createdAt = Date()
            entry.contentType = "plainText"
            entry.rawString = text
            entry.plainTextPreview = String(text.prefix(300))
            entry.charCount = Int32(text.count)
            entry.sourceAppName = appName
            entry.sourceAppBundleID = appBundleID
            
            self.saveAndDeduplicate(entry, in: context)
        }
    }
    
    func addImageEntry(image: NSImage, tiffData: Data, appName: String, appBundleID: String) {
        let thumbData = image.generateThumbnailData()
        
        CoreDataStack.shared.persistentContainer.performBackgroundTask { context in
            let entry = CDClipboardEntry(context: context)
            entry.uuid = UUID()
            entry.createdAt = Date()
            entry.contentType = "image"
            entry.rawContent = tiffData
            entry.setValue(thumbData, forKey: "thumbnailData")
            entry.plainTextPreview = "Изображение (\(Int(image.size.width))×\(Int(image.size.height)))"
            entry.imageWidth = Double(image.size.width)
            entry.imageHeight = Double(image.size.height)
            entry.sourceAppName = appName
            entry.sourceAppBundleID = appBundleID
            
            self.saveAndDeduplicate(entry, in: context)
        }
    }
    
    func addRTFEntry(rtfData: Data, plainText: String, appName: String, appBundleID: String) {
        CoreDataStack.shared.persistentContainer.performBackgroundTask { context in
            let entry = CDClipboardEntry(context: context)
            entry.uuid = UUID()
            entry.createdAt = Date()
            entry.contentType = "rtf"
            entry.rtfData = rtfData
            entry.rawString = plainText
            entry.plainTextPreview = String(plainText.prefix(300))
            entry.charCount = Int32(plainText.count)
            entry.sourceAppName = appName
            entry.sourceAppBundleID = appBundleID
            
            self.saveAndDeduplicate(entry, in: context)
        }
    }
    
    func addPDFEntry(pdfData: Data, plainText: String, appName: String, appBundleID: String) {
        CoreDataStack.shared.persistentContainer.performBackgroundTask { context in
            let entry = CDClipboardEntry(context: context)
            entry.uuid = UUID()
            entry.createdAt = Date()
            entry.contentType = "pdf"
            entry.pdfData = pdfData
            entry.rawString = plainText
            entry.plainTextPreview = plainText.isEmpty ? "Документ PDF" : String(plainText.prefix(300))
            entry.sourceAppName = appName
            entry.sourceAppBundleID = appBundleID
            
            self.saveAndDeduplicate(entry, in: context)
        }
    }
    
    func addFileEntry(urls: [URL], appName: String, appBundleID: String) {
        CoreDataStack.shared.persistentContainer.performBackgroundTask { context in
            let entry = CDClipboardEntry(context: context)
            entry.uuid = UUID()
            entry.createdAt = Date()
            entry.contentType = "file"
            entry.setFileURLs(urls)
            let title = urls.count == 1 ? urls[0].lastPathComponent : "Файлов: \(urls.count)"
            entry.plainTextPreview = title
            entry.sourceAppName = appName
            entry.sourceAppBundleID = appBundleID
            
            self.saveAndDeduplicate(entry, in: context)
        }
    }
    
    private func saveAndDeduplicate(_ newEntry: CDClipboardEntry, in context: NSManagedObjectContext) {
        let hash = newEntry.generateHash()
        newEntry.contentHash = hash
        guard !hash.isEmpty else {
            context.safeSave()
            enforceLimit(in: context)
            return
        }
        
        let fetchRequest: NSFetchRequest<CDClipboardEntry> = NSFetchRequest(entityName: "CDClipboardEntry")
        fetchRequest.predicate = NSPredicate(format: "contentHash == %@ AND self != %@", hash, newEntry)
        fetchRequest.fetchLimit = 1
        
        if let existing = try? context.fetch(fetchRequest), let duplicate = existing.first {
            duplicate.createdAt = Date()
            context.delete(newEntry)
            context.safeSave()
            return
        }
        
        context.safeSave()
        enforceLimit(in: context)
    }
    
    func togglePin(_ entry: CDClipboardEntry) {
        context.perform {
            entry.isPinned.toggle()
            self.context.safeSave()
        }
    }
    
    func deleteEntry(_ entry: CDClipboardEntry) {
        context.perform {
            self.context.delete(entry)
            self.context.safeSave()
        }
    }
    
    func clearHistory() {
        context.perform {
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CDClipboardEntry")
            fetchRequest.predicate = NSPredicate(format: "isPinned == NO")
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            do {
                try self.context.execute(deleteRequest)
                self.context.safeSave()
            } catch {
                print("Failed to clear history: \(error)")
            }
        }
    }
    
    func enforceLimit(in context: NSManagedObjectContext? = nil) {
        let ctx = context ?? self.context
        ctx.perform {
            let limit = self.maxHistorySize
            let fetchRequest: NSFetchRequest<CDClipboardEntry> = NSFetchRequest(entityName: "CDClipboardEntry")
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CDClipboardEntry.createdAt, ascending: false)]
            
            do {
                let entries = try ctx.fetch(fetchRequest)
                if entries.count > limit {
                    let entriesToDelete = entries.suffix(from: limit).filter { !$0.isPinned }
                    for entry in entriesToDelete {
                        ctx.delete(entry)
                    }
                    ctx.safeSave()
                }
            } catch {
                print("Failed to enforce history limit: \(error)")
            }
        }
    }
}
