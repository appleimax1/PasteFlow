import Cocoa
import CoreData

extension CDSnippet {
    var rawString: String? {
        get {
            guard let data = rawContent else { return nil }
            return String(data: data, encoding: .utf8)
        }
        set {
            rawContent = newValue?.data(using: .utf8)
            plainTextContent = newValue
        }
    }
}
