import SwiftUI
import MapKit
import AVKit

class AlertasViewModel: ObservableObject {
    @Published var alertas: [Alerta] = []
    @Published var isLoading: Bool = false
    
    @MainActor
    func fetchAlertas() async {
        isLoading = true
        
        do {
            let fetchedAlertas = try await ColetaDados_Alertas.getdata()
            self.alertas = fetchedAlertas
        } catch {
            print("Erro ao buscar alertas: \(error)")
        }
        
        isLoading = false
    }
}

struct StatusAlertaView: View {
    // MARK: - Propriedades de Estado
    @State private var isLoading: Bool = false
    @State private var isRadarExpanded: Bool = false
    @State private var isAlarmeExpanded: Bool = false
    @State private var isPontosApoioExpanded: Bool = false
    @State private var isUnidadesSaudeExpanded: Bool = false
    @State private var isPontosResfriamentoExpanded: Bool = false
    @State private var scrollOffset: CGFloat = 0
    @State private var debouncedScrollOffset: CGFloat = 0
    @State private var scrollDebounceTimer: Timer?
    @State private var isScrolling: Bool = false
    @State private var isPontosTuristicosExpanded: Bool = false
    @State private var isInterdicoesExpanded: Bool = false
    @State private var isLoadingEventos: Bool = false

    @StateObject private var alertasViewModel = AlertasViewModel()
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @StateObject private var locationManager = LocationManager()
    
    // NOVO: Acessa o ViewModel do ambiente
    @EnvironmentObject var viewModel: CORViewModel

    let eventos: [Evento]
    let alertas: [Alerta]
    let infoTempo: [InformeTempo]
    let infoTransito: [InformeTrânsito]
    let cameras: [Camera]
    let sirenes: [Sirene]
    let nomeImagemFundo: String
    
    // Dados para as telas modais
    let pontosDeApoio: [PontoDeApoio]
    let unidadesDeSaude: [PontoDeApoio]
    let pontosDeResfriamento: [PontoDeApoio]
    let nivelCalor: NivelCalor
    let recomendacoes: [Recomendacao]
    let estagioOperacional: Int
    
    let headerColor = Color(red: 0.1, green: 0.5, blue: 0.9)
    
