import SwiftUI
import CoreData

struct SnippetMenuView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CDSnippetFolder.sortOrder, ascending: true)],
        animation: .easeInOut)
    private var folders: FetchedResults<CDSnippetFolder>
    
    @State private var searchText = ""
    @State private var refreshToggle = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 13))
                
                TextField("popup.search_snippets".localized, text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 12))
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color(NSColor.controlBackgroundColor)))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            
            Divider()
            
            if folders.isEmpty || allSnippetsEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("popup.snippets_empty".localized)
                        .font(.system(size: 13, weight: .semibold))
                    Text("popup.snippets_empty_desc".localized)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    Spacer()
                }
            } else {
                List {
                    ForEach(folders) { folder in
                        let matchingSnippets = folder.snippetsArray.filter { snippet in
                            searchText.isEmpty ||
                            (snippet.title?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                            (snippet.rawString?.localizedCaseInsensitiveContains(searchText) ?? false)
                        }
                        
                        if !matchingSnippets.isEmpty {
                            DisclosureGroup {
                                ForEach(matchingSnippets) { snippet in
                                    SnippetRow(snippet: snippet)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            pasteSnippet(snippet)
                                        }
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: folder.sfSymbolName ?? "folder.fill")
                                        .foregroundColor(.accentColor)
                                    Text(folder.name ?? "popup.snippets".localized)
                                        .font(.system(size: 13, weight: .bold))
                                }
                                .foregroundColor(.primary)
                                .padding(.vertical, 4)
                            }
                            .tint(.secondary)
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("PasteFlowSnippetsImported"))) { _ in
            viewContext.refreshAllObjects()
            refreshToggle.toggle()
        }
    }
    
    private var allSnippetsEmpty: Bool {
        folders.allSatisfy { $0.snippetsArray.isEmpty }
    }
    
    private func pasteSnippet(_ snippet: CDSnippet) {
        guard let raw = snippet.rawString else { return }
        let processed = PlaceholderProcessor.shared.process(raw)
        PasteEngine.shared.paste(text: processed)
    }
}

struct SnippetRow: View {
    @ObservedObject var snippet: CDSnippet
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "text.quote")
                .font(.system(size: 12))
                .foregroundColor(.accentColor)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(snippet.title ?? "snippets.untitled".localized)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
                
                if let raw = snippet.rawString {
                    Text(raw)
                        .font(.system(size: 10, design: .monospaced))
                        .lineLimit(1)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if let shortcut = snippet.shortcutTrigger, !shortcut.isEmpty {
                Text(shortcut)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(RoundedRectangle(cornerRadius: 4).fill(Color.accentColor.opacity(0.15)))
                    .foregroundColor(.accentColor)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovered ? Color.accentColor.opacity(0.12) : Color.clear)
        )
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
