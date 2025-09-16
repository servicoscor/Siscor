import Foundation
import SwiftUI

// MARK: - Gerenciador de Favoritos com Persistência Garantida
class FavoritesManager: ObservableObject {
    /// Instância compartilhada para acesso global (Singleton).
    static let shared = FavoritesManager()
    
    /// A propriedade `@Published` notifica a UI sobre qualquer mudança.
    /// O `didSet` garante que qualquer alteração seja salva imediatamente.
    @Published var favoriteCameraIds: Set<UUID> = [] {
        didSet {
            saveFavorites()
        }
    }
    
    // Use uma chave única para evitar conflitos
    private let favoritesKey = "com.cocr.favoriteCameraIds"
    private let userDefaults = UserDefaults.standard
    
    /// O inicializador é privado para garantir que apenas uma instância seja criada.
    private init() {
        loadFavorites()
        
        // Adiciona observador para salvar quando o app entrar em background
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        
        // Adiciona observador para salvar quando o app for terminado
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillTerminate),
            name: UIApplication.willTerminateNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Métodos de Ciclo de Vida do App
    
    @objc private func appWillResignActive() {
        saveFavorites()
        userDefaults.synchronize() // Força sincronização
    }
    
    @objc private func appWillTerminate() {
        saveFavorites()
        userDefaults.synchronize() // Força sincronização
    }
    
    // MARK: - Lógica de Persistência (Salvar e Carregar)
    
    /// Salva o conjunto atual de IDs de favoritos no UserDefaults.
    private func saveFavorites() {
        do {
            // Converte o Set<UUID> para um Array<String> para um salvamento seguro em JSON.
            let idsArray = Array(favoriteCameraIds.map { $0.uuidString })
            let data = try JSONEncoder().encode(idsArray)
            userDefaults.set(data, forKey: favoritesKey)
            
            // Força a sincronização imediata
            let saved = userDefaults.synchronize()
            
            print("✅ Favoritos salvos com sucesso: \(idsArray.count) câmeras. Sincronizado: \(saved)")
            
            // Debug: Verifica se foi realmente salvo
            if let savedData = userDefaults.data(forKey: favoritesKey),
               let savedIds = try? JSONDecoder().decode([String].self, from: savedData) {
                print("✅ Verificação: \(savedIds.count) favoritos confirmados no UserDefaults")
            }
        } catch {
            print("❌ Erro ao salvar favoritos: \(error.localizedDescription)")
        }
    }
    
    /// Carrega os IDs de favoritos do UserDefaults ao iniciar.
    private func loadFavorites() {
        // Primeiro, tenta carregar com a nova chave
        if let data = userDefaults.data(forKey: favoritesKey) {
            do {
                let idsArray = try JSONDecoder().decode([String].self, from: data)
                let uuids = idsArray.compactMap { UUID(uuidString: $0) }
                self.favoriteCameraIds = Set(uuids)
                print("✅ Favoritos carregados: \(uuids.count) câmeras.")
                return
            } catch {
                print("❌ Erro ao decodificar favoritos: \(error.localizedDescription)")
            }
        }
        
        // Se não encontrou com a nova chave, tenta migrar da chave antiga
        tryMigrateLegacyFavorites()
    }
    
    /// Tenta migrar favoritos de uma chave antiga
    private func tryMigrateLegacyFavorites() {
        let oldKey = "favoriteCameraIds"
        
        if let oldData = userDefaults.data(forKey: oldKey) {
            do {
                // Tenta primeiro como Array<String>
                if let idsArray = try? JSONDecoder().decode([String].self, from: oldData) {
                    let uuids = idsArray.compactMap { UUID(uuidString: $0) }
                    self.favoriteCameraIds = Set(uuids)
                    print("✅ Migração de favoritos (formato Array) concluída: \(uuids.count) câmeras.")
                }
                // Se falhar, tenta como Set<UUID> (formato antigo)
                else if let legacyIds = try? JSONDecoder().decode(Set<UUID>.self, from: oldData) {
                    self.favoriteCameraIds = legacyIds
                    print("✅ Migração de favoritos (formato Set) concluída: \(legacyIds.count) câmeras.")
                }
                
                // Salva com a nova chave e remove a antiga
                saveFavorites()
                userDefaults.removeObject(forKey: oldKey)
                userDefaults.synchronize()
                
            } catch {
                print("❌ Falha na migração de favoritos antigos.")
            }
        } else {
            print("📭 Nenhum favorito salvo encontrado. Iniciando com lista vazia.")
        }
    }
    
    // MARK: - Métodos Públicos para Manipulação de Favoritos
    
    /// Adiciona ou remove uma câmera da lista de favoritos.
    func toggleFavorite(_ cameraId: UUID) {
        if favoriteCameraIds.contains(cameraId) {
            favoriteCameraIds.remove(cameraId)
            print("➖ Câmera removida dos favoritos: \(cameraId)")
        } else {
            favoriteCameraIds.insert(cameraId)
            print("➕ Câmera adicionada aos favoritos: \(cameraId)")
        }
    }
    
    /// Adiciona uma câmera aos favoritos.
    func addFavorite(_ cameraId: UUID) {
        favoriteCameraIds.insert(cameraId)
        print("➕ Câmera adicionada aos favoritos: \(cameraId)")
    }
    
    /// Remove uma câmera dos favoritos.
    func removeFavorite(_ cameraId: UUID) {
        favoriteCameraIds.remove(cameraId)
        print("➖ Câmera removida dos favoritos: \(cameraId)")
    }
    
    /// Verifica se uma câmera específica está na lista de favoritos.
    func isFavorite(_ cameraId: UUID) -> Bool {
        return favoriteCameraIds.contains(cameraId)
    }
    
    // MARK: - Utilitários e Debug
    
    /// Propriedade computada para obter os IDs como um array de Strings ordenado.
    var favoriteCameraIdsArray: [String] {
        return Array(favoriteCameraIds.map { $0.uuidString }).sorted()
    }
    
    /// Força o recarregamento dos favoritos do UserDefaults
    func forceReload() {
        loadFavorites()
        print("🔄 Favoritos recarregados forçadamente")
    }
    
    /// Imprime informações de depuração sobre o estado atual dos favoritos.
    func printDebugInfo() {
        print("========================")
        print("  Debug dos Favoritos")
        print("------------------------")
        print("Total de favoritos em memória: \(favoriteCameraIds.count)")
        print("IDs em memória: \(favoriteCameraIdsArray)")
        
        // Verifica o que está salvo no UserDefaults
        if let data = userDefaults.data(forKey: favoritesKey),
           let savedIds = try? JSONDecoder().decode([String].self, from: data) {
            print("Total de favoritos salvos: \(savedIds.count)")
            print("IDs salvos: \(savedIds)")
        } else {
            print("⚠️ Nenhum dado encontrado no UserDefaults")
        }
        
        print("========================")
    }
    
    /// Limpa todos os favoritos (útil para debug)
    func clearAllFavorites() {
        favoriteCameraIds.removeAll()
        print("🗑️ Todos os favoritos foram removidos")
    }
}

// MARK: - Extensão para facilitar a injeção do `FavoritesManager` em Views do SwiftUI.
extension View {
    func withFavoritesManager() -> some View {
        self.environmentObject(FavoritesManager.shared)
    }
}
