import SwiftUI

struct SirenesStatusButton: View {
    var action: () -> Void
    let sirenes: [Sirene] // Recebe as sirenes como parâmetro
    
    @State private var isPressed = false
    @StateObject private var localizationManager = LocalizationManager.shared
    
    // Propriedade computada para o status das sirenes
    private var sirenesStatus: (title: String, subtitle: String, isActive: Bool, count: Int) {
        // Conta quantas sirenes estão ativas
        let activeSirens = sirenes.filter { sirene in
            // Verifica se o status indica que a sirene está ativa
            if let status = sirene.status?.lowercased() {
                return status.contains("acionada") || status.contains("ativa") || status.contains("ligada")
            }
            return false
        }
        
        let count = activeSirens.count
        
        if count > 0 {
            return (
                localizationManager.string(for: "sirens_active"),
                String(format: localizationManager.string(for: "sirens_active_count"), count),
                true,
                count
            )
        } else {
            return (
                localizationManager.string(for: "no_sirens"),
                localizationManager.string(for: "no_sirens_active"),
                false,
                0
            )
        }
    }
    
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
                // Camada de fundo com o gradiente - muda cor se houver sirenes ativas
                RoundedRectangle(cornerRadius: 15)
                    .fill(sirenesStatus.isActive ? activeGradient : cardGradient)
                
                // Borda definida localmente
                RoundedRectangle(cornerRadius: 15)
                    .stroke(sirenesStatus.isActive ? Color.yellow.opacity(0.5) : Color.white.opacity(0.2), lineWidth: 1)
                
                // Conteúdo do botão com layout padronizado
                VStack(alignment: .leading) {
                    // Container para o ícone com tamanho fixo
                    ZStack(alignment: .leading) {
                        Color.clear
                            .frame(height: 50)
                        
                        // Ícone do botão - muda cor e pulsa se ativo
                        Image(systemName: "light.beacon.max.fill")
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundColor(sirenesStatus.isActive ? .yellow : .white)
                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                            .scaleEffect(sirenesStatus.isActive ? 1.1 : 1.0)
                            .animation(sirenesStatus.isActive ? Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true) : .default, value: sirenesStatus.isActive)
                    }
                    
                    Spacer()
                    
                    // Container para o texto com tamanho fixo
                    ZStack(alignment: .leading) {
                        Color.clear
                            .frame(height: 55)
                        
                        // Texto do botão - localizado
                        VStack(alignment: .leading, spacing: 4) {
                            Text(sirenesStatus.title)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                            
                            Text(sirenesStatus.subtitle)
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)
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
        .accessibilityLabel(Text(formatAccessibilityLabel()))
    }
    
    // Função para formatar o label de acessibilidade
    private func formatAccessibilityLabel() -> String {
        if sirenesStatus.isActive {
            return String(format: localizationManager.string(for: "sirens_status_active_accessibility"), sirenesStatus.count)
        } else {
            return localizationManager.string(for: "sirens_status_inactive_accessibility")
        }
    }
}

// Gradientes
private let cardGradient = LinearGradient(gradient: Gradient(colors: [
    Color(red: 0.1, green: 0.5, blue: 0.9),
    Color(red: 0.3, green: 0.6, blue: 0.9)
]), startPoint: .top, endPoint: .bottom)

private let activeGradient = LinearGradient(gradient: Gradient(colors: [
    Color(red: 0.9, green: 0.6, blue: 0.1),
    Color(red: 0.9, green: 0.3, blue: 0.1)
]), startPoint: .top, endPoint: .bottom)


// MARK: - Chaves de Localização para adicionar ao Localizable.strings

/*
// Português (pt)

*/
