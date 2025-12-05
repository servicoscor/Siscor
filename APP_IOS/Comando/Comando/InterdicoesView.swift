import SwiftUI

// MARK: - View de Interdições Simplificada
struct InterdicoesView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = InterdicoesViewModel()
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Header com estilo integrado
            VStack(spacing: 12) {
                HStack {
                    Text(localizationManager.string(for: "scheduled_interdictions"))
                        .font(.title3.bold())
                        .foregroundColor(.primary)
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.body.weight(.bold))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
                
                // Botão de compartilhar integrado ao header
                if !viewModel.interdicoes.isEmpty {
                    HStack {
                        Text(localizationManager.string(for: "check_interdicted_roads"))
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button(action: shareContent) {
                            Label(localizationManager.string(for: "share"), systemImage: "square.and.arrow.up")
                                .font(.footnote.weight(.medium))
                        }
                        .tint(.primary)
                    }
                }
            }
            .padding()
            .background(.thinMaterial)
            
            // Conteúdo principal
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.05, green: 0.1, blue: 0.2),
                        Color(red: 0.1, green: 0.2, blue: 0.3)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Conteúdo
                if viewModel.isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.orange)
                        Text(localizationManager.string(for: "loading_interdictions"))
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding()
                } else if viewModel.interdicoes.isEmpty {
                    EmptyStateView(
                        icon: "checkmark.circle",
                        message: localizationManager.string(for: "no_interdictions")
                    )
                } else {
                    InterdicoesListView(interdicoes: viewModel.interdicoes)
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .task {
            await viewModel.loadInterdicoes()
        }
    }
    
    private func shareContent() {
        let title = localizationManager.string(for: "scheduled_interdictions")
        let textoCompleto = viewModel.interdicoes
            .compactMap { $0.nor ?? $0.via }
            .joined(separator: "\n\n")
        let av = UIActivityViewController(
            activityItems: ["\(title):\n\n\(textoCompleto)"],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(av, animated: true)
        }
    }
}

// MARK: - Lista de Interdições
struct InterdicoesListView: View {
    let interdicoes: [Interdicao]
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header informativo
               
                
                // Lista de interdições
                ForEach(Array(interdicoes.enumerated()), id: \.element.id) { index, interdicao in
                    InterdicaoCard(
                        interdicao: interdicao,
                        index: index + 1
                    )
                }
            }
            .padding()
        }
    }
}

// MARK: - Card de Interdição Individual
struct InterdicaoCard: View {
    let interdicao: Interdicao
    let index: Int
    @State private var isExpanded = false
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header do card
            HStack {
                // Número do item
                ZStack {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 30, height: 30)
                    
                    Text("\(index)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
                
                // Título com via ou dia da semana
                VStack(alignment: .leading, spacing: 2) {
                    if let via = interdicao.via {
                        Text(extractTitle(from: via))
                            .font(.headline)
                            .foregroundColor(.white)
                            .lineLimit(1)
                    } else {
                        Text(localizationManager.string(for: "interdiction_number").localized(with: index))
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    
                    if let poli = interdicao.poli {
                        Text(translateDayOfWeek(poli))
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                Spacer()
                
                // Status badge
                if let status = interdicao.status {
                    Text(translateStatus(status))
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(8)
                }
                
                // Botão expandir/recolher
                if let texto = interdicao.nor ?? interdicao.via, texto.count > 150 {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .accessibilityLabel(localizationManager.string(for: isExpanded ? "collapse" : "expand"))
                }
            }
            
            // Horário, se disponível
            if let reg = interdicao.reg {
                HStack {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text(reg)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            // Descrição completa
            if let texto = interdicao.nor ?? interdicao.via {
                Text(texto)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(isExpanded ? nil : 3)
                    .fixedSize(horizontal: false, vertical: true)
                    .animation(.easeInOut(duration: 0.3), value: isExpanded)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private func extractTitle(from text: String) -> String {
        // Extrai o nome da via principal
        let keywords = ["Túnel", "Ponte", "Elevado", "Viaduto", "Av.", "Avenida", "Rua", "Estrada"]
        
        for keyword in keywords {
            if let range = text.range(of: keyword) {
                let startIndex = text.index(range.lowerBound, offsetBy: 0)
                let substring = String(text[startIndex...])
                
                // Procura por vírgula ou "sentido" para delimitar o título
                if let commaIndex = substring.firstIndex(of: ",") {
                    return String(substring[..<commaIndex])
                } else if let sentidoRange = substring.range(of: "sentido") {
                    return String(substring[..<sentidoRange.lowerBound]).trimmingCharacters(in: .whitespaces)
                } else if substring.count < 50 {
                    return substring
                } else {
                    return String(substring.prefix(50)) + "..."
                }
            }
        }
        
        // Se não encontrar palavras-chave, retorna os primeiros caracteres
        return String(text.prefix(30)) + "..."
    }
    
    private func translateDayOfWeek(_ day: String) -> String {
        let daysMap: [String: [String: String]] = [
            "en": [
                "Segunda": "Monday",
                "Terça": "Tuesday",
                "Quarta": "Wednesday",
                "Quinta": "Thursday",
                "Sexta": "Friday",
                "Sábado": "Saturday",
                "Domingo": "Sunday"
            ],
            "es": [
                "Segunda": "Lunes",
                "Terça": "Martes",
                "Quarta": "Miércoles",
                "Quinta": "Jueves",
                "Sexta": "Viernes",
                "Sábado": "Sábado",
                "Domingo": "Domingo"
            ]
        ]
        
        if localizationManager.currentLanguage == "pt" {
            return day
        }
        
        return daysMap[localizationManager.currentLanguage]?[day] ?? day
    }
    
    private func translateStatus(_ status: String) -> String {
        if status.lowercased().contains("programada") {
            return localizationManager.string(for: "scheduled")
        }
        return status
    }
}

// MARK: - ViewModel
@MainActor
class InterdicoesViewModel: ObservableObject {
    @Published var interdicoes: [Interdicao] = []
    @Published var isLoading = false
    
    func loadInterdicoes() async {
        isLoading = true
        
        do {
            // Tenta buscar dados da API usando a versão 2 que faz parsing mais inteligente
            let fetchedInterdicoes = try await ColetaDados_Interdicoes_V2.getdata()
            
            // Filtra interdições válidas (que tenham pelo menos via ou nor preenchidos)
            self.interdicoes = fetchedInterdicoes.filter {
                ($0.via != nil && !$0.via!.isEmpty) ||
                ($0.nor != nil && !$0.nor!.isEmpty)
            }
            
        } catch {
            print("Erro ao carregar interdições: \(error)")
            // Em caso de erro, mantém lista vazia
            self.interdicoes = []
        }
        
        isLoading = false
    }
}

// MARK: - Preview
struct InterdicoesView_Previews: PreviewProvider {
    static var previews: some View {
        InterdicoesView()
    }
}
