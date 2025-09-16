import Foundation
import SwiftUI

// MARK: - LocalizationManager
class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    // Publica mudanças quando o idioma muda
    @Published var currentLanguage: String {
        didSet {
            if currentLanguage != oldValue {
                print("🌐 Language changed from \(oldValue) to \(currentLanguage)")
                UserDefaults.standard.set(currentLanguage, forKey: "AppLanguage")
                UserDefaults.standard.synchronize() // Força salvamento imediato
                
                // Força atualização da UI
                DispatchQueue.main.async {
                    self.objectWillChange.send()
                }
                
                // Notifica toda a aplicação
                NotificationCenter.default.post(
                    name: NSNotification.Name("LanguageChanged"),
                    object: nil,
                    userInfo: ["language": currentLanguage]
                )
            }
        }
    }
    
    // Bundle atual baseado no idioma selecionado
    private var bundle: Bundle {
        // First, try to find the exact match in available localizations
        let availableLocalizations = Bundle.main.localizations
        print("🔍 Looking for bundle for language: \(currentLanguage)")
        print("📦 Available localizations: \(availableLocalizations)")
        
        // Try different variations of the language code
        let possibleBundleNames = getPossibleBundleNames(for: currentLanguage)
        
        for bundleName in possibleBundleNames {
            if availableLocalizations.contains(bundleName) {
                if let path = Bundle.main.path(forResource: bundleName, ofType: "lproj"),
                   let bundle = Bundle(path: path) {
                    print("✅ Successfully loaded bundle for language: \(currentLanguage) using: \(bundleName)")
                    return bundle
                }
            }
        }
        
        // If no bundle found, try a direct path check for all variations
        for bundleName in possibleBundleNames {
            if let path = Bundle.main.path(forResource: bundleName, ofType: "lproj"),
               let bundle = Bundle(path: path) {
                print("✅ Successfully loaded bundle for language: \(currentLanguage) using direct path: \(bundleName)")
                return bundle
            }
        }
        
        print("⚠️ Failed to load bundle for language: \(currentLanguage). Tried: \(possibleBundleNames)")
        return Bundle.main
    }
    
    // Get all possible bundle names for a language code
    private func getPossibleBundleNames(for languageCode: String) -> [String] {
        var names: [String] = []
        
        switch languageCode {
        case "pt":
            names = ["Portuguese", "pt", "pt-BR", "pt-PT", "pt_BR", "pt_PT"]
        case "en":
            names = ["en", "English", "en-US", "en_US", "Base"]
        case "es":
            names = ["Spanish", "es", "es-ES", "es_ES", "es-MX", "es_MX"]
        case "fr":
            names = ["fr", "French", "fr-FR", "fr_FR"]
        case "zh-Hans":
            names = ["Chinese, Simplified", "zh-Hans", "zh_Hans", "zh-CN", "zh_CN", "Chinese (Simplified)"]
        default:
            names = [languageCode]
        }
        
        return names
    }
    
    private init() {
        // Carrega o idioma salvo ou usa o padrão do sistema
        if let savedLanguage = UserDefaults.standard.string(forKey: "AppLanguage") {
            self.currentLanguage = savedLanguage
        } else {
            // Detecta o idioma do sistema baseado nas localizações disponíveis
            let availableLocalizations = Bundle.main.localizations
            let preferredLanguage = Bundle.main.preferredLocalizations.first ?? "en"
            
            print("🌍 System language: \(preferredLanguage)")
            print("📦 Available localizations: \(availableLocalizations)")
            
            // Mapeia para os idiomas suportados
            if preferredLanguage.contains("Portuguese") || preferredLanguage.hasPrefix("pt") {
                self.currentLanguage = "pt"
            } else if preferredLanguage.contains("Spanish") || preferredLanguage.hasPrefix("es") {
                self.currentLanguage = "es"
            } else if preferredLanguage.hasPrefix("fr") {
                self.currentLanguage = "fr"
            } else if preferredLanguage.contains("Chinese") || preferredLanguage.hasPrefix("zh") {
                self.currentLanguage = "zh-Hans"
            } else {
                self.currentLanguage = "en"
            }
            
            print("🔤 Selected language code: \(self.currentLanguage)")
        }
        
        // Debug info on init
        printDebugInfo()
    }
    
    // Função principal para obter strings localizadas
    func string(for key: String) -> String {
        let localizedString = bundle.localizedString(forKey: key, value: nil, table: nil)
        
        // Debug: se a string retornada for igual à chave, significa que não foi encontrada
        if localizedString == key {
            print("⚠️ Missing translation for key '\(key)' in language '\(currentLanguage)'")
            
            // Try fallback to main bundle
            let fallbackString = Bundle.main.localizedString(forKey: key, value: nil, table: nil)
            if fallbackString != key {
                print("📌 Found fallback translation in main bundle")
                return fallbackString
            }
        }
        
        return localizedString
    }
    
    // Função para strings com formato
    func string(for key: String, arguments: CVarArg...) -> String {
        let format = string(for: key)
        return String(format: format, arguments: arguments)
    }
    
    // Função para mudar o idioma programaticamente
    func setLanguage(_ languageCode: String) {
        currentLanguage = languageCode
    }
    
    // Lista de idiomas suportados
    static let supportedLanguages = [
        ("pt", "🇧🇷", "Português"),
        ("en", "🇺🇸", "English"),
        ("es", "🇪🇸", "Español"),
        ("fr", "🇫🇷", "Français"),
        ("zh-Hans", "🇨🇳", "中文")
    ]
    
    // Verifica se um idioma é suportado
    func isLanguageSupported(_ code: String) -> Bool {
        return Self.supportedLanguages.contains { $0.0 == code }
    }
    
    // Obtém informações do idioma atual
    var currentLanguageInfo: (code: String, flag: String, name: String)? {
        return Self.supportedLanguages.first { $0.0 == currentLanguage }
    }
}