    // MARK: - Corpo da View
    var body: some View {
        ZStack {
            // Fundo dinâmico com parallax limitado
            Image(nomeImagemFundo)
                .resizable()
                .scaledToFill()
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height + 200)
                .offset(y: min(max(debouncedScrollOffset * 0.3, -150), 150))
                .animation(isScrolling ? nil : .easeOut(duration: 0.3), value: debouncedScrollOffset)
                .id(nomeImagemFundo)
                .ignoresSafeArea()
                .clipped()
            
            // ScrollViewReader envolve TUDO que precisa acessar scrollProxy
            ScrollViewReader { scrollProxy in
                ZStack {
                    // ScrollView otimizado
                    OptimizedScrollView(offset: $scrollOffset, isScrolling: $isScrolling) {
                        VStack(spacing: 0) {
                            Color.clear.frame(height: 100)
                            
                            // Conteúdo principal com espaçamento otimizado
                            VStack(spacing: 20) {
                                // Views sempre visíveis (não lazy)
                                EstagioView(currentStage: estagioOperacional)
                                    .drawingGroup()
                                
                                ClimaCardView(
                                    pontosDeApoio: self.pontosDeApoio,
                                    unidadesDeSaude: self.unidadesDeSaude,
                                    pontosDeResfriamento: self.pontosDeResfriamento,
                                    nivelCalor: self.nivelCalor,
                                    recomendacoes: self.recomendacoes
                                ).id("climaSection")
                                                                
                                // AlertasCardView com ID para scroll
                                AlertasCardView(
                                    alertas: alertasViewModel.alertas,
                                    isLoading: alertasViewModel.isLoading
                                )
                                .padding(.top, 100)
                                .id("alertasSection")
                                .task {
                                    await alertasViewModel.fetchAlertas()
                                }
                                
                                // LazyVStack apenas para conteúdo pesado
                                LazyVStack(spacing: 20) {
                                    
                                                                    
                                    InformesTempoView(informes: self.infoTempo, isLoading: self.isLoading)
                                    
                                    RadarCardView(onExpand: {
                                        self.isRadarExpanded = true
                                    })
                                    
                                    Color.clear.frame(height: 40)
                                    
                                    HStack(spacing: 16) {
                                        TransitoCardView(action: {
                                            print("Botão de Trânsito foi tocado!")
                                        })
                                        InterdicoesCardView(action: {
                                            self.isInterdicoesExpanded = true
                                        })
                                    }
                                    .padding(.horizontal, 16)
                                    
                                    InformesTransitoCardView(
                                        informes: self.infoTransito,
                                        isLoading: self.isLoading
                                    )
                                    
                                    CamerasMapView(cameras: self.cameras)
                                    
                                    Color.clear.frame(height: 40)
                                    
                                    HStack(spacing: 16) {
                                        SirenesStatusButton(
                                            action: {
                                                self.isAlarmeExpanded = true
                                            },
                                            sirenes: self.sirenes
                                        )
                                        
                                        PontosApoioButton(action: {
                                            self.isPontosApoioExpanded = true
                                        })
                                    }
                                    .padding(.horizontal, 16)
                                    
                                    SistemaAlarmeMapView(sirenes: self.sirenes, onExpand: {
                                        self.isAlarmeExpanded = true
                                    })
                                    
                                    Color.clear.frame(height: 40)
                                    
                                    BotoesFinaisView(
                                        isUnidadesSaudeExpanded: $isUnidadesSaudeExpanded,
                                        isPontosTuristicosExpanded: $isPontosTuristicosExpanded
                                    )
                                    
                                    Color.clear.frame(height: 240)
                                }
                            }
                            .padding(.top, 120)
                        }
                    }
                    .onChange(of: scrollOffset) { newValue in
                        // Debounce do scroll offset
                        scrollDebounceTimer?.invalidate()
                        scrollDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: false) { _ in
                            withAnimation(.easeOut(duration: 0.2)) {
                                debouncedScrollOffset = newValue
                            }
                        }
                    }
                    
                    // Header sobreposto
                    VStack {
                        HeaderView(
                            currentStage: estagioOperacional,
                            alertCount: alertas.count,
                            eventCount: eventos.count,
                            temperature: "28°",
                            scrollToAlerts: {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    scrollProxy.scrollTo("alertasSection", anchor: UnitPoint(x: 0.5, y: 0.15))
                                }
                            },
                            scrollToEvents: {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    scrollProxy.scrollTo("eventosSection", anchor: UnitPoint(x: 0.5, y: 0.15))
                                }
                            }
                        )
                        .ignoresSafeArea(edges: .top)
                        
                        Spacer()
                    }
                }
            }
            
            // NOVO: Loading Overlay para reloads
            if viewModel.isLoading && viewModel.isDataLoaded {
                LoadingOverlay()
                    .transition(.opacity)
            }
        }
        // MARK: - Modais (Telas Cheias)
        .fullScreenCover(isPresented: $isRadarExpanded) {
            FullScreenRadarView()
        }
        .fullScreenCover(isPresented: $isAlarmeExpanded) {
            FullScreenAlarmeView(sirenes: self.sirenes)
        }
        .fullScreenCover(isPresented: $isPontosApoioExpanded) {
            PontosApoioView(pontos: self.pontosDeApoio)
        }
        .fullScreenCover(isPresented: $isUnidadesSaudeExpanded) {
            UnidadesSaudeView(unidades: self.unidadesDeSaude)
        }
        .fullScreenCover(isPresented: $isPontosTuristicosExpanded) {
            PontosTuristicosView()
        }
        .fullScreenCover(isPresented: $isInterdicoesExpanded) {
            InterdicoesView()
        }
        .fullScreenCover(isPresented: $isPontosResfriamentoExpanded) {
            PontosResfriamentoView(
                pontosUnidadesSaude: self.unidadesDeSaude,
                pontosResfriamento: self.pontosDeResfriamento,
                nivelCalor: self.nivelCalor,
                recomendacoes: self.recomendacoes
            )
        }
        .onDisappear {
            // Limpa timers ao sair da view
            scrollDebounceTimer?.invalidate()
        }
    }
}

// MARK: - Loading Overlay Component
struct LoadingOverlay: View {
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        ZStack {
            // Fundo semi-transparente
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Usar o mesmo BrandedLoadingView
                BrandedLoadingView()
                
                Text(localizationManager.string(for: "updating_data"))
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - ScrollView Otimizado
struct OptimizedScrollView<Content: View>: View {
    let content: Content
    @Binding var offset: CGFloat
    @Binding var isScrolling: Bool
    @State private var scrollTimer: Timer?
    
    init(offset: Binding<CGFloat>, isScrolling: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self._offset = offset
        self._isScrolling = isScrolling
        self.content = content()
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            content
                .background(
                    GeometryReader { proxy in
                        Color.clear
                            .preference(
                                key: ScrollOffsetPreferenceKey.self,
                                value: proxy.frame(in: .named("optimizedScroll")).minY
                            )
                    }
                )
        }
        .coordinateSpace(name: "optimizedScroll")
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
            // Apenas atualiza se a diferença for significativa
            if abs(offset - value) > 2 {
                isScrolling = true
                offset = value
                
                // Cancela timer anterior
                scrollTimer?.invalidate()
                
                // Marca como não scrolling após delay
                scrollTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in
                    isScrolling = false
                }
            }
        }
    }
}

