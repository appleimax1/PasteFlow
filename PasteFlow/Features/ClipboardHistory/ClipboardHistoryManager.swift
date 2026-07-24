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
        CoreDataStack.shared.persistentContainer.performBackgroundTask { context in
            let entry = CDClipboardEntry(context: context)
            entry.uuid = UUID()
            entry.createdAt = Date()
            entry.contentType = "image"
            entry.rawContent = tiffData
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
        guard !hash.isEmpty else {
            try? context.save()
            enforceLimit(in: context)
            return
        }
        
        // Проверять дубликат по всей базе
        let fetchRequest: NSFetchRequest<CDClipboardEntry> = NSFetchRequest(entityName: "CDClipboardEntry")
        fetchRequest.predicate = NSPredicate(format: "self != %@", newEntry)
        
        if let existing = try? context.fetch(fetchRequest) {
            let duplicate = existing.first { $0.generateHash() == hash }
            if duplicate != nil {
                duplicate?.createdAt = Date()
                context.delete(newEntry)
                try? context.save()
                return
            }
        }
        
        try? context.save()
        enforceLimit(in: context)
    }
    
    func togglePin(_ entry: CDClipboardEntry) {
        entry.isPinned.toggle()
        CoreDataStack.shared.saveContext()
    }
    
    func deleteEntry(_ entry: CDClipboardEntry) {
        context.delete(entry)
        CoreDataStack.shared.saveContext()
    }
    
    func clearHistory() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CDClipboardEntry")
        fetchRequest.predicate = NSPredicate(format: "isPinned == NO")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try context.execute(deleteRequest)
            CoreDataStack.shared.saveContext()
        } catch {
            print("Failed to clear history: \(error)")
        }
    }
    
    func enforceLimit(in context: NSManagedObjectContext? = nil) {
        let ctx = context ?? self.context
        let limit = maxHistorySize
        let fetchRequest: NSFetchRequest<CDClipboardEntry> = NSFetchRequest(entityName: "CDClipboardEntry")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CDClipboardEntry.createdAt, ascending: false)]
        
        do {
            let entries = try ctx.fetch(fetchRequest)
            if entries.count > limit {
                let entriesToDelete = entries.suffix(from: limit).filter { !$0.isPinned }
                for entry in entriesToDelete {
                    ctx.delete(entry)
                }
                if ctx == self.context {
                    CoreDataStack.shared.saveContext()
                } else {
                    try? ctx.save()
                }
            }
        } catch {
            print("Failed to enforce history limit: \(error)")
        }
    }
}
