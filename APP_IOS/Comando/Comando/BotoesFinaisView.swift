import SwiftUI

// MARK: - ViewModel para gerenciar as ações dos botões
class BotoesViewModel: ObservableObject {
    
    // Função para ligar para a Defesa Civil (número 199)
    func ligarDefesaCivil() {
        if let url = URL(string: "tel://199") {
            UIApplication.shared.open(url)
        }
    }
    
    // Função para abrir redes sociais do Centro de Operações Rio
    func abrirRedesSociais() {
        // Cria um ActionSheet para escolher entre Instagram e Twitter
        let alert = UIAlertController(
            title: "Redes Sociais",
            message: "Escolha a rede social para acessar o Centro de Operações Rio:",
            preferredStyle: .actionSheet
        )
        
        // Botão Instagram
        alert.addAction(UIAlertAction(title: "📷 Instagram", style: .default) { _ in
            self.abrirInstagram()
        })
        
        // Botão Twitter/X
        alert.addAction(UIAlertAction(title: "🐦 Twitter/X", style: .default) { _ in
            self.abrirTwitter()
        })
        
        // Botão Cancelar
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        
        // Apresentar o ActionSheet
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            
            // Para iPad - configura o popover
            if let popover = alert.popoverPresentationController {
                popover.sourceView = window
                popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            rootViewController.present(alert, animated: true)
        }
    }
    
    private func abrirInstagram() {
        // Tenta abrir no app do Instagram primeiro
        let instagramAppURL = "instagram://user?username=centrooperacoesrio"
        let instagramWebURL = "https://www.instagram.com/centrooperacoesrio/"
        
        if let appURL = URL(string: instagramAppURL),
           UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL)
        } else if let webURL = URL(string: instagramWebURL) {
            UIApplication.shared.open(webURL)
        }
    }
    
    private func abrirTwitter() {
        // Tenta abrir no app do Twitter/X primeiro
        let twitterAppURL = "twitter://user?screen_name=OperacoesRio"
        let twitterWebURL = "https://twitter.com/OperacoesRio"
        
        if let appURL = URL(string: twitterAppURL),
           UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL)
        } else if let webURL = URL(string: twitterWebURL) {
            UIApplication.shared.open(webURL)
        }
    }
}

// MARK: - View da Grade de Botões
struct BotoesFinaisView: View {
    @StateObject private var viewModel = BotoesViewModel()
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var isAnimating = false
    @Binding var isUnidadesSaudeExpanded: Bool
    @Binding var isPontosTuristicosExpanded: Bool

    // Define o layout da grade com 2 colunas flexíveis
    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]
    
    // Gradiente comum para todos os botões
    private let cardGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 0.1, green: 0.5, blue: 0.9),
            Color(red: 0.3, green: 0.6, blue: 0.9)
        ]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    // Gradiente especial para redes sociais
    private let socialGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 0.1, green: 0.5, blue: 0.9),
            Color(red: 0.3, green: 0.6, blue: 0.9)
        ]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    var body: some View {
        VStack(alignment: .leading) {
            // Grade que organiza os botões
            LazyVGrid(columns: columns, spacing: 20) {
                FuncaoButton(
                    iconName: "phone.fill",
                    labelText: localizationManager.string(for: "call_civil_defense"),
                    cardGradient: cardGradient
                ) {
                    playHapticFeedback(.medium)
                    viewModel.ligarDefesaCivil()
                }
                
                FuncaoButton(
                    iconName: "camera.fill",
                    labelText: localizationManager.string(for: "tourist_spots"),
                    cardGradient: cardGradient
                ) {
                    playHapticFeedback(.medium)
                    isPontosTuristicosExpanded = true
                }
                
                FuncaoButton(
                    iconName: "cross.case.fill",
                    labelText: localizationManager.string(for: "health_units"),
                    cardGradient: cardGradient
                ) {
                    playHapticFeedback(.medium)
                    isUnidadesSaudeExpanded = true
                }
                
                FuncaoButton(
                    iconName: "heart.fill",
                    labelText: localizationManager.string(for: "social_networks"),
                    cardGradient: socialGradient
                ) {
                    playHapticFeedback(.medium)
                    viewModel.abrirRedesSociais()
                }
            }
            .padding()
        }
    }
    
    // Função para feedback tátil
    func playHapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}

// MARK: - Componente Reutilizável do Botão
struct FuncaoButton: View {
    let iconName: String
    let labelText: String
    let cardGradient: LinearGradient
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            
            // Atrasa a ação e reseta o estado
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                action()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
            }
        }) {
            ZStack {
                // Camada de fundo com o gradiente fornecido
                RoundedRectangle(cornerRadius: 15)
                    .fill(cardGradient)
                
                // Borda definida localmente
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                
                // Conteúdo do botão com layout padronizado
                VStack(alignment: .leading) {
                    // Container para o ícone com tamanho fixo
                    ZStack(alignment: .leading) {
                        Color.clear
                            .frame(height: 50)
                        
                        // Ícone do botão - aumentado
                        Image(systemName: iconName)
                            .font(.system(size: 40, weight: .semibold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                    }
                    
                    Spacer()
                    
                    // Container para o texto com tamanho fixo
                    ZStack(alignment: .leading) {
                        Color.clear
                            .frame(height: 65)
                        
                        // Texto do botão - aumentado
                        Text(labelText)
                            .font(.title3)
                            .fontWeight(.bold)
                            .lineLimit(2)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity)
                
                // Reflexo sutil no topo
                RoundedRectangle(cornerRadius: 15)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.3), Color.white.opacity(0)],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .mask(
                        RoundedRectangle(cornerRadius: 15)
                            .scale(0.95)
                    )
                    .opacity(isPressed ? 0.2 : 0.4)
            }
            .shadow(color: Color.black.opacity(0.2), radius: isPressed ? 3 : 7, x: 0, y: isPressed ? 2 : 4)
            .scaleEffect(isPressed ? 0.96 : 1)
            .rotation3DEffect(
                .degrees(isPressed ? 2 : 0),
                axis: (x: 1, y: 0, z: 0)
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(Text(labelText.replacingOccurrences(of: "\n", with: " ")))
    }
}

// MARK: - Preview
struct BotoesFinaisView_Previews: PreviewProvider {
    static var previews: some View {
        BotoesFinaisView(
            isUnidadesSaudeExpanded: .constant(false),
            isPontosTuristicosExpanded: .constant(false)
        )
        .background(Color.black)
    }
}

// MARK: - Chaves de Localização para adicionar ao Localizable.strings

/*
// Português (pt)
"social_networks" = "Redes Sociais";

// English (en)
"social_networks" = "Social Networks";

// Español (es)
"social_networks" = "Redes Sociales";

// Français (fr)
"social_networks" = "Réseaux Sociaux";

// 中文简体 (zh-Hans)
"social_networks" = "社交网络";
*/
