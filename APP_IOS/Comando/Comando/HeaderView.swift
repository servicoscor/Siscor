import SwiftUI

// MARK: - HeaderView com Localização
struct HeaderView: View {
    @State private var pulseAnimation = false
    @State private var emergencyPulse = false
    @State private var showNotifications = false
    @State private var showLanguageMenu = false
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    // Props opcionais para integração
    var currentStage: Int = 1
    var alertCount: Int = 3
    var eventCount: Int = 0
    var temperature: String? = nil
    
    // Closures para ações
    var scrollToAlerts: (() -> Void)?
    var scrollToEvents: (() -> Void)?
    
    // Idiomas disponíveis
    private let languages = [
        ("pt-BR", "🇧🇷", "Português"),
        ("en", "🇺🇸", "English"),
        ("es", "🇪🇸", "Español"),
        ("fr", "🇫🇷", "Français"),
        ("zh-Hans", "🇨🇳", "中文")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Principal com fundo material nativo (substitui GlassBackground)
            headerContent
            
            // Status do estágio (aparece em emergências)
            if currentStage >= 3 {
                emergencyStatusBar
            }
        }
        .onAppear {
            startAnimations()
        }
        .overlay(emergencyOverlay)
    }
    
    // MARK: - Subviews
    
    private var headerContent: some View {
        HStack(spacing: 12) {
            statusAndLogo
            Spacer()
            languageMenuButton
            stageStatusButton // Substitui o antigo alertsButton
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            // Substituto para GlassBackground
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0.15),
                        Color.black.opacity(0.05)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        )
        .shadow(color: Color.black.opacity(0.5), radius: 10, x: 0, y: 5)
    }
    
    private var statusAndLogo: some View {
        HStack(spacing: 10) {
            // Círculo de status com pulso
            statusCircle
            
            // Logo
            logoImage
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(localizationManager.string(for: "app_title"))
        .accessibilityHint(localizationManager.string(for: "city_stage") + " \(currentStage)")
    }
    
    private var statusCircle: some View {
        Circle()
            .fill(colorForStage(currentStage))
            .frame(width: 12, height: 12)
            .overlay(
                Circle()
                    .stroke(colorForStage(currentStage), lineWidth: 2)
                    .scaleEffect(pulseAnimation ? (1.5 + CGFloat(currentStage) * 0.25) : 1)
                    .opacity(pulseAnimation ? 0 : 1)
            )
    }
    
    private var logoImage: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image("logocordeitado")
                .resizable()
                .scaledToFit()
                .frame(height: 28)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
        }
    }
    
    private var languageMenuButton: some View {
        Menu {
            ForEach(languages, id: \.0) { lang in
                Button(action: {
                    selectLanguage(lang.0)
                }) {
                    HStack {
                        Text(lang.1) // Bandeira
                        Text(lang.2) // Nome do idioma
                            .foregroundColor(.primary)
                        Spacer()
                        if localizationManager.currentLanguage == lang.0 {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
            }
        } label: {
            currentLanguageLabel
        }
        .accessibilityLabel(localizationManager.string(for: "language_selector"))
        .accessibilityHint(localizationManager.string(for: "change_language_hint"))
    }
    
    private var currentLanguageLabel: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.15))
                .frame(width: 36, height: 36)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
            
            Text(currentLanguageFlag)
                .font(.system(size: 16))
                .animation(.none, value: localizationManager.currentLanguage)
        }
    }
    
    private var currentLanguageFlag: String {
        languages.first { $0.0 == localizationManager.currentLanguage }?.1 ?? "🌐"
    }
    
    private var currentLanguageName: String {
        languages.first { $0.0 == localizationManager.currentLanguage }?.2 ?? "Language"
    }
    
    // NOVO: Botão do estágio (substitui o sino)
    private var stageStatusButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                showNotifications.toggle()
            }
            // Reaproveita a ação do sino: rolar para alertas
            if let scrollToAlerts = scrollToAlerts {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    scrollToAlerts()
                }
            }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }) {
            ZStack {
                // Fundo com vidro, igual aos outros botões
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 36, height: 36)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                
                // Imagem do estágio (selo localizado) ou fallback
                Group {
                    if let uiImage = stageImage(for: currentStage) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 28)
                            .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                    } else {
                        Image(systemName: "shield.fill")
                            .font(.system(size: 18))
                            .foregroundColor(colorForStage(currentStage))
                    }
                }
                
                // Efeito pulsante ao redor do botão (igual ao statusCircle)
                Circle()
                    .stroke(colorForStage(currentStage), lineWidth: 2)
                    .frame(width: 36, height: 36)
                    .scaleEffect(pulseAnimation ? (1.5 + CGFloat(currentStage) * 0.25) : 1.0)
                    .opacity(pulseAnimation ? 0 : 1)
            }
        }
        .scaleEffect(showNotifications ? 0.95 : 1.0)
        .accessibilityLabel(localizationManager.string(for: "emergency_status"))
        .accessibilityHint(statusForStage(currentStage) + ". " + shortDescriptionForStage(currentStage))
        .accessibilityAddTraits(.isButton)
    }
    
    private var emergencyStatusBar: some View {
        HStack(spacing: 8) {
            Image(systemName: iconForStage(currentStage))
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(colorForStage(currentStage))
                .symbolEffect(.pulse, value: currentStage >= 4)
            
            Text(statusForStage(currentStage))
                .font(.caption.bold())
                .foregroundColor(.white)
            
            Spacer()
            
            Text(shortDescriptionForStage(currentStage))
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(emergencyStatusBackground)
        .overlay(
            Rectangle()
                .fill(colorForStage(currentStage))
                .frame(height: 2),
            alignment: .bottom
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(localizationManager.string(for: "emergency_status"))
        .accessibilityValue(statusForStage(currentStage) + ". " + shortDescriptionForStage(currentStage))
    }
    
    private var emergencyStatusBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                colorForStage(currentStage).opacity(0.3),
                colorForStage(currentStage).opacity(0.1)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    private var emergencyOverlay: some View {
        Group {
            if currentStage >= 4 {
                Circle()
                    .stroke(Color.red, lineWidth: 2)
                    .frame(width: 40, height: 40)
                    .scaleEffect(emergencyPulse ? 2.5 : 1.0)
                    .opacity(emergencyPulse ? 0 : 1)
                    .animation(
                        Animation.easeOut(duration: 1.0).repeatForever(autoreverses: false),
                        value: emergencyPulse
                    )
                    .position(x: 50, y: 50)
                    .onAppear {
                        emergencyPulse = true
                    }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func startAnimations() {
        withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulseAnimation = true
        }
    }
    
    private func selectLanguage(_ code: String) {
        withAnimation(.spring(response: 0.3)) {
            localizationManager.currentLanguage = code
            UserDefaults.standard.set(code, forKey: "AppLanguage")
            NotificationCenter.default.post(
                name: NSNotification.Name("LanguageChanged"),
                object: nil
            )
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
    
    // MARK: - Funções Auxiliares
    
    private func colorForStage(_ stage: Int) -> Color {
        switch stage {
        case 1: return .green
        case 2: return .yellow
        case 3: return .orange
        case 4: return .red
        case 5: return .purple
        default: return .gray
        }
    }
    
    private func iconForStage(_ stage: Int) -> String {
        switch stage {
        case 1: return "checkmark.circle.fill"
        case 2: return "exclamationmark.circle.fill"
        case 3: return "exclamationmark.triangle.fill"
        case 4: return "exclamationmark.octagon.fill"
        case 5: return "xmark.octagon.fill"
        default: return "questionmark.circle.fill"
        }
    }
    
    private func statusForStage(_ stage: Int) -> String {
        // Usa o sistema de localização para os status
        switch stage {
        case 1: return localizationManager.string(for: "stage_1_status")
        case 2: return localizationManager.string(for: "stage_2_status")
        case 3: return localizationManager.string(for: "stage_3_status")
        case 4: return localizationManager.string(for: "stage_4_status")
        case 5: return localizationManager.string(for: "stage_5_status")
        default: return localizationManager.string(for: "stage_operational")
        }
    }
    
    private func shortDescriptionForStage(_ stage: Int) -> String {
        // Usa descrições curtas localizadas
        switch stage {
        case 1: return localizationManager.string(for: "stage_1_short")
        case 2: return localizationManager.string(for: "stage_2_short")
        case 3: return localizationManager.string(for: "stage_3_short")
        case 4: return localizationManager.string(for: "stage_4_short")
        case 5: return localizationManager.string(for: "stage_5_short")
        default: return ""
        }
    }
    
    // MARK: - NOVO: Utilitários para imagem do estágio (replicado do EstagioView)
    private func stageImage(for stage: Int) -> UIImage? {
        let name = getStageImageName(for: stage)
        return UIImage(named: name)
    }
    
    private func getStageImageName(for stage: Int) -> String {
        let languageCode = localizationManager.currentLanguage
        
        // Define o sufixo do idioma
        let languageSuffix: String
        switch languageCode {
        case "pt-BR":
            languageSuffix = "" // Sem sufixo para português
        case "en":
            languageSuffix = "-en"
        case "es":
            languageSuffix = "-es"
        case "fr":
            languageSuffix = "-fr"
        case "zh-Hans":
            languageSuffix = "-zh"
        default:
            languageSuffix = "" // fallback sem sufixo
        }
        
        // Retorna o nome da imagem
        switch stage {
        case 1: return "selo-cidade-estagio-01\(languageSuffix)"
        case 2: return "selo-cidade-estagio-02\(languageSuffix)"
        case 3: return "selo-cidade-estagio-03\(languageSuffix)"
        case 4: return "selo-cidade-estagio-04\(languageSuffix)"
        case 5: return "selo-cidade-estagio-05\(languageSuffix)"
        default: return "selo-cidade-estagio-01\(languageSuffix)"
        }
    }
}



// MARK: - Preview
struct HeaderView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Preview em diferentes idiomas
            ForEach(["pt-BR", "en", "es", "fr", "zh-Hans"], id: \.self) { language in
                VStack {
                    HeaderView(
                        currentStage: 3,
                        alertCount: 5,
                        eventCount: 2,
                        temperature: "28°",
                        scrollToAlerts: {
                            print("Scroll to alerts funcionando!")
                        },
                        scrollToEvents: {
                            print("Scroll to events funcionando!")
                        }
                    )
                    .environment(\.locale, Locale(identifier: language))
                    
                    Spacer()
                }
                .background(
                    Image("weather-background")
                        .resizable()
                        .scaledToFill()
                        .overlay(Color.black.opacity(0.3))
                )
                .previewDisplayName("Language: \(language)")
            }
        }
    }
}

// MARK: - Exemplo de uso no StatusAlertaView
/*
 Certifique-se de que no StatusAlertaView você está passando as closures corretamente:
 
 HeaderView(
     currentStage: currentStage,
     alertCount: alertasViewModel.alertas.count,
     eventCount: eventos.count,
     temperature: "28°",
     scrollToAlerts: {
         withAnimation(.easeInOut(duration: 0.5)) {
             scrollProxy.scrollTo("alertasSection", anchor: .top)
         }
     },
     scrollToEvents: {
         withAnimation(.easeInOut(duration: 0.5)) {
             scrollProxy.scrollTo("eventosSection", anchor: .top)
         }
     }
 )
*/
