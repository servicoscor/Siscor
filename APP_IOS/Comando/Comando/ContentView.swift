import SwiftUI

@main
struct CORRioApp: App {
    @StateObject private var viewModel = CORViewModel()
    @StateObject private var favoritesManager = FavoritesManager.shared
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var body: some Scene {
        WindowGroup {
            StatusPrincipalView()
                .environmentObject(viewModel)
                .environmentObject(favoritesManager)
                .environmentObject(localizationManager)
                .onAppear {
                    // Usa o método correto que existe no CORViewModel
                    viewModel.fetchInitialData()
                    
                    // Debug dos favoritos
                    favoritesManager.printDebugInfo()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                    // Salva quando o app vai para background
                    print("📱 App entrando em background...")
                    favoritesManager.printDebugInfo()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    // Recarrega quando o app volta do background
                    print("📱 App voltando ao foreground...")
                    favoritesManager.forceReload()
                    favoritesManager.printDebugInfo()
                    // O CORViewModel já tem sua própria lógica para recarregar quando volta do background
                }
        }
    }
}
