import SwiftUI

struct SnippetEditorView: View {
    @ObservedObject var snippet: CDSnippet
    @State private var previewEvaluatedText: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Название сниппета")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                    
                    TextField("Например, Приветствие", text: Binding(
                        get: { snippet.title ?? "" },
                        set: { snippet.title = $0; save() }
                    ))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(size: 13, weight: .medium))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ключевое слово")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                    
                    TextField("например, ;;email", text: Binding(
                        get: { snippet.shortcutTrigger ?? "" },
                        set: { snippet.shortcutTrigger = $0; save() }
                    ))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(size: 13, design: .monospaced))
                    .frame(width: 140)
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Вставить динамический тег:")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(PlaceholderProcessor.availablePlaceholders, id: \.tag) { item in
                            Button(action: { insertPlaceholder(item.tag) }) {
                                Text(item.tag)
                                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(Color.accentColor.opacity(0.12)))
                                    .foregroundColor(.accentColor)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .help(item.description)
                        }
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Текст шаблона")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
                
                TextEditor(text: Binding(
                    get: { snippet.rawString ?? "" },
                    set: {
                        snippet.rawString = $0
                        save()
                        updatePreview()
                    }
                ))
                .font(.system(size: 12, design: .monospaced))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Label("Живой предпросмотр результата", systemImage: "sparkles")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.accentColor)
                
                ScrollView {
                    Text(previewEvaluatedText.isEmpty ? "(Пустой сниппет)" : previewEvaluatedText)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(8)
                .frame(height: 70)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color(NSColor.controlBackgroundColor)))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.accentColor.opacity(0.3), lineWidth: 1))
            }
        }
        .padding(16)
        .onAppear { updatePreview() }
    }
    
    private func insertPlaceholder(_ tag: String) {
        let current = snippet.rawString ?? ""
        snippet.rawString = current + tag
        save()
        updatePreview()
    }
    
    private func updatePreview() {
        let content = snippet.rawString ?? ""
        previewEvaluatedText = PlaceholderProcessor.shared.process(content)
    }
    
    private func save() {
        CoreDataStack.shared.saveContext()
    }
}
