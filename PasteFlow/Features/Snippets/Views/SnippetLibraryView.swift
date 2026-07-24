import SwiftUI
import CoreData

struct SnippetLibraryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CDSnippetFolder.sortOrder, ascending: true)],
        animation: .easeInOut)
    private var folders: FetchedResults<CDSnippetFolder>
    
    @State private var selectedFolder: CDSnippetFolder?
    @State private var selectedSnippet: CDSnippet?
    @State private var refreshToggle = false
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedFolder) {
                Section(header: Text("Папки").font(.system(size: 11, weight: .bold))) {
                    ForEach(folders) { folder in
                        NavigationLink(value: folder) {
                            HStack {
                                Label(folder.name ?? "Новая папка", systemImage: folder.sfSymbolName ?? "folder.fill")
                                Spacer()
                                Text("\(folder.snippetsArray.count)")
                                    .font(.system(size: 10, weight: .bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Color.secondary.opacity(0.15)))
                            }
                        }
                        .contextMenu {
                            Button(role: .destructive, action: { deleteFolder(folder) }) {
                                Label("Удалить папку", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .listStyle(SidebarListStyle())
            .navigationTitle("Папки сниппетов")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: addFolder) {
                        Label("Новая папка", systemImage: "folder.badge.plus")
                    }
                }
            }
        } content: {
            if let folder = selectedFolder {
                List(selection: $selectedSnippet) {
                    Section(header: Text(folder.name ?? "Сниппеты в папке").font(.system(size: 11, weight: .bold))) {
                        ForEach(folder.snippetsArray) { snippet in
                            NavigationLink(value: snippet) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(snippet.title ?? "Без названия")
                                        .font(.system(size: 12, weight: .medium))
                                    if let trigger = snippet.shortcutTrigger, !trigger.isEmpty {
                                        Text(trigger)
                                            .font(.system(size: 10, design: .monospaced))
                                            .foregroundColor(.accentColor)
                                    }
                                }
                            }
                            .contextMenu {
                                Button(role: .destructive, action: { deleteSnippet(snippet) }) {
                                    Label("Удалить сниппет", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
                .navigationTitle(folder.name ?? "Сниппеты")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: { addSnippet(in: folder) }) {
                            Label("Новый сниппет", systemImage: "plus")
                        }
                    }
                }
            } else {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "folder")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("Выберите или создайте папку")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        } detail: {
            if let snippet = selectedSnippet {
                SnippetEditorView(snippet: snippet)
            } else {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "doc.text")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("Выберите сниппет для редактирования")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
        .onAppear {
            if selectedFolder == nil, let first = folders.first {
                selectedFolder = first
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("PasteFlowSnippetsImported"))) { _ in
            viewContext.refreshAllObjects()
            refreshToggle.toggle()
            if selectedFolder == nil, let first = folders.first {
                selectedFolder = first
            }
        }
    }
    
    private func addFolder() {
        let folder = SnippetManager.shared.createFolder(name: "Новая папка \(folders.count + 1)")
        selectedFolder = folder
    }
    
    private func deleteFolder(_ folder: CDSnippetFolder) {
        SnippetManager.shared.delete(object: folder)
        if selectedFolder == folder {
            selectedFolder = nil
        }
    }
    
    private func addSnippet(in folder: CDSnippetFolder) {
        let snippet = SnippetManager.shared.createSnippet(in: folder, title: "Новый сниппет", content: "Привет {CLIPBOARD}")
        selectedSnippet = snippet
    }
    
    private func deleteSnippet(_ snippet: CDSnippet) {
        SnippetManager.shared.delete(object: snippet)
        if selectedSnippet == snippet {
            selectedSnippet = nil
        }
    }
}