// MARK: - ScrollOffsetPreferenceKey
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

class SpeechManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    @Published var isSpeaking: Bool = false
    override init() { super.init(); synthesizer.delegate = self }
    func speak(text: String) {
        guard !text.isEmpty else { return }
        if synthesizer.isSpeaking { synthesizer.stopSpeaking(at: .immediate) }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "pt-BR")
        synthesizer.speak(utterance)
    }
    func stop() { synthesizer.stopSpeaking(at: .immediate) }
    func speechSynthesizer(_ s: AVSpeechSynthesizer, didStart u: AVSpeechUtterance) { DispatchQueue.main.async { self.isSpeaking = true } }
    func speechSynthesizer(_ s: AVSpeechSynthesizer, didFinish u: AVSpeechUtterance) { DispatchQueue.main.async { self.isSpeaking = false } }
    func speechSynthesizer(_ s: AVSpeechSynthesizer, didCancel u: AVSpeechUtterance) { DispatchQueue.main.async { self.isSpeaking = false } }
}

struct ServiceButton: View {
    let title: String, icon: String, action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon).font(.title2)
                Text(title).font(.footnote).fontWeight(.semibold)
            }
            .foregroundColor(.white).frame(maxWidth: .infinity, minHeight: 100)
            .background(cardGradient.opacity(0.8)).cornerRadius(15).overlay(cardBorder)
        }
    }
}

//====================================================================//
// MARK: - Subviews Locais
//====================================================================//

struct EstagioView:  View {
    let currentStage: Int
    @State private var selectedDetail: Int? = nil
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Header minimalista
            VStack(spacing: 8) {
                Text(localizationManager.string(for: "city_in"))
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)
                    .tracking(2)
                
            }
            
            // Container principal simplificado
            estagioImage
                .resizable()
                .scaledToFit()
                .frame(height: 200)
                .padding(.vertical, 20)
            
            // Container dos estágios
            VStack(spacing: 20) {
                // Ícones dos estágios
                HStack(spacing: 0) {
                    ForEach(1...5, id: \.self) { stage in
                        PlayStationTrophy(
                            stage: stage,
                            currentStage: currentStage,
                            onTap: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    selectedDetail = selectedDetail == stage ? nil : stage
                                }
                            }
                        )
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 20)
                
                // Detalhes do estágio selecionado
                if let selected = selectedDetail {
                    TrophyDetailView(stage: selected)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.9).combined(with: .opacity),
                            removal: .scale(scale: 0.9).combined(with: .opacity)
                        ))
                }
            }
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 40)
    }
    
    private var estagioImage: Image {
        getImageForStage(currentStage)
    }
    
    private func getImageForStage(_ stage: Int) -> Image {
        let imageName = getImageName(for: stage)
        if let uiImage = UIImage(named: imageName) {
            return Image(uiImage: uiImage)
        }
        return Image(systemName: "shield.fill")
    }
    
    private func getImageName(for stage: Int) -> String {
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
    
    private func colorForStage(_ stage: Int) -> Color {
        switch stage {
        case 1...2: return .green
        case 3: return .yellow
        case 4: return .orange
        case 5: return .red
        default: return .gray
        }
    }
}

struct PlayStationTrophy: View {
    let stage: Int
    let currentStage: Int
    let onTap: () -> Void
    
    private var stageColor: Color {
        if stage > currentStage { return .gray }
        switch stage {
        case 1...2: return .green
        case 3: return .yellow
        case 4: return .orange
        case 5: return .red
        default: return .gray
        }
    }
    
    private let localizationManager = LocalizationManager.shared

    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                // Ícone minimalista
                ZStack {
                    // Círculo simples de fundo
                    Circle()
                        .fill(Color.white.opacity(0.05))
                        .frame(width: 60, height: 60)
                    
                    // Borda circular fina
                    Circle()
                        .stroke(
                            stage <= currentStage
                                ? stageColor
                                : Color.white.opacity(0.2),
                            lineWidth: stage == currentStage ? 2 : 1
                        )
                        .frame(width: 60, height: 60)
                    
                    // Imagem do estágio (simplificada)
                    getImageForStage(stage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 55, height: 55)
                        .opacity(stage <= currentStage ? 0.9 : 0.3)
                        .grayscale(stage <= currentStage ? 0.0 : 1.0)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(stage == currentStage ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: currentStage)
    }
    
    private func getImageForStage(_ stage: Int) -> Image {
        let imageName = getImageName(for: stage)
        if let uiImage = UIImage(named: imageName) {
            return Image(uiImage: uiImage)
        }
        return Image(systemName: "shield.fill")
    }
    
