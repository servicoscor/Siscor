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
            // Header Principal com Glassmorphism
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
        HStack(spacing: 16) {
            statusAndLogo
            Spacer()
            languageMenuButton
            alertsButton
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .padding(.top, 130)
        .background(GlassBackground())
        .shadow(color: Color.black.opacity(0.5), radius: 10, x: 0, y: 5)
    }
    
    private var statusAndLogo: some View {
        HStack(spacing: 12) {
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
        VStack(alignment: .leading, spacing: 2) {
            Image("logocordeitado")
                .resizable()
                .scaledToFit()
                .frame(height: 40)
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
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
            
            Text(currentLanguageFlag)
                .font(.system(size: 20))
                .animation(.none, value: localizationManager.currentLanguage)
        }
    }
    
    private var currentLanguageFlag: String {
        languages.first { $0.0 == localizationManager.currentLanguage }?.1 ?? "🌐"
    }
    
    private var currentLanguageName: String {
        languages.first { $0.0 == localizationManager.currentLanguage }?.2 ?? "Language"
    }
    
    private var eventsButton: some View {
        Button(action: {
            // Chama a closure se ela existir
            if let scrollToEvents = scrollToEvents {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    scrollToEvents()
                }
            } else {
                print("scrollToEvents não foi definido")
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }) {
            ZStack {
                buttonBackground
                
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .symbolRenderingMode(.hierarchical)
                
                if eventCount > 0 {
                    eventBadge
                }
            }
        }
        .accessibilityLabel(localizationManager.string(for: "city_events"))
        .accessibilityHint(String(format: localizationManager.string(for: "events_count_hint"), eventCount))
        .accessibilityAddTraits(.isButton)
    }
    
    private var alertsButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                showNotifications.toggle()
            }
            
            // Chama a closure se ela existir
            if let scrollToAlerts = scrollToAlerts {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    scrollToAlerts()
                }
            } else {
                print("scrollToAlerts não foi definido")
            }
            
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }) {
            ZStack {
                alertButtonBackground
                
                Image(systemName: alertCount > 0 ? "bell.badge.fill" : "bell.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .symbolRenderingMode(.hierarchical)
                    .symbolEffect(.bounce, value: alertCount)
                
                if alertCount > 0 {
                    alertBadge
                }
            }
        }
        .scaleEffect(showNotifications ? 0.95 : 1.0)
        .accessibilityLabel(localizationManager.string(for: "alerts"))
        .accessibilityHint(String(format: localizationManager.string(for: "alerts_count_hint"), alertCount))
        .accessibilityAddTraits(.isButton)
        .accessibilityAddTraits(alertCount > 0 ? .startsMediaSession : [])
    }
    
    private var buttonBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.white.opacity(0.15))
            .frame(width: 44, height: 44)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
    }
    
    private var alertButtonBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(alertCount > 0 ? Color.red.opacity(0.15) : Color.white.opacity(0.15))
            .frame(width: 44, height: 44)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(alertCount > 0 ? Color.red.opacity(0.5) : Color.white.opacity(0.3), lineWidth: 1)
            )
    }
    
    private var eventBadge: some View {
        ZStack {
            Circle()
                .fill(Color.purple)
                .frame(width: 18, height: 18)
            
            Text("\(eventCount)")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
        }
        .offset(x: 14, y: -14)
        .transition(.scale.combined(with: .opacity))
    }
    
    private var alertBadge: some View {
        ZStack {
            Circle()
                .fill(Color.red)
                .frame(width: 18, height: 18)
            
            Text("\(alertCount)")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
        }
        .offset(x: 14, y: -14)
        .transition(.scale.combined(with: .opacity))
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
