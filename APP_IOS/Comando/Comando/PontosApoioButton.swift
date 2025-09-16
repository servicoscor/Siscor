import SwiftUI

struct PontosApoioButton: View {
    var action: () -> Void
    
    @State private var isPressed = false
    @StateObject private var localizationManager = LocalizationManager.shared
    
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
                        Image(systemName: "house.fill")
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                    }
                    
                    Spacer()
                    
                    // Container para o texto com tamanho fixo
                    ZStack(alignment: .leading) {
                        Color.clear
                            .frame(height: 55)
                        
                        // Texto do botão - aumentado
                        Text(localizationManager.string(for: "support_points"))
                            .font(.title3)
                            .fontWeight(.bold)
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
        .accessibilityLabel(Text(localizationManager.string(for: "support_points")))
    }
}

// Usando o mesmo gradiente do SirenesStatusButton
private let cardGradient = LinearGradient(gradient: Gradient(colors: [
    Color(red: 0.1, green: 0.5, blue: 0.9),
    Color(red: 0.3, green: 0.6, blue: 0.9)
]), startPoint: .top, endPoint: .bottom)

// MARK: - Chaves de Localização para adicionar ao Localizable.strings

/*
// Português (pt)

*/