    private func getImageName(for stage: Int) -> String {
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

struct TrophyDetailView: View {
    let stage: Int
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    private var stageInfo: (title: String, when: String, impact: String) {
        let title = localizationManager.string(for: "stage_\(stage)_title")
        let when = localizationManager.string(for: "stage_\(stage)_when")
        let impact = localizationManager.string(for: "stage_\(stage)_impact")
        return (title, when, impact)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(stageInfo.title.uppercased())
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .tracking(1)
            
            Text("\(localizationManager.string(for: "stage_when"))\n\(stageInfo.when)\n\n\(localizationManager.string(for: "stage_impact"))\n\(stageInfo.impact)")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
    }
}

//====================================================================//
// MARK: - View do Card de Alertas
//====================================================================//

struct AlertasCardView: View {
    let alertas: [Alerta]
    let isLoading: Bool
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    @State private var alertaSelecionado: Alerta?
    @State private var isVisible: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Cabeçalho
            HStack {
                Image(systemName: "bell.badge.fill").foregroundColor(.white)
                Text(localizationManager.string(for: "alerts"))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.vertical, 12).padding(.horizontal)
            
            // Lógica de Loading / Vazio
            if isLoading {
                BrandedLoadingView().frame(height: 150)
            } else if alertas.isEmpty {
                EmptyStateView(
                    icon: "checkmark.circle",
                    message: localizationManager.string(for: "no_alerts")
                )
            } else {
                // Lista de Alertas
                VStack(spacing: 12) {
                    ForEach(Array(alertas.enumerated()), id: \.element.id) { index, alerta in
                        AlertaRow(alerta: alerta)
                            .onTapGesture {
                                alertaSelecionado = alerta
                            }
                            .opacity(isVisible ? 1 : 0)
                            .offset(x: isVisible ? 0 : -20)
                            .animation(.easeOut.delay(Double(index) * 0.1), value: isVisible)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 12)
            }
        }
        .background(cardGradient)
        .cornerRadius(12)
        .overlay(cardBorder)
        .shadow(color: Color.black.opacity(0.8), radius: 4, x: 0, y: 1)
        .padding(.horizontal, 16)
        .sheet(item: $alertaSelecionado) { alerta in
            AlertaDetalhesView(alerta: alerta)
        }
        .onAppear {
            isVisible = true
        }
        .id("alertasSection")
    }
}

struct AlertaRow: View {
    let alerta: Alerta
    @ObservedObject private var localizationManager = LocalizationManager.shared

    var body: some View {
        HStack(spacing: 15) {
            // Ícone contextual
            Image(systemName: iconFor(alerta: alerta))
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 40)
                .fontWeight(.bold)

            // Título e Data
            VStack(alignment: .leading, spacing: 2) {
                Text(alerta.nome ?? localizationManager.string(for: "alert_no_title"))
                    .font(.system(size: 16, weight: .bold))
                    .lineLimit(2)
                
                if let data = alerta.data {
                    Text(data)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            Spacer()
            Image(systemName: "chevron.right").foregroundColor(.white.opacity(0.5))
        }
        .foregroundColor(.white)
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(10)
    }
    
    private func iconFor(alerta: Alerta) -> String {
        let texto = (alerta.nome ?? "").lowercased()
        
        if texto.contains("acidente") {
            return "car.2.fill"
        }
        
        if texto.contains("pista") || texto.contains("avenida") || texto.contains("rua") {
            return "road.lanes"
        }
        
        if texto.contains("trânsito") || texto.contains("via") {
            return "arrow.triangle.swap"
        }
        
        if texto.contains("sirene") {
            return "siren.fill"
        }
        
        if texto.contains("ressaca") {
            return "water.waves"
        }
        
        if texto.contains("chuva") {
            return "cloud.rain.fill"
        }
        
        if texto.contains("vento") {
            return "wind"
        }
        
        return "exclamationmark.triangle.fill"
    }
}

struct AlertaDetalhesView: View {
    let alerta: Alerta
    @StateObject private var speechManager = SpeechManager()
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var player: AVPlayer?
    @State private var isAudioPlaying = false
    @State private var region = MKCoordinateRegion()
    @State private var polygon: MKPolygon?
    @State private var showShareSheet = false
    
