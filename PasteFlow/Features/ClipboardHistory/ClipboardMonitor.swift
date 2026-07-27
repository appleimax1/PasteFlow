import Cocoa

class ClipboardMonitor {
    static let shared = ClipboardMonitor()
    
    var isPaused: Bool = false
    private var timer: Timer?
    private let pasteboard = NSPasteboard.general
    private var lastChangeCount = 0

    func startMonitoring() {
        lastChangeCount = pasteboard.changeCount
        
        let t = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkPasteboard()
        }
        RunLoop.main.add(t, forMode: .common)
        self.timer = t
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func checkPasteboard() {
        let currentChangeCount = pasteboard.changeCount
        guard currentChangeCount != lastChangeCount else { return }
        lastChangeCount = currentChangeCount
        
        guard !isPaused else { return }
        
        let types = pasteboard.types ?? []
        
        // Clipy: не сохранять временные данные (TransientType)
        let transientType = NSPasteboard.PasteboardType("org.nspasteboard.TransientType")
        if types.contains(transientType) { return }
        
        // Clipy: не сохранять данные от менеджеров паролей (ConcealedType)
        let concealedType = NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType")
        if types.contains(concealedType) { return }
        
        // Clipy: не сохранять данные Universal Clipboard если это только ссылки на файлы
        let universalClipboard = NSPasteboard.PasteboardType("com.apple.is-remote-clipboard")
        if types.contains(universalClipboard) {
            let fileTypes: Set<NSPasteboard.PasteboardType> = [.fileURL, NSPasteboard.PasteboardType("NSFilenamesPboardType")]
            if let firstType = types.first, fileTypes.contains(firstType) { return }
        }
        
        if AppExclusionFilter.shared.isCurrentAppExcluded() {
            return
        }

        
        let frontApp = NSWorkspace.shared.frontmostApplication
        let appName = frontApp?.localizedName ?? "Система"
        let appBundleID = frontApp?.bundleIdentifier ?? "com.apple.finder"
        
        let enableText = UserDefaults.standard.object(forKey: "PasteFlow.EnableText") as? Bool ?? true
        let enableImages = UserDefaults.standard.object(forKey: "PasteFlow.EnableImages") as? Bool ?? true
        let enableRTF = UserDefaults.standard.object(forKey: "PasteFlow.EnableRTF") as? Bool ?? true
        let enablePDF = UserDefaults.standard.object(forKey: "PasteFlow.EnablePDF") as? Bool ?? true
        let enableFiles = UserDefaults.standard.object(forKey: "PasteFlow.EnableFiles") as? Bool ?? true
        
        // 1. Files (Should be checked first because Finder puts BOTH fileURL and string in pasteboard)
        if enableFiles, let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL], !urls.isEmpty {
            let fileUrls = urls.filter { $0.isFileURL }
            if !fileUrls.isEmpty {
                ClipboardHistoryManager.shared.addFileEntry(urls: fileUrls, appName: appName, appBundleID: appBundleID)
                return
            }
        }
        
        // 2. Images
        if enableImages, let image = NSImage(pasteboard: pasteboard), let tiffData = image.tiffRepresentation {
            ClipboardHistoryManager.shared.addImageEntry(image: image, tiffData: tiffData, appName: appName, appBundleID: appBundleID)
            return
        }
        
        // 3. PDF
        if enablePDF, let pdfData = pasteboard.data(forType: .pdf) {
            let plainText = pasteboard.string(forType: .string) ?? "Документ PDF"
            ClipboardHistoryManager.shared.addPDFEntry(pdfData: pdfData, plainText: plainText, appName: appName, appBundleID: appBundleID)
            return
        }
        
        // 4. Text & Rich Text (most common, but fallback)
        if enableText, let text = pasteboard.string(forType: .string), !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            if enableRTF, let rtfData = pasteboard.data(forType: .rtf) {
                ClipboardHistoryManager.shared.addRTFEntry(rtfData: rtfData, plainText: text, appName: appName, appBundleID: appBundleID)
            } else {
                ClipboardHistoryManager.shared.addTextEntry(text: text, appName: appName, appBundleID: appBundleID)
            }
            return
        }
    }
}
