import SwiftUI
import AppKit

struct CustomTextEditor: NSViewRepresentable {
    @Binding var text: String
    var onEnter: (() -> Void)?
    var onCmdEnter: (() -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? NSTextView else {
            return scrollView
        }
        
        textView.delegate = context.coordinator
        textView.isRichText = false
        textView.font = NSFont.systemFont(ofSize: 13)
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: 4, height: 6)
        textView.allowsUndo = true
        
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        if textView.string != text {
            textView.string = text
        }
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: CustomTextEditor

        init(_ parent: CustomTextEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            self.parent.text = textView.string
        }

        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                if let event = NSApp.currentEvent, event.type == .keyDown {
                    let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
                    // Shift + Enter или Option + Enter -> Новая строка
                    if flags.contains(.shift) || flags.contains(.option) {
                        textView.insertText("\n", replacementRange: textView.selectedRange())
                        return true
                    }
                    // Cmd + Enter -> Копировать результат
                    if flags.contains(.command) {
                        DispatchQueue.main.async {
                            self.parent.onCmdEnter?()
                        }
                        return true
                    }
                    // Обычный Enter -> Запуск проверки текста
                    if flags.isEmpty {
                        DispatchQueue.main.async {
                            self.parent.onEnter?()
                        }
                        return true
                    }
                }
            }
            return false
        }
    }
}