    private var palavrasDeDestaque: [String] {
        // Retorna as palavras localizadas
        return [
            localizationManager.string(for: "highlight_attention"),
            localizationManager.string(for: "highlight_risk"),
            localizationManager.string(for: "highlight_closed"),
            localizationManager.string(for: "highlight_evacuate"),
            localizationManager.string(for: "highlight_danger"),
            localizationManager.string(for: "highlight_warning"),
            localizationManager.string(for: "highlight_avoid"),
            localizationManager.string(for: "highlight_forecast"),
            localizationManager.string(for: "highlight_traffic"),
            localizationManager.string(for: "highlight_strong"),
            localizationManager.string(for: "highlight_moderate"),
            localizationManager.string(for: "highlight_stage"),
            // Adicione outras palavras específicas do português aqui se necessário
            "fechado", "ocorrência", "avenida", "liberada", "interdições",
            "centro de operações", "vias", "liberadas", "moderadas", "fortes",
            "moderados", "acidentes", "reduza", "molhadas", "escorregadias",
            "fraca", "fracos"
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 4) {
                Capsule().fill(Color.gray.opacity(0.5)).frame(width: 40, height: 5)
                Text(alerta.nome ?? localizationManager.string(for: "details"))
                    .font(.headline).padding(.top, 8)
            }.padding()
            
            if let polygon {
                PolygonMapView(region: $region, polygon: polygon)
                    .frame(height: 180).cornerRadius(12).padding(.horizontal)
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    infoRow(
                        icon: "calendar.badge.clock",
                        title: localizationManager.string(for: "date"),
                        value: formatarData(alerta.data)
                    )
                    
                    if let mensagem = alerta.mensagem, !mensagem.isEmpty {
                        VStack(alignment: .leading) {
                            HStack {
                                Image(systemName: "text.bubble.fill").foregroundColor(.accentColor)
                                Text(localizationManager.string(for: "message"))
                                    .font(.caption.bold()).foregroundColor(.secondary)
                                Spacer()
                            }
                            HighlightedText(text: mensagem, keywords: palavrasDeDestaque).padding(.top, 4)
                        }
                    }
                    
                    if let audioURLString = alerta.audiourl, let url = URL(string: audioURLString) {
                        Divider().padding(.horizontal, -16)
                        audioPlayer(url: url)
                    }
                }.padding()
            }
            
            Spacer()
            
            VStack {
                Divider()
                Button(action: { showShareSheet = true }) {
                    HStack {
                        Spacer()
                        Image(systemName: "square.and.arrow.up")
                        Text(localizationManager.string(for: "share_alert"))
                        Spacer()
                    }
                    .fontWeight(.semibold).padding()
                    .background(Color.blue.opacity(0.2)).cornerRadius(12)
                }.padding([.horizontal, .bottom])
            }
        }
        .onAppear(perform: setupMap)
        .onDisappear(perform: speechManager.stop)
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: [gerarTextoCompartilhamento()])
        }
    }
    
    private func setupMap() {
        guard let geoString = alerta.geo,
              let coordinates = parseCoordinates(from: geoString),
              !coordinates.isEmpty else { return }
        let p = MKPolygon(coordinates: coordinates, count: coordinates.count)
        self.polygon = p
        self.region = MKCoordinateRegion(p.boundingMapRect.insetBy(
            dx: -p.boundingMapRect.size.width*0.2,
            dy: -p.boundingMapRect.size.height*0.2
        ))
    }
    
    private func parseCoordinates(from geoString: String) -> [CLLocationCoordinate2D]? {
        geoString.split(separator: ";").compactMap { p in
            let c = p.split(separator: ",")
            guard c.count==2, let lat=Double(c[0]), let lon=Double(c[1]) else {return nil}
            return .init(latitude: lat, longitude: lon)
        }
    }
    
    private func formatarData(_ dateString: String?) -> String? {
        guard let dateString else { return nil }
        let f = DateFormatter()
        f.dateFormat = "dd/MM/yyyy HH:mm:ss"
        guard let date = f.date(from: dateString) else { return dateString }
        let rf = RelativeDateTimeFormatter()
        rf.unitsStyle = .full
        return rf.localizedString(for: date, relativeTo: Date())
    }
    
    private func gerarTextoCompartilhamento() -> String {
        "\(localizationManager.string(for: "alert_prefix")) \(alerta.nome ?? localizationManager.string(for: "not_available_short"))\n\n\(alerta.mensagem ?? "")"
    }
    
    @ViewBuilder
    private func infoRow(icon: String, title: String, value: String?) -> some View {
        if let value=value, !value.isEmpty {
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: icon).foregroundColor(.accentColor)
                    Text(title).font(.caption.bold()).foregroundColor(.secondary)
                }
                Text(value).padding(.top, 2)
            }
        }
    }
    
    private func audioPlayer(url: URL) -> some View {
        HStack {
            Text(localizationManager.string(for: "audio"))
            Spacer()
            Button(action: toggleAudioPlayback) {
                Image(systemName: isAudioPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.largeTitle)
            }
        }.onAppear { player = AVPlayer(url: url) }
    }
    
    private func toggleAudioPlayback() {
        guard let player else { return }
        isAudioPlaying.toggle()
        if isAudioPlaying {
            player.seek(to: .zero)
            player.play()
        } else {
            player.pause()
        }
    }
}

//====================================================================//
// MARK: - Views Auxiliares e Componentes Comuns
//====================================================================//

