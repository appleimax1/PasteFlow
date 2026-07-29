import SwiftUI
import Cocoa

@available(macOS 13.0, *)
struct FlowLayout: Layout {
    var spacing: CGFloat = 4
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 350
        var height: CGFloat = 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var maxHeightInRow: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width && x > 0 {
                x = 0
                y += maxHeightInRow + spacing
                maxHeightInRow = 0
            }
            x += size.width + spacing
            maxHeightInRow = max(maxHeightInRow, size.height)
        }
        height = y + maxHeightInRow
        return CGSize(width: width, height: max(height, 16))
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var maxHeightInRow: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                x = bounds.minX
                y += maxHeightInRow + spacing
                maxHeightInRow = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            maxHeightInRow = max(maxHeightInRow, size.height)
        }
    }
}

struct TextAssistantWindowView: View {
    @State private var inputText: String = ""
    @State private var rawResultText: String = ""
    @State private var fixCount: Int = 0
    @State private var paragraphs: [TextDiffParagraph] = []
    @State private var rejectedSegmentIDs: Set<UUID> = []
    @State private var selectedAlternatives: [UUID: String] = [:]
    @State private var showCopiedToast: Bool = false
    @State private var isProcessing: Bool = false
    
    @AppStorage("PasteFlow.ClearTextAssistantOnClose") private var clearOnClose = false
    @AppStorage("PasteFlow.LastAssistantInputText") private var savedInputText = ""
    
    var onClose: () -> Void
    var onRegisterCopyHandler: ((@escaping () -> Void) -> Void)?
    var onRegisterCheckHandler: ((@escaping () -> Void) -> Void)?
    
    @ObservedObject private var langManager = LanguageManager.shared
    
    var effectiveResultText: String {
        if paragraphs.isEmpty { return rawResultText }
        var lineResults: [String] = []
        for paragraph in paragraphs {
            var wordParts: [String] = []
            for seg in paragraph.segments {
                let isRejected = rejectedSegmentIDs.contains(seg.id)
                switch seg.type {
                case .unchanged:
                    wordParts.append(seg.text)
                case .inserted:
                    if !isRejected {
                        wordParts.append(seg.text)
                    }
                case .deleted:
                    if isRejected {
                        wordParts.append(seg.text)
                    }
                case .modified(_, let new, _):
                    if let selection = selectedAlternatives[seg.id] {
                        wordParts.append(selection)
                    } else {
                        wordParts.append(new)
                    }
                }
            }
            lineResults.append(wordParts.joined(separator: " "))
        }
        return lineResults.joined(separator: "\n")
    }
    
    var activeFixes: Int {
        var active = fixCount
        for _ in rejectedSegmentIDs { active -= 1 }
        for p in paragraphs {
            for s in p.segments {
                if case .modified(let orig, _, _) = s.type, selectedAlternatives[s.id] == orig {
                    active -= 1
                }
            }
        }
        return max(0, active)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.bubble.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.accentColor)
                    
                    Text("text_assistant.title".localized)
                        .font(.system(size: 14, weight: .bold))
                    
                    Spacer()
                    
