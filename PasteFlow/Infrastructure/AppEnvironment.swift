import Foundation
import CoreData
import SwiftUI

/// Глобальный контейнер зависимостей приложения.
final class AppEnvironment: ObservableObject {
    let coreDataStack: CoreDataStack
    let clipboardHistoryManager: ClipboardHistoryManager
    let snippetManager: SnippetManager
    let pasteEngine: PasteEngine
    let placeholderProcessor: PlaceholderProcessor
    
    init(
        coreDataStack: CoreDataStack = .shared,
        clipboardHistoryManager: ClipboardHistoryManager = .shared,
        snippetManager: SnippetManager = .shared,
        pasteEngine: PasteEngine = .shared,
        placeholderProcessor: PlaceholderProcessor = .shared
    ) {
        self.coreDataStack = coreDataStack
        self.clipboardHistoryManager = clipboardHistoryManager
        self.snippetManager = snippetManager
        self.pasteEngine = pasteEngine
        self.placeholderProcessor = placeholderProcessor
    }
}
