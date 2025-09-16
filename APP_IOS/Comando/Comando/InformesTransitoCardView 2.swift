import SwiftUI

//====================================================================//
// MARK: - Modelo de Dados e Ferramenta de Medição (PreferenceKey)
//====================================================================//

// 1. A FERRAMENTA AVANÇADA: PREFERENCE KEY
// Esta struct define uma forma de comunicar dados (neste caso, a altura)
// de uma view filha para uma view pai.
private struct MaxHeightPreferenceKey: PreferenceKey {
    // O valor padrão é 0
    static var defaultValue: CGFloat = 0
    // A função 'reduce' garante que sempre teremos o valor MÁXIMO
    // entre a altura atual e a próxima altura medida.
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

//====================================================================//
// MARK: - View Principal (Com Lógica de Medição)
//====================================================================//
struct InformesTransitoCardView: View {
    let informes: [InformeTrânsito]
    let isLoading: Bool
    @State private var currentIndex: Int = 0
    @State private var carouselHeight: CGFloat? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Cabeçalho (inalterado)
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.yellow)
                Text("Informes de trânsito").font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                Spacer()
                if !informes.isEmpty && !isLoading {
                    Text("\(currentIndex + 1)/\(informes.count)").foregroundColor(.white.opacity(0.8)).font(.system(size: 14, weight: .medium))
                        .padding(.horizontal, 8).padding(.vertical, 4).background(Color.black.opacity(0.2)).cornerRadius(12)
                }
            }.padding([.top, .horizontal])
            
            if isLoading {
                LoadingView(message: "Carregando informes...")
            } else if informes.isEmpty {
                EmptyStateView(icon: "checkmark.seal", message: "Trânsito sem ocorrências no momento")
            } else {
                // Carrossel Visível
                TransitoHorizontalCarouselView(informes: informes, currentIndex: $currentIndex)
                    // Usa a altura calculada. Usamos um valor mínimo como fallback.
                    .frame(height: carouselHeight ?? 500)
                
                // Botões de navegação (inalterados)
                if informes.count > 1 {
                    HStack {
                        Spacer()
                        Button(action: {
                            withAnimation(.easeInOut) { currentIndex = (currentIndex > 0) ? currentIndex - 1 : informes.count - 1 }
                        }) {
                            Image(systemName: "chevron.left").foregroundColor(.white).padding(8).background(Color.black.opacity(0.2)).clipShape(Circle())
                        }
                        Spacer()
                        if informes.count <= 12 {
                            HStack(spacing: 8) {
                                ForEach(informes.indices, id: \.self) { index in
                                    Circle().fill(index == currentIndex ? Color.white : Color.white.opacity(0.3)).frame(width: 8, height: 8)
                                }
                            }
                        }
                        Spacer()
                        Button(action: {
                            withAnimation(.easeInOut) { currentIndex = (currentIndex < informes.count - 1) ? currentIndex + 1 : 0 }
                        }) {
                            Image(systemName: "chevron.right").foregroundColor(.white).padding(8).background(Color.black.opacity(0.2)).clipShape(Circle())
                        }
                        Spacer()
                    }.padding(.bottom, 8)
                }
            }
        }
        .padding(.bottom)
        .background(cardGradient)
        .cornerRadius(12)
        .overlay(cardBorder)
        .shadow(color: Color.black.opacity(0.8), radius: 4, x: 0, y: 1)
        .padding(.horizontal, 16)
        // 1. A MEDIÇÃO AGORA ACONTECE NO BACKGROUND
        // Um background não afeta o tamanho da view principal.
        .background(
            VStack {
                // A camada de medição invisível
                ForEach(informes) { informe in
                    InformeItemView(textoCompleto: informe.texto ?? "")
                        .readHeight()
                }
            }
            .opacity(0) // Continua invisível
        )
        // 2. O RECEPTOR FICA AQUI
        .onPreferenceChange(MaxHeightPreferenceKey.self) { maxHeight in
            // 3. ATUALIZAÇÃO SEGURA DA ALTURA
            // Usamos DispatchQueue para evitar um aviso de "modifying state during view update".
            DispatchQueue.main.async {
                self.carouselHeight = maxHeight
            }
        }
    }
}


// MARK: - Carrossel Horizontal (Sem Gesto de Swipe)
private struct TransitoHorizontalCarouselView: View {
    let informes: [InformeTrânsito]
    @Binding var currentIndex: Int

    var body: some View {
        ZStack {
            if !informes.isEmpty {
                InformeItemView(textoCompleto: informes[currentIndex].texto ?? "Informe indisponível")
                    .id(currentIndex)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        // GESTO DE DESLIZE ADICIONADO DE VOLTA
        .gesture(
            DragGesture()
                .onEnded { value in
                    // Se o usuário arrastou mais de 50 pontos para a esquerda
                    if value.translation.width < -50 {
                        // Evita passar do limite
                        if currentIndex < informes.count - 1 {
                            withAnimation(.easeInOut) {
                                currentIndex += 1
                            }
                        }
                    // Se o usuário arrastou mais de 50 pontos para a direita
                    } else if value.translation.width > 50 {
                        // Evita passar do limite
                        if currentIndex > 0 {
                            withAnimation(.easeInOut) {
                                currentIndex -= 1
                            }
                        }
                    }
                }
        )
    }
}

// MARK: - View do Item (Sem ScrollView)
private struct InformeItemView: View {
    let textoCompleto: String
    
    private var linhasProcessadas: [String] {
        let textoComQuebrasDeLinha = textoCompleto.replacingOccurrences(of: "jumpline", with: "\n")
        return textoComQuebrasDeLinha.components(separatedBy: "\n")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(linhasProcessadas, id: \.self) { linha in
                if linha.hasPrefix("Atenção!") {
                    Text(linha).font(.system(size: 16, weight: .bold)).padding(8).frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.yellow.opacity(0.4)).cornerRadius(6)
                } else if !linha.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(linha).font(.system(size: 16, weight: .medium))
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}


// MARK: - Extensão de View para ler a altura
extension View {
    func readHeight() -> some View {
        self.background(
            GeometryReader { geometry in
                Color.clear.preference(
                    key: MaxHeightPreferenceKey.self,
                    value: geometry.size.height
                )
            }
        )
    }
}


//====================================================================//
// MARK: - Views Auxiliares (Inalteradas)
//====================================================================//


struct EmptyStateView: View {
    let icon: String
    let message: String
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 36)).foregroundColor(.white.opacity(0.8))
            Text(message).font(.system(size: 16)).foregroundColor(.white.opacity(0.8)).multilineTextAlignment(.center)
        }.frame(maxWidth: .infinity, minHeight: 120).padding()
    }
}

private let cardGradient = LinearGradient(gradient: Gradient(colors: [
    Color(red: 0.1, green: 0.5, blue: 0.9),
    Color(red: 0.3, green: 0.6, blue: 0.9)
]), startPoint: .top, endPoint: .bottom)

private var cardBorder: some View {
    RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.2), lineWidth: 1)
}