struct Clima {
    // Dados completos para a tela de detalhes
    let cidade: String
    let temperatura: String
    let sensacaoTermica: String
    let condicaoTexto: String
    let velocidadeVentoCompleto: String
    let umidade: String
    let chanceChuvaCompleto: String
    
    // Dados para a UI principal
    let iconeCondicao: String
    let nivelCalorCompleto: String
    let isChovendo: Bool
    let isNoite: Bool
    
    // Dados já separados para os segmentos da barra
    let chuvaTitulo: String
    let chuvaValor: String
    
    let ventoTitulo: String
    let ventoValor: String
    
    let calorTitulo: String
    let calorValor: String
}

class ClimaViewModel: ObservableObject {
    @Published var condicaoClimatica: Clima?
    @Published var isLoading: Bool = false
    @Published var estacoesChuva: [EstacaoChuva] = []
    @Published var estacoesMet: [EstacaoMeteorologica] = []
    @Published var recomendacoes: [Recomendacao] = []
    @Published var nivelCalor: NivelCalor?
    
    private let localizationManager = LocalizationManager.shared

    @MainActor
    func fetchData() async {
        self.isLoading = true
        
        defer { self.isLoading = false }
        
        do {
            async let estacoesMetResult = ColetaDados_EstacaoMeteorologica.getdata()
            async let estacoesCeuResult = EstacaoMetCeu.getEsta()
            async let estacoesChuvaResult = EstacaoSer.getEsta()
            async let solInfoResult = Porenascer.getEsta()
            async let nivelCalorResult = ColetaDados_NCSitu.getdata()
            async let recomendacoesResult = ColetaDados_Recomenda.getdata()

            let recomendacoes = try await recomendacoesResult
            let nivelCalor = try await nivelCalorResult
            
            self.nivelCalor = nivelCalor
            self.recomendacoes = recomendacoes
            
            let estacoesMet = try await estacoesMetResult
            let estacoesCeu = try await estacoesCeuResult
            let estacoesChuva = try await estacoesChuvaResult
            
            self.estacoesChuva = estacoesChuva
            self.estacoesMet = estacoesMet

            let solInfo = try await solInfoResult
            
            let estacaoMetPrincipal = estacoesMet.first
            let estacaoCeuPrincipal = estacoesCeu.first
            let estacaoChuvaPrincipal = estacoesChuva.first
            
            let (tituloCalor, valorCalor) = formatarNivelCalor(situacao: nivelCalor.situacao)
            let (tituloChuva, valorChuva, isChovendo) = formatarChuva(estacao: estacaoChuvaPrincipal)
            let (tituloVento, valorVento) = formatarVento(estacaoMetPrincipal?.vel_med)
            let noite = isNightTime(solInfo: solInfo.first)
            
            self.condicaoClimatica = Clima(
                cidade: "Rio de Janeiro",
                temperatura: formatarTemperatura(estacaoMetPrincipal?.tem_med),
                sensacaoTermica: formatarTemperatura(estacaoMetPrincipal?.tem_med, isSensacao: true),
                condicaoTexto: estacaoCeuPrincipal?.ceu ?? localizationManager.string(for: "unavailable"),
                velocidadeVentoCompleto: valorVento,
                umidade: formatarUmidade(estacaoMetPrincipal?.umd_med),
                chanceChuvaCompleto: valorChuva,
                
                iconeCondicao: iconePara(condicao: estacaoCeuPrincipal?.ceu ?? "", isNoite: noite),
                nivelCalorCompleto: nivelCalor.situacao ?? localizationManager.string(for: "not_available_short"),
                
                isChovendo: isChovendo,
                isNoite: noite,
                
                chuvaTitulo: tituloChuva,
                chuvaValor: valorChuva,
                
                ventoTitulo: tituloVento,
                ventoValor: valorVento,
                
                calorTitulo: tituloCalor,
                calorValor: valorCalor
            )
        } catch {
            print("Erro ao buscar dados do clima: \(error)")
            self.condicaoClimatica = nil
        }
    }
    
    // Funções de formatação e lógica
    private func isNightTime(solInfo: InfoTempoSol?) -> Bool {
        guard let sol = solInfo, let nascer = sol.nascer, let por = sol.por else {
            let hour = Calendar.current.component(.hour, from: Date())
            return hour < 6 || hour > 18
        }
        
        let calendar = Calendar.current
        let agora = Date()
        
        let horaAtual = calendar.component(.hour, from: agora)
        let minutoAtual = calendar.component(.minute, from: agora)
        
        let horaNascer = calendar.component(.hour, from: nascer)
        let minutoNascer = calendar.component(.minute, from: nascer)
        
        let horaPor = calendar.component(.hour, from: por)
        let minutoPor = calendar.component(.minute, from: por)
        
        let minutosAtuais = horaAtual * 60 + minutoAtual
        let minutosNascer = horaNascer * 60 + minutoNascer
        let minutosPor = horaPor * 60 + minutoPor
        
        return minutosAtuais < minutosNascer || minutosAtuais > minutosPor
    }
    
