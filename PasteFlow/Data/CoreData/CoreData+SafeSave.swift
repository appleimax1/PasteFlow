import CoreData
import os

private let logger = Logger(subsystem: "com.pasteflow", category: "CoreData")

extension NSManagedObjectContext {
    func safeSave(caller: String = #function) {
        self.performAndWait {
            if self.hasChanges {
                do {
                    try self.save()
                } catch {
                    logger.error("[\(caller)] CoreData save failed: \(error.localizedDescription)")
                }
            }
        }
    }
}