                    Text("Esc — закрыть")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.secondary.opacity(0.12)))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Hints Banner
            HStack(spacing: 6) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.orange)
                
                Text("text_assistant.hints".localized)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(Color.orange.opacity(0.08))
            
            Divider()
            
            // 2 Dialogue / Text Panes
            HStack(spacing: 0) {
                // Panel 1: Input Text
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Исходный текст")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button(action: pasteFromClipboard) {
                            Label("text_assistant.paste_input_btn".localized, systemImage: "doc.on.clipboard")
                                .font(.system(size: 11))
                        }
                        .buttonStyle(BorderedButtonStyle())
                        
                        if !inputText.isEmpty {
                            Button(action: clearText) {
                                Image(systemName: "trash")
                                    .font(.system(size: 11))
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    
                    ZStack(alignment: .topLeading) {
                        if inputText.isEmpty {
                            Text("text_assistant.input_placeholder".localized)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary.opacity(0.6))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 8)
                        }
                        
                        CustomTextEditor(
                            text: $inputText,
                            onEnter: {
                                runSpellCheck(text: inputText)
                            },
                            onCmdEnter: {
                                copyResult()
                            }
                        )
                    }
                    .padding(4)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color(NSColor.controlBackgroundColor)))
                    
                    HStack {
                        Text("\(inputText.count) симв. • \(wordCount(inputText)) слов")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    
                    // Button Bar for Panel 1
                    HStack {
                        Button(action: { runSpellCheck(text: inputText) }) {
                            HStack(spacing: 6) {
                                if isProcessing {
                                    ProgressView()
                                        .scaleEffect(0.6)
                                        .frame(width: 12, height: 12)
                                }
                                Text(isProcessing ? "Проверка..." : "Проверить текст (↵)")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .frame(maxWidth: .infinity, minHeight: 24)
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(BorderedProminentButtonStyle())
                        .tint(Color.accentColor)
                        .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isProcessing)
                    }
                }
                .padding(14)
                
                Divider()
                
                // Panel 2: Result Text & Interactive Diff Layout
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Результат проверки")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if isProcessing {
                            ProgressView()
                                .scaleEffect(0.6)
                                .frame(width: 14, height: 14)
                        } else if fixCount > 0 {
                            Text("\(activeFixes) из \(fixCount) испр.")
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.green.opacity(0.2)))
                                .foregroundColor(.green)
                        }
                    }
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 6) {
                            if isProcessing {
                                HStack {
                                    Spacer()
                                    VStack(spacing: 8) {
                                        ProgressView()
                                        Text("Проверяем орфографию и пунктуацию...")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.top, 40)
                                    Spacer()
                                }
                            } else if rawResultText.isEmpty {
                                Text("text_assistant.result_placeholder".localized)
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary.opacity(0.6))
                                    .padding(8)
                            } else {
                                InteractiveDiffView(
                                    paragraphs: paragraphs,
                                    rejectedIDs: rejectedSegmentIDs,
                                    selectedAlternatives: $selectedAlternatives,
                                    onToggleSegment: { id in
                                        toggleSegmentRejection(id: id)
                                    }
                                )
                                .padding(8)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color(NSColor.controlBackgroundColor)))
                    
                    // Action Buttons Bar for Panel 2
                    HStack {
                        Button(action: copyResult) {
                            HStack(spacing: 6) {
                                Image(systemName: showCopiedToast ? "checkmark.circle.fill" : "doc.on.doc.fill")
                                Text(showCopiedToast ? "✓ Скопировано в буфер!" : "Скопировать результат (⌘↵)")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .frame(maxWidth: .infinity, minHeight: 24)
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(BorderedProminentButtonStyle())
                        .tint(showCopiedToast ? Color.green : Color.accentColor)
                        .disabled(effectiveResultText.isEmpty || isProcessing)
                        .keyboardShortcut(.return, modifiers: [.command])
                    }
                }
                .padding(14)
            }
            
            Divider()
            
            // Footer Bar
            HStack {
                Text("Hunspell + 10 правил пунктуации • 100% Локальная проверка (без интернета)")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if showCopiedToast {
                    Text("✓ Результат скопирован в буфер обмена")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.green)
                        .transition(.opacity)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 780, height: 480)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            let shouldClear = UserDefaults.standard.bool(forKey: "PasteFlow.ClearTextAssistantOnClose")
            if shouldClear {
                self.inputText = ""
                self.rawResultText = ""
                self.paragraphs = []
                self.rejectedSegmentIDs.removeAll()
                self.savedInputText = ""
            } else if !savedInputText.isEmpty {
                self.inputText = savedInputText
                runSpellCheck(text: savedInputText)
            }
            
            onRegisterCopyHandler?({
                copyResult()
            })
            
            onRegisterCheckHandler?({
                runSpellCheck(text: inputText)
            })
        }
    }
    
    private func autoFillFromClipboard() {
        if let clipboardString = NSPasteboard.general.string(forType: .string), !clipboardString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            self.inputText = clipboardString
            runSpellCheck(text: clipboardString)
        }
    }
    
    private func runSpellCheck(text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        isProcessing = true
        rejectedSegmentIDs.removeAll()
        selectedAlternatives.removeAll()
        if !clearOnClose {
            savedInputText = text
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let res = TextAssistantEngine.shared.processText(text)
            DispatchQueue.main.async {
                self.rawResultText = res.correctedText
                self.fixCount = res.fixCount
                self.paragraphs = res.paragraphs
                self.isProcessing = false
            }
        }
    }
    
    private func toggleSegmentRejection(id: UUID) {
        if rejectedSegmentIDs.contains(id) {
            rejectedSegmentIDs.remove(id)
        } else {
            rejectedSegmentIDs.insert(id)
        }
    }
    
    private func pasteFromClipboard() {
        if let str = NSPasteboard.general.string(forType: .string) {
            self.inputText = str
            runSpellCheck(text: str)
        }
    }
    
    private func clearText() {
        self.inputText = ""
        self.rawResultText = ""
        self.fixCount = 0
        self.paragraphs = []
        self.rejectedSegmentIDs.removeAll()
        self.selectedAlternatives.removeAll()
        self.savedInputText = ""
    }
    
    private func copyResult() {
        let textToCopy = effectiveResultText
        guard !textToCopy.isEmpty else { return }
        
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(textToCopy, forType: .string)
        
        withAnimation {
            showCopiedToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                showCopiedToast = false
            }
        }
    }
    
    private func wordCount(_ text: String) -> Int {
        let components = text.components(separatedBy: .whitespacesAndNewlines)
        return components.filter { !$0.isEmpty }.count
    }
}

