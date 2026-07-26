import SwiftUI
import CoreData

struct ClipboardHistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \CDClipboardEntry.isPinned, ascending: false),
            NSSortDescriptor(keyPath: \CDClipboardEntry.createdAt, ascending: false)
        ],
        animation: .easeInOut)
    private var entries: FetchedResults<CDClipboardEntry>
    
    @State private var searchText = ""
    @State private var hoveredEntry: CDClipboardEntry?
    @State private var hoveredIndex: Int?
    @State private var expandedGroups: Set<Int> = [0]
    
    @AppStorage("PasteFlow.FolderGroupingSize") private var folderGroupingSize = 10
    
    var body: some View {
        VStack(spacing: 0) {
            // Поисковая строка
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 13))
                
                TextField("popup.search_history".localized, text: $searchText)
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
            
            if filteredEntries.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "clipboard")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary.opacity(0.6))
                    Text(searchText.isEmpty ? "popup.history_empty".localized : "popup.nothing_found".localized)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                // Список занимает оставшееся место
                ScrollViewReader { scrollProxy in
                    List {
                        if folderGroupingSize == 0 {
                            ForEach(Array(filteredEntries.enumerated()), id: \.element.id) { absoluteIndex, entry in
                                rowForEntry(entry, absoluteIndex: absoluteIndex)
                            }
                        } else {
                            ForEach(Array(groupedEntries.enumerated()), id: \.offset) { groupIndex, chunk in
                                DisclosureGroup(
                                    isExpanded: Binding(
                                        get: { expandedGroups.contains(groupIndex) },
                                        set: { isExpanded in
                                            if isExpanded { expandedGroups.insert(groupIndex) }
                                            else { expandedGroups.remove(groupIndex) }
                                        }
                                    )
                                ) {
                                    ForEach(Array(chunk.enumerated()), id: \.element.id) { indexInChunk, entry in
                                        let absoluteIndex = groupIndex * folderGroupingSize + indexInChunk
                                        rowForEntry(entry, absoluteIndex: absoluteIndex)
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "folder.fill")
                                            .foregroundColor(.accentColor)
                                        Text(String(format: "popup.history_folder_range".localized, groupIndex * folderGroupingSize + 1, min((groupIndex + 1) * folderGroupingSize, filteredEntries.count)))
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
        }
        .onDisappear {
            HoverPreviewPanel.shared.hide()
        }
    }
    
    var filteredEntries: [CDClipboardEntry] {
        if searchText.isEmpty {
            return Array(entries)
        } else {
            return entries.filter { entry in
                entry.displayTitle.localizedCaseInsensitiveContains(searchText) ||
                (entry.rawString?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (entry.sourceAppName?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    var groupedEntries: [[CDClipboardEntry]] {
        let entries = filteredEntries
        let size = folderGroupingSize == 0 ? entries.count : folderGroupingSize
        guard size > 0 else { return [] }
        
        var chunks: [[CDClipboardEntry]] = []
        for i in stride(from: 0, to: entries.count, by: size) {
            let chunk = Array(entries[i..<min(i + size, entries.count)])
            chunks.append(chunk)
        }
        return chunks
    }
    
    private func shortcutKey(for index: Int) -> String? {
        if index >= 0 && index < 9 {
            return "\(index + 1)"
        } else if index == 9 {
            return "0"
        }
        return nil
    }
    
    @ViewBuilder
    private func rowForEntry(_ entry: CDClipboardEntry, absoluteIndex: Int) -> some View {
        let shortcutKeyStr = shortcutKey(for: absoluteIndex)
        
        ClipboardEntryRow(
            entry: entry,
            shortcutDisplay: shortcutKeyStr,
            isHovered: hoveredIndex == absoluteIndex
        )
        .contentShape(Rectangle())
        .onHover { isHovering in
            if isHovering {
                hoveredEntry = entry
                hoveredIndex = absoluteIndex
                // Показываем плавающее превью-окно ниже попапа
                let window = NSApp.keyWindow ?? NSApp.windows.first
                HoverPreviewPanel.shared.show(entry: entry, relativeTo: window)
            } else if hoveredIndex == absoluteIndex {
                hoveredEntry = nil
                hoveredIndex = nil
                HoverPreviewPanel.shared.hide()
            }
        }
        .onTapGesture {
            let flags = NSEvent.modifierFlags
            let asPlainText = flags.contains(.shift)
            
            PasteEngine.shared.paste(entry: entry, asPlainText: asPlainText)
            
            if flags.contains(.option) {
                ClipboardHistoryManager.shared.deleteEntry(entry)
            }
        }
        .background(
            // Скрытая кнопка для шорткатов Cmd+1...Cmd+9 и Cmd+0 для 10-й записи
            Group {
                if let keyStr = shortcutKeyStr, let char = keyStr.first {
                    Button("") {
                        let flags = NSEvent.modifierFlags
                        let asPlainText = flags.contains(.shift)
                        PasteEngine.shared.paste(entry: entry, asPlainText: asPlainText)
                        if flags.contains(.option) {
                            ClipboardHistoryManager.shared.deleteEntry(entry)
                        }
                    }
                    .keyboardShortcut(KeyEquivalent(char), modifiers: .command)
                    .opacity(0)
                }
            }
        )
        .contextMenu {
            Button(action: { PasteEngine.shared.paste(entry: entry) }) {
                Label("popup.paste".localized, systemImage: "doc.on.clipboard")
            }
            Button(action: { PasteEngine.shared.paste(entry: entry, asPlainText: true) }) {
                Label("popup.paste_plain".localized, systemImage: "text.quote")
            }
            Divider()
            Button(action: { ClipboardHistoryManager.shared.togglePin(entry) }) {
                Label(entry.isPinned ? "popup.unpin".localized : "popup.pin".localized, systemImage: entry.isPinned ? "pin.slash" : "pin")
            }
            Button(role: .destructive, action: { ClipboardHistoryManager.shared.deleteEntry(entry) }) {
                Label("popup.delete".localized, systemImage: "trash")
            }
        }
        .onDrag {
            entry.itemProvider
        }
    }
    
    struct ClipboardEntryRow: View {
        @ObservedObject var entry: CDClipboardEntry
        let shortcutDisplay: String?
        let isHovered: Bool
        
        var body: some View {
            HStack(spacing: 10) {
                Image(systemName: entry.sfSymbolName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(entry.isPinned ? .orange : .accentColor)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.displayTitle)
                        .font(.system(size: 12))
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 6) {
                        if let appName = entry.sourceAppName {
                            Text(appName)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        
                        Text(entry.timeFormatted)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 6) {
                    if entry.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.orange)
                    }
                    
                    if let key = shortcutDisplay {
                        Text("⌘\(key)")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(RoundedRectangle(cornerRadius: 4).fill(Color.primary.opacity(0.08)))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered ? Color.accentColor.opacity(0.12) : Color.clear)
            )
        }
    }
}
