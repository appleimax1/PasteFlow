import SwiftUI

struct PopupRootView: View {
    @ObservedObject var controller: MenuBarController
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Bar with Segmented Control
            HStack {
                Picker("", selection: $controller.selectedTab) {
                    Label("История", systemImage: "clock").tag(0)
                    Label("Сниппеты", systemImage: "square.grid.2x2").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 8)
            .background(Color(NSColor.windowBackgroundColor).opacity(0.6))
            
            Divider()
            
            // Tab Contents
            if controller.selectedTab == 0 {
                ClipboardHistoryView()
            } else {
                SnippetMenuView()
            }
            
            Divider()
            
            // Bottom Toolbar
            HStack(spacing: 12) {
                Button(action: { controller.openPreferences() }) {
                    Label("Настройки", systemImage: "gearshape.fill")
                        .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(PlainButtonStyle())
                .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: { controller.openSnippetManager() }) {
                    Label("Сниппеты", systemImage: "square.and.pencil")
                        .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(PlainButtonStyle())
                .foregroundColor(.accentColor)
                
                Spacer()
                
                Button(action: quitApp) {
                    Image(systemName: "power")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Завершить PasteFlow")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(NSColor.windowBackgroundColor).opacity(0.8))
        }
        .frame(width: 350, height: 470)
        .background(.ultraThinMaterial)
    }
    
    private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
