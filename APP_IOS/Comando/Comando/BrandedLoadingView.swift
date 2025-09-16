import SwiftUI

struct BrandedLoadingView: View {
    // Mensagem opcional para exibir abaixo do loading
    let message: String?
    
    // Estado para controlar a animação
    @State private var isAnimating: Bool = false
    
    // Inicializador com mensagem opcional
    init(message: String? = nil) {
        self.message = message
    }

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                // Círculo externo que pulsa
                Circle()
                    .stroke(lineWidth: 2)
                    .foregroundColor(.white.opacity(0.3))
                    .frame(width: 150, height: 150)
                    // A animação muda a escala e a opacidade
                    .scaleEffect(isAnimating ? 1.5 : 1.0)
                    .opacity(isAnimating ? 0 : 1)
                
                // Círculo interno que pulsa (com um delay diferente)
                Circle()
                    .stroke(lineWidth: 2)
                    .foregroundColor(.white.opacity(0.5))
                    .frame(width: 150, height: 150)
                    .scaleEffect(isAnimating ? 1.2 : 0.9)
                    .opacity(isAnimating ? 0 : 1)
                
                // Seu logo no centro
                Image("loading") // << Use o nome que você deu para a imagem no Assets
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 18)) // Deixa as bordas levemente arredondadas
                    .shadow(radius: 5)
            }
            
            // Mensagem opcional abaixo do loading
            if let message = message {
                Text(message)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
        }
        .onAppear {
            // Inicia a animação quando a view aparece
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Preview
struct BrandedLoadingView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black
            
            VStack(spacing: 50) {
                // Sem mensagem
                BrandedLoadingView()
                
                // Com mensagem
                BrandedLoadingView(message: "Carregando dados...")
            }
        }
        .ignoresSafeArea()
    }
}
