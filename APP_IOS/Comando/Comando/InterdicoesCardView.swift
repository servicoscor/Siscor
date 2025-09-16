import SwiftUI

struct InterdicoesCardView: View {
    // Ação a ser executada quando o botão for tocado
    var action: () -> Void
    
    @State private var isPressed = false
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            
            playHapticFeedback(.medium)
            
            // Atrasa a ação e reseta o estado
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                action()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
            }
        }) {
            ZStack {
                // Camada de fundo com o gradiente
                RoundedRectangle(cornerRadius: 15)
                    .fill(cardGradient)
                
                // Borda
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                
                // Conteúdo do botão
                VStack(alignment: .leading) {
                    // Container para o ícone com tamanho fixo
                    ZStack(alignment: .leading) {
                        Color.clear
                            .frame(height: 50)
                        
                        // Ícone da barreira
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 40, weight: .semibold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                    }
                    
                    Spacer()
                    
                    // Container para o texto com tamanho fixo
                    ZStack(alignment: .leading) {
                        Color.clear
                            .frame(height: 65)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(localizationManager.string(for: "interdictions"))
                                .font(.title3)
                                .fontWeight(.bold)
                                .lineLimit(1)
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                            
                            Text(localizationManager.string(for: "scheduled"))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white.opacity(0.9))
                                .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                        }
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
        .accessibilityLabel(Text(localizationManager.string(for: "scheduled_interdictions")))
    }
    
    // Função para feedback tátil
    func playHapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}

// MARK: - Estilos

private let cardGradient = LinearGradient(
    gradient: Gradient(colors: [
        Color(red: 0.1, green: 0.5, blue: 0.9),
        Color(red: 0.3, green: 0.6, blue: 0.9)
    ]),
    startPoint: .top,
    endPoint: .bottom
)

// Preview
struct InterdicoesCardView_Previews: PreviewProvider {
    static var previews: some View {
        InterdicoesCardView(action: {})
            .padding()
            .background(Color(red: 0.1, green: 0.1, blue: 0.2))
            .previewLayout(.sizeThatFits)
    }
}

// MARK: - Chaves de Localização para adicionar ao Localizable.strings

/*
// Português (pt)

*/