// MARK: - Интерактивный Diff с сохранением абзацев и красивым обтеканием слов
struct InteractiveDiffView: View {
    let paragraphs: [TextDiffParagraph]
    let rejectedIDs: Set<UUID>
    @Binding var selectedAlternatives: [UUID: String]
    let onToggleSegment: (UUID) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(paragraphs) { paragraph in
                if paragraph.segments.isEmpty {
                    Spacer().frame(height: 8)
                } else {
                    FlowLayout(spacing: 4) {
                        ForEach(paragraph.segments) { seg in
                            let isRejected = rejectedIDs.contains(seg.id)
                            
                            switch seg.type {
                            case .unchanged:
                                Text(seg.text)
                                    .font(.system(size: 13, design: .default))
                                    .foregroundColor(.primary)
                                
                            case .inserted:
                                Button(action: { onToggleSegment(seg.id) }) {
                                    HStack(spacing: 3) {
                                        Text(seg.text)
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(isRejected ? .secondary : .green)
                                            .strikethrough(isRejected)
                                        
                                        if isRejected {
                                            Text("(отменено)")
                                                .font(.system(size: 9))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(isRejected ? Color.gray.opacity(0.15) : Color.green.opacity(0.15))
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .help(isRejected ? "Кликните, чтобы вернуть добавленное" : "Кликните, чтобы отменить добавление")
                                
                            case .deleted:
                                Button(action: { onToggleSegment(seg.id) }) {
                                    HStack(spacing: 3) {
                                        Text(seg.text)
                                            .font(.system(size: 13))
                                            .foregroundColor(isRejected ? .primary : .red)
                                            .strikethrough(!isRejected)
                                        
                                        if isRejected {
                                            Text("(оставлено)")
                                                .font(.system(size: 9, weight: .semibold))
                                                .foregroundColor(.accentColor)
                                        }
                                    }
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(isRejected ? Color.accentColor.opacity(0.15) : Color.red.opacity(0.15))
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .help(isRejected ? "Кликните, чтобы удалить" : "Кликните, чтобы оставить оригинал")
                                
                            case .modified(let original, let new, let alternatives):
                                let currentSelection = selectedAlternatives[seg.id] ?? new
                                
                                Button(action: {
                                    DispatchQueue.main.async {
                                        if currentSelection == original {
                                            selectedAlternatives[seg.id] = new
                                        } else {
                                            selectedAlternatives[seg.id] = original
                                        }
                                    }
                                }) {
                                    HStack(spacing: 3) {
                                        if currentSelection == original {
                                            Text(original)
                                                .font(.system(size: 13, weight: .bold))
                                                .foregroundColor(.primary)
                                                .padding(.horizontal, 4)
                                                .padding(.vertical, 1)
                                                .background(RoundedRectangle(cornerRadius: 4).fill(Color.accentColor.opacity(0.2)))
                                            
                                            Text("(оригинал)")
                                                .font(.system(size: 9))
                                                .foregroundColor(.secondary)
                                        } else {
                                            Text(original)
                                                .font(.system(size: 13))
                                                .foregroundColor(.red)
                                                .strikethrough()
                                                .padding(.horizontal, 3)
                                                .background(RoundedRectangle(cornerRadius: 3).fill(Color.red.opacity(0.15)))
                                            
                                            Image(systemName: "arrow.right")
                                                .font(.system(size: 9))
                                                .foregroundColor(.secondary)
                                            
                                            Text(currentSelection)
                                                .font(.system(size: 13, weight: .bold))
                                                .foregroundColor(currentSelection == new ? .green : .orange)
                                                .padding(.horizontal, 3)
                                                .background(RoundedRectangle(cornerRadius: 3).fill(currentSelection == new ? Color.green.opacity(0.15) : Color.orange.opacity(0.15)))
                                        }
                                    }
                                    .padding(.vertical, 1)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .help(currentSelection == original ? "Кликните, чтобы применить (ПКМ для вариантов)" : "Кликните, чтобы отменить (ПКМ для вариантов)")
                                .contextMenu {
                                    Button(action: {
                                        DispatchQueue.main.async { selectedAlternatives[seg.id] = original }
                                    }) { Text("Оригинал: \(original)") }
                                    
                                    Button(action: {
                                        DispatchQueue.main.async { selectedAlternatives[seg.id] = new }
                                    }) { Text("Лучший вариант: \(new)") }
                                    
                                    if !alternatives.isEmpty {
                                        Divider()
                                        Text("Другие варианты:")
                                        ForEach(alternatives, id: \.self) { alt in
                                            Button(action: {
                                                DispatchQueue.main.async { selectedAlternatives[seg.id] = alt }
                                            }) { Text(alt) }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