    // MARK: - Funções de Formatação
    private func formatarTemperatura(_ temp: Float?, isSensacao: Bool = false) -> String {
        guard let temp else { return localizationManager.string(for: "not_available_short") }
        return "\(Int(round(temp)))°" + (isSensacao ? "C" : "")
    }
    
    private func formatarNivelCalor(situacao: String?) -> (titulo: String, valor: String) {
        guard let situacao, !situacao.isEmpty else {
            return (localizationManager.string(for: "heat_level"), localizationManager.string(for: "not_available_short"))
        }
        let valor = situacao.replacingOccurrences(of: "calor ", with: "")
        return (localizationManager.string(for: "heat_level"), valor)
    }

    private func formatarVento(_ vel: Float?) -> (titulo: String, valor: String) {
        guard let vel else {
            return (localizationManager.string(for: "wind"), localizationManager.string(for: "not_available_short"))
        }
        let valor = "\(Int(round(vel * 3.6))) km/h"
        return (localizationManager.string(for: "wind"), valor)
    }
    
    private func formatarUmidade(_ umidade: Float?) -> String {
        guard let umidade else { return localizationManager.string(for: "not_available_short") }
        return "\(Int(round(umidade)))%"
    }
    
    private func formatarChuva(estacao: EstacaoChuva?) -> (titulo: String, valor: String, isChovendo: Bool) {
        guard let chuva1h = estacao?.chuva_1 else {
            return (localizationManager.string(for: "rain"), localizationManager.string(for: "not_available_short"), false)
        }
        if chuva1h == 0 {
            return (localizationManager.string(for: "rain"), localizationManager.string(for: "rain_none"), false)
        }
        if chuva1h < 5 {
            return (localizationManager.string(for: "rain"), localizationManager.string(for: "rain_light"), true)
        }
        if chuva1h < 25 {
            return (localizationManager.string(for: "rain"), localizationManager.string(for: "rain_moderate"), true)
        }
        return (localizationManager.string(for: "rain"), localizationManager.string(for: "rain_heavy"), true)
    }
    
    private func iconePara(condicao: String, isNoite: Bool) -> String {
        let texto = condicao.lowercased()
        print(texto)
        
        if texto.contains("chuva") { return "cloud.rain.fill" }
        if texto.contains("tempestade") { return "cloud.bolt.rain.fill" }
        if texto.contains("névoa") || texto.contains("nevoeiro") { return "cloud.fog.fill" }
        
        if texto.contains("parcialmente") {
            return isNoite ? "cloud.moon.fill" : "cloud.sun.fill"
        }
        
        if texto.contains("nublado") {
            return "cloud.fill"
        }

        if texto.contains("claro") || texto.contains("sol") || texto.isEmpty {
            return isNoite ? "moon.stars.fill" : "sun.max.fill"
        }
        
        return isNoite ? "moon.fill" : "sun.max.fill"
    }
}

struct ClimaCardView: View {
    @StateObject private var viewModel = ClimaViewModel()
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    let pontosDeApoio: [PontoDeApoio]
    let unidadesDeSaude: [PontoDeApoio]
    let pontosDeResfriamento: [PontoDeApoio]
    let nivelCalor: NivelCalor
    let recomendacoes: [Recomendacao]
    
    @State private var activeSheet: ClimaSheet?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Cabeçalho
            HStack(spacing: 12) {
                Image(systemName: "sun.max.fill").font(.system(size: 24, weight: .bold)) .foregroundColor(.white)
                Text(localizationManager.string(for: "weather_conditions"))
                    .font(.system(size: 24, weight: .bold)) .foregroundColor(.white)
                Spacer()
            }
            .foregroundColor(.white)
            .padding([.top, .horizontal])

