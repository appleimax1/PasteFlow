import SwiftUI

struct HoverPreviewView: View {
    let entry: CDClipboardEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Шапка с мета-информацией
            HStack(spacing: 8) {
                Image(systemName: entry.sfSymbolName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.accentColor)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(entry.sourceAppName ?? "PasteFlow")
                        .font(.system(size: 11, weight: .bold))
                    Text(entry.timeFormatted)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if entry.charCount > 0 {
                    Text("\(entry.charCount) симв.")
                        .font(.system(size: 10, weight: .medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.secondary.opacity(0.15)))
                } else if entry.contentType == "image" && entry.imageWidth > 0 {
                    Text("\(Int(entry.imageWidth))×\(Int(entry.imageHeight))")
                        .font(.system(size: 10, weight: .medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.secondary.opacity(0.15)))
                }
            }
            
            Divider()
            
            // Содержимое
            if entry.contentType == "image", let nsImage = entry.image {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 100)
                    .cornerRadius(4)
            } else if entry.contentType == "file" {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(entry.fileURLs.prefix(3), id: \.self) { url in
                        HStack(spacing: 6) {
                            Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                                .resizable()
                                .frame(width: 14, height: 14)
                            Text(url.lastPathComponent)
                                .font(.system(size: 11, design: .monospaced))
                                .lineLimit(1)
                        }
                    }
                }
            } else {
                Text(entry.rawString ?? entry.plainTextPreview ?? "")
                    .font(.system(size: 11, design: .monospaced))
                    .lineLimit(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            
            Divider()
            
            // Подсказки
            HStack {
                Label("Enter — вставить", systemImage: "return")
                Spacer()
                Label("Shift+Enter — текст", systemImage: "text.quote")
            }
            .font(.system(size: 9))
            .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }
}

/// Плавающее превью-окно. Отображается НИЖЕ попапа при наведении на элемент.
/// Полностью независимо от layout списка — не вызывает дёрганья при скролле.
final class HoverPreviewPanel {
    static let shared = HoverPreviewPanel()
    
    private var panel: NSPanel?
    
    func show(entry: CDClipboardEntry, relativeTo popoverWindow: NSWindow?) {
        guard let popoverWindow else { hide(); return }
        
        // Обновить контент если панель уже показана
        if let panel = panel, panel.isVisible,
           let hosting = panel.contentView as? NSHostingView<HoverPreviewView> {
            hosting.rootView = HoverPreviewView(entry: entry)
            return
        }
        
        let view = HoverPreviewView(entry: entry)
        let hosting = NSHostingView(rootView: view)
        
        let panelSize = CGSize(width: 320, height: 180)
        let p = NSPanel(
            contentRect: NSRect(origin: .zero, size: panelSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        p.isFloatingPanel = true
        p.level = .floating
        p.isOpaque = false
        p.backgroundColor = .clear
        p.hasShadow = true
        p.ignoresMouseEvents = true
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        p.contentView = hosting
        
        position(p, relativeTo: popoverWindow)
        p.orderFront(nil)
        self.panel = p
    }
    
    func hide() {
        panel?.orderOut(nil)
        panel = nil
    }
    
    private func position(_ panel: NSPanel, relativeTo window: NSWindow) {
        let size = panel.frame.size
        let wFrame = window.frame
        let origin = NSPoint(
            x: wFrame.midX - size.width / 2,
            y: wFrame.minY - size.height - 6
        )
        panel.setFrameOrigin(origin)
    }
}
