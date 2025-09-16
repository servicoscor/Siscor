import SwiftUI

//====================================================================//
// MARK: - Modelo de Dados e Ferramentas de Medição
//====================================================================//

// PreferenceKey para comunicar a altura máxima do filho para o pai.
private struct MaxHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

//====================================================================//
// MARK: - View Principal do Card de Informes de Tempo
//====================================================================//
struct InformesTempoView: View {
    let informes: [InformeTempo]
    let isLoading: Bool
    @State private var currentIndex: Int = 0
    @StateObject private var localizationManager = LocalizationManager.shared
    
    // Estado para armazenar a altura máxima calculada.
    @State private var carouselHeight: CGFloat? = nil
    
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Cabeçalho
            HStack(spacing: 12) {
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 24)).foregroundColor(.white)
                Text(localizationManager.string(for: "weather_reports"))
                    .font(.system(size: 24, weight: .bold)).foregroundColor(.white)
                Spacer()
                if !informes.isEmpty && !isLoading {
                    Text("\(currentIndex + 1)/\(informes.count)")
                        .foregroundColor(.white.opacity(0.8)).font(.system(size: 14, weight: .medium))
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color.black.opacity(0.2)).cornerRadius(12)
                }
            }
            .padding([.top, .horizontal])
            
            // Lógica de Loading / Vazio / Conteúdo
            if isLoading {
                LoadingView(message: localizationManager.string(for: "loading_forecasts"))
            } else if informes.isEmpty {
                EmptyStateView(
                    icon: "sun.haze",
                    message: localizationManager.string(for: "no_weather_info")
                )
            } else {
                // Carrossel Visível
                TempoHorizontalCarouselView(informes: informes, currentIndex: $currentIndex)
                    // Usa a altura calculada. Usamos um valor mínimo como fallback.
                    .frame(height: carouselHeight ?? 150)
                
                // Botões de Navegação
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
        .cornerRadius(15)
        .overlay(cardBorder)
        .shadow(color: Color.black.opacity(0.8), radius: 4, x: 0, y: 1)
        .padding(.horizontal, 16)
        // 1. MEDIÇÃO INVISÍVEL NO BACKGROUND
        .background(
            VStack {
                ForEach(informes) { informe in
                    TempoItemView(
                        textoCompleto: informe.texto ?? "",
                        localizationManager: localizationManager
                    )
                    .readHeight2()
                }
            }
            .opacity(0)
        )
        // 2. RECEPTOR DA ALTURA MÁXIMA
        .onPreferenceChange(MaxHeightPreferenceKey.self) { maxHeight in
            DispatchQueue.main.async {
                self.carouselHeight = maxHeight+70
            }
        }
    }
}

// MARK: - Carrossel Horizontal (Manual com Gesto)
private struct TempoHorizontalCarouselView: View {
    let informes: [InformeTempo]
    @Binding var currentIndex: Int
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        ZStack {
            // Exibe apenas o item atual
            if !informes.isEmpty {
                TempoItemView(
                    textoCompleto: informes[currentIndex].texto ?? localizationManager.string(for: "report_unavailable"),
                    localizationManager: localizationManager
                )
                .id(currentIndex) // Essencial para a animação de transição
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width < -50 { // Swipe para a esquerda
                        if currentIndex < informes.count - 1 {
                            withAnimation(.easeInOut) { currentIndex += 1 }
                        }
                    } else if value.translation.width > 50 { // Swipe para a direita
                        if currentIndex > 0 {
                            withAnimation(.easeInOut) { currentIndex -= 1 }
                        }
                    }
                }
        )
    }
}

private struct TempoItemView: View {
    let textoCompleto: String
    let localizationManager: LocalizationManager
    
    // Esta propriedade continua útil para tratar "jumpline" e linhas em branco.
    private var linhasProcessadas: [String] {
        let textoComQuebrasDeLinha = textoCompleto.replacingOccurrences(of: "jumpline", with: "\n").replacingOccurrences(of: "Jumpline", with: "\n").replacingOccurrences(of: "JUMPLINE", with: "\n")
        // O .filter no final remove linhas que só contêm espaços ou quebras de linha.
        return textoComQuebrasDeLinha.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
    
    // Função para detectar e traduzir palavras-chave de atenção
    private func isAttentionLine(_ linha: String) -> Bool {
        let attentionKeywords = [
            "Atenção!", "ATENÇÃO!", "Atenção",
            "Attention!", "ATTENTION!",
            "¡Atención!", "¡ATENCIÓN!"
        ]
        return attentionKeywords.contains { linha.hasPrefix($0) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Um ForEach que simplesmente exibe cada linha de texto processada.
            ForEach(linhasProcessadas, id: \.self) { linha in
                
                // Destaca linhas importantes
                if isAttentionLine(linha) {
                    Text(linha)
                        .font(.system(size: 16, weight: .bold))
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.yellow.opacity(0.4))
                        .cornerRadius(6)
                } else {
                    Text(linha)
                        .font(.system(size: 16, weight: .medium))
                }
            }
        }
        .foregroundColor(.white)
        .padding()
        .frame(maxWidth: .infinity, alignment: .topLeading) // Alinha o conteúdo ao topo
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

// MARK: - Extensão de View para ler a altura
extension View {
    func readHeight2() -> some View {
        self.background(
            GeometryReader { geometry in
                Color.clear.preference(
                    key: MaxHeightPreferenceKey.self,
                    value: geometry.size.height+50
                )
            }
        )
    }
}

//====================================================================//
// MARK: - Views Auxiliares
//====================================================================//

private let cardGradient = LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.blue.opacity(0.9)]), startPoint: .top, endPoint: .bottom)

private var cardBorder: some View {
    RoundedRectangle(cornerRadius: 15).stroke(Color.white.opacity(0.2), lineWidth: 1)
}

// MARK: - Chaves de Localização para adicionar ao Localizable.strings

/*
// Português (pt)

*/