            // Lógica de Loading / Conteúdo / Erro
            if viewModel.isLoading {
                HStack { Spacer(); BrandedLoadingView(); Spacer() }.frame(height: 100)
            } else if let condicao = viewModel.condicaoClimatica {
                
                HStack(spacing: 12) {
                    // Botão 1: Nível de Calor
                    Button(action: { activeSheet = .calor }) {
                        InfoSegmentView(
                            icon: "thermometer.sun.fill",
                            value: condicao.calorValor,
                            title: condicao.calorTitulo
                        )
                    }
                    
                    // Botão 2: Chuva
                    Button(action: { activeSheet = .chuva }) {
                        InfoSegmentView(
                            icon: condicao.isChovendo ? "umbrella.fill" : "umbrella",
                            value: condicao.chuvaValor,
                            title: condicao.chuvaTitulo
                        )
                    }
                    
                    // Botão 3: Vento
                    Button(action: { activeSheet = .vento }) {
                        InfoSegmentView(
                            icon: "wind",
                            value: condicao.ventoValor,
                            title: condicao.ventoTitulo
                        )
                    }
                }
                .buttonStyle(CardButtonStyle())
                .padding([.horizontal, .bottom])

            } else {
                EmptyStateView(
                    icon: "wifi.exclamationmark",
                    message: localizationManager.string(for: "data_unavailable")
                )
            }
        }
        .background(cardGradient)
        .cornerRadius(12)
        .overlay(cardBorder)
        .shadow(color: Color.black.opacity(0.8), radius: 4, x: 0, y: 1)
        .padding(.horizontal, 16)
        .task {
            await viewModel.fetchData()
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .calor:
                PontosResfriamentoView(
                    pontosUnidadesSaude: self.unidadesDeSaude,
                    pontosResfriamento: self.pontosDeResfriamento,
                    nivelCalor: self.nivelCalor,
                    recomendacoes: self.recomendacoes
                )
            case .chuva:
                ChuvaDetalhesView(estacoes: viewModel.estacoesChuva)
            case .vento:
                VentoDetalhesView(estacoes: viewModel.estacoesMet)
            }
        }
    }
}

struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

enum ClimaSheet: Identifiable {
    case calor, chuva, vento
    var id: Self { self }
}

private struct InfoSegmentView: View {
    let icon: String
    let value: String
    let title: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .symbolRenderingMode(.multicolor)
                .foregroundColor(.white)
            
            (
                Text(title.uppercased())
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.7))
                +
                Text("\n" + value)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            )
            .multilineTextAlignment(.center)
            .lineLimit(3)
            .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
    }
}


//====================================================================//
// MARK: - Views Auxiliares e Componentes Comuns
//====================================================================//

struct HighlightedText: View {
    let text: String
    let keywords: [String]
    
    var body: some View {
        Text(highlightedString())
    }
    
    private func highlightedString() -> AttributedString {
        var attrString = AttributedString(text)
        for keyword in keywords {
            if let range = attrString.range(of: keyword, options: .caseInsensitive) {
                attrString[range].font = .body.bold()
                attrString[range].foregroundColor = .yellow
            }
        }
        return attrString
    }
}

struct LoadingView: View {
    let message: String
    var body: some View {
        HStack {
            Spacer()
            VStack {
                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)).scaleEffect(1.5)
                Text(message).foregroundColor(.white).padding(.top, 8)
            }
            Spacer()
        }.frame(minHeight: 120).padding(.vertical, 12)
    }
}

private let cardGradient = LinearGradient(gradient: Gradient(colors: [
    Color(red: 0.1, green: 0.5, blue: 0.9),
    Color(red: 0.3, green: 0.6, blue: 0.9)
]), startPoint: .top, endPoint: .bottom)

private var cardBorder: some View {
    RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.2), lineWidth: 1)
}

struct PolygonAnnotation: Identifiable {
    let id = UUID()
    let polygon: MKPolygon
    var coordinate: CLLocationCoordinate2D { polygon.coordinate }
}

//====================================================================//
// MARK: - Helper para a Folha de Compartilhamento
//====================================================================//
struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct PolygonMapView: UIViewRepresentable {
    
    @Binding var region: MKCoordinateRegion
    let polygon: MKPolygon
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.setRegion(region, animated: false)
        mapView.addOverlay(polygon)
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.removeOverlays(uiView.overlays)
        uiView.addOverlay(polygon)
        uiView.setRegion(region, animated: true)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: PolygonMapView
        
        init(_ parent: PolygonMapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polygon = overlay as? MKPolygon {
                let renderer = MKPolygonRenderer(polygon: polygon)
                renderer.fillColor = UIColor.red.withAlphaComponent(0.3)
                renderer.strokeColor = UIColor.red
                renderer.lineWidth = 2
                return renderer
            }
            return MKOverlayRenderer()
        }
    }
}

struct GlassBackground: View {
    var body: some View {
        ZStack {
            VisualEffectBlur(blurStyle: .systemUltraThinMaterialDark)
            
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.4),
                    Color.black.opacity(0.2)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            
            GeometryReader { geometry in
                Path { path in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let gridSize: CGFloat = 20
                    
                    for x in stride(from: 0, to: width, by: gridSize) {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: height))
                    }
                    
                    for y in stride(from: 0, to: height, by: gridSize) {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: width, y: y))
                    }
                }
                .stroke(Color.white.opacity(0.02), lineWidth: 0.5)
            }
            
            VStack {
                Spacer()
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0),
                        Color.white.opacity(0.2),
                        Color.white.opacity(0)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 1)
            }
        }
    }
}

struct VisualEffectBlur: UIViewRepresentable {
    let blurStyle: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
