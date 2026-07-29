import Cocoa
import CoreData

extension CDSnippetFolder {
    var childrenArray: [CDSnippetFolder] {
        let set = children as? Set<CDSnippetFolder> ?? []
        return set.sorted { $0.sortOrder < $1.sortOrder }
    }
    
    var snippetsArray: [CDSnippet] {
        let set = snippets as? Set<CDSnippet> ?? []
        return set.sorted { 
            if $0.sortOrder != $1.sortOrder {
                return $0.sortOrder < $1.sortOrder
            }
            return ($0.title ?? "") < ($1.title ?? "") 
        }
    }
}
