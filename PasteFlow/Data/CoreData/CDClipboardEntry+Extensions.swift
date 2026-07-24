import Cocoa
import CoreData
import CommonCrypto

extension CDClipboardEntry {
    var rawString: String? {
        get {
            guard let data = rawContent else { return nil }
            return String(data: data, encoding: .utf8)
        }
        set {
            rawContent = newValue?.data(using: .utf8)
        }
    }
    
    var image: NSImage? {
        guard contentType == "image", let data = rawContent else { return nil }
        return NSImage(data: data)
    }
    
    var fileURLs: [URL] {
        guard let data = fileURLsData,
              let paths = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return paths.map { URL(fileURLWithPath: $0) }
    }
    
    func setFileURLs(_ urls: [URL]) {
        let paths = urls.map { $0.path }
        fileURLsData = try? JSONEncoder().encode(paths)
    }
    
    var sfSymbolName: String {
        switch contentType {
        case "image": return "photo"
        case "rtf": return "doc.richtext"
        case "pdf": return "doc.fill"
        case "file": return "doc.on.doc"
        default: return "doc.text"
        }
    }
    
    var displayTitle: String {
        if let preview = plainTextPreview, !preview.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return preview.replacingOccurrences(of: "\n", with: " ")
        }
        if contentType == "image" {
            let w = Int(imageWidth)
            let h = Int(imageHeight)
            return w > 0 && h > 0 ? "\("core.image".localized) (\(w)×\(h))" : "core.image".localized
        }
        if contentType == "file" {
            let urls = fileURLs
            if urls.count == 1 {
                return urls[0].lastPathComponent
            } else if urls.count > 1 {
                return String(format: "core.files".localized, urls.count, urls[0].lastPathComponent)
            }
            return "core.file".localized
        }
        return "core.clipboard_item".localized
    }
    
    var timeFormatted: String {
        guard let date = createdAt else { return "" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    func generateHash() -> String {
        let dataToHash = rawContent ?? rtfData ?? pdfData ?? fileURLsData ?? Data()
        guard !dataToHash.isEmpty else { return "" }
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        dataToHash.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(dataToHash.count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
    
    var itemProvider: NSItemProvider {
        let provider = NSItemProvider()
        
        switch contentType {
        case "plainText":
            if let text = rawString {
                provider.registerDataRepresentation(forTypeIdentifier: "public.utf8-plain-text", visibility: .all) { completion in
                    completion(text.data(using: .utf8), nil)
                    return nil
                }
            }
        case "image":
            if let data = rawContent {
                provider.registerDataRepresentation(forTypeIdentifier: "public.tiff", visibility: .all) { completion in
                    completion(data, nil)
                    return nil
                }
            }
        case "rtf":
            if let rtf = rtfData {
                provider.registerDataRepresentation(forTypeIdentifier: "public.rtf", visibility: .all) { completion in
                    completion(rtf, nil)
                    return nil
                }
            }
        case "pdf":
            if let pdf = pdfData {
                provider.registerDataRepresentation(forTypeIdentifier: "com.adobe.pdf", visibility: .all) { completion in
                    completion(pdf, nil)
                    return nil
                }
            }
        case "file":
            for url in fileURLs {
                provider.registerFileRepresentation(forTypeIdentifier: "public.file-url", fileOptions: [], visibility: .all) { completion in
                    completion(url, true, nil)
                    return nil
                }
            }
        default:
            if let text = rawString {
                provider.registerDataRepresentation(forTypeIdentifier: "public.utf8-plain-text", visibility: .all) { completion in
                    completion(text.data(using: .utf8), nil)
                    return nil
                }
            }
        }
        
        return provider
    }
}
