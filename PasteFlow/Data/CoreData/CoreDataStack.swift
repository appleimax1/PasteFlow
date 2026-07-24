import CoreData

class CoreDataStack {
    static let shared = CoreDataStack()

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "PasteFlow")
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                print("CoreData Load Error: \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        // Устанавливаем политику слияния конфликтов: изменения в памяти перезаписывают базу данных
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return container
    }()

    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                print("CoreData Save Error: \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