// MARK: - View Modifier para Atualização Automática
struct LocalizedView: ViewModifier {
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var updateTrigger = UUID()
    
    func body(content: Content) -> some View {
        content
            .id(updateTrigger) // Usa UUID para forçar redesenho completo
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LanguageChanged"))) { _ in
                // Força atualização da view com novo UUID
                print("📱 Updating UI for language change")
                updateTrigger = UUID()
            }
    }
}

extension View {
    func localized() -> some View {
        self.modifier(LocalizedView())
    }
}

// MARK: - String Extension para Facilitar Uso
extension String {
    var localized: String {
        return LocalizationManager.shared.string(for: self)
    }
    
    func localized(with arguments: CVarArg...) -> String {
        let format = LocalizationManager.shared.string(for: self)
        return String(format: format, arguments: arguments)
    }
}

// MARK: - Environment Key para Injeção de Dependência
struct LocalizationManagerKey: EnvironmentKey {
    static let defaultValue = LocalizationManager.shared
}

extension EnvironmentValues {
    var localizationManager: LocalizationManager {
        get { self[LocalizationManagerKey.self] }
        set { self[LocalizationManagerKey.self] = newValue }
    }
}

// MARK: - Preview Helper
struct LocalizationPreview<Content: View>: View {
    let content: () -> Content
    let language: String
    
    init(language: String, @ViewBuilder content: @escaping () -> Content) {
        self.language = language
        self.content = content
        
        // Temporariamente muda o idioma para preview
        LocalizationManager.shared.setLanguage(language)
    }
    
    var body: some View {
        content()
            .environment(\.locale, Locale(identifier: language))
    }
}

// MARK: - Debug Helper
extension LocalizationManager {
    func printDebugInfo() {
        print("=== LocalizationManager Debug Info ===")
        print("Current Language: \(currentLanguage)")
        print("Available Localizations: \(Bundle.main.localizations)")
        print("Preferred Localizations: \(Bundle.main.preferredLocalizations)")
        print("Development Region: \(Bundle.main.developmentLocalization ?? "nil")")
        
        // Testa uma string conhecida
        let testString = string(for: "app_title")
        print("Test String (app_title): \(testString)")
        
        // Verifica se os arquivos .lproj existem para todas as variações possíveis
        for lang in Self.supportedLanguages {
            let possibleNames = getPossibleBundleNames(for: lang.0)
            var found = false
            
            for bundleName in possibleNames {
                if let path = Bundle.main.path(forResource: bundleName, ofType: "lproj") {
                    print("✅ Found \(lang.0) as \(bundleName).lproj at: \(path)")
                    found = true
                    break
                }
            }
            
            if !found {
                print("❌ Missing bundle for \(lang.0). Tried: \(possibleNames)")
            }
        }
        print("=====================================")
    }
    
    // Additional helper to check what's actually in the bundle
    func listAllBundleContents() {
        print("=== Bundle Contents ===")
        if let resourcePath = Bundle.main.resourcePath {
            do {
                let contents = try FileManager.default.contentsOfDirectory(atPath: resourcePath)
                let lprojFolders = contents.filter { $0.hasSuffix(".lproj") }
                print("Found .lproj folders: \(lprojFolders)")
            } catch {
                print("Error listing bundle contents: \(error)")
            }
        }
        print("=====================")
    }
}
