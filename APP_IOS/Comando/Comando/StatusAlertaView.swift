import SwiftUI
import MapKit
import AVKit
import CoreLocation

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
        GeometryReader { geo in
            let topSafe = geo.safeAreaInsets.top
            ZStack {
                Image(nomeImagemFundo)
                    .resizable()
                    .scaledToFill()
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height + 200)
                    .offset(y: min(max(debouncedScrollOffset * 0.3, -150), 150))
                    .animation(isScrolling ? nil : .easeOut(duration: 0.3), value: debouncedScrollOffset)
                    .id(nomeImagemFundo)
                    .ignoresSafeArea()
                    .clipped()
                
                ScrollViewReader { scrollProxy in
                    ZStack {
                        OptimizedScrollView(offset: $scrollOffset, isScrolling: $isScrolling) {
                            VStack(spacing: 0) {
                                VStack(spacing: 12) {
                                    // 1. Cabeçalho de clima local
                                    ClimaLocalHeaderView()
                                        .drawingGroup()
                                    
                                    // Espaço entre Clima e Câmeras: garantir 12–16pt
                                    Color.clear.frame(height: 12)
                                    
                                    // 2. Câmeras logo abaixo do clima
                                    CamerasMapView(cameras: self.cameras)
                                        .padding(.top, 0) // já controlado internamente
                                    
                                    // 3. Alertas (REMOVIDO: AlertasCardView ausente no escopo)
                                    // Caso precise de alertas, reintroduza a view quando o arquivo estiver no target.
                                    
                                    LazyVStack(spacing: 16) {
                                        InformesTempoView(informes: self.infoTempo, isLoading: self.isLoading)
                                        
                                        RadarCardView(onExpand: {
                                            self.isRadarExpanded = true
                                        })
                                        
                                        Color.clear.frame(height: 16)
                                        
                                        HStack(spacing: 12) {
                                            TransitoCardView(action: {
                                                print("Botão de Trânsito foi tocado!")
                                            })
                                            InterdicoesCardView(action: {
                                                self.isInterdicoesExpanded = true
                                            })
                                        }
                                        .padding(.horizontal, 12)
                                        
                                        InformesTransitoCardView(
                                            informes: self.infoTransito,
                                            isLoading: self.isLoading
                                        )
                                        
                                        Color.clear.frame(height: 16)
                                        
                                        HStack(spacing: 12) {
                                            SirenesStatusButton(
                                                action: { self.isAlarmeExpanded = true },
                                                sirenes: self.sirenes
                                            )
                                            PontosApoioButton(action: {
                                                self.isPontosApoioExpanded = true
                                            })
                                        }
                                        .padding(.horizontal, 12)
                                        
                                        SistemaAlarmeMapView(sirenes: self.sirenes, onExpand: {
                                            self.isAlarmeExpanded = true
                                        })
                                        
                                        Color.clear.frame(height: 16)
                                        
                                        BotoesFinaisView(
                                            isUnidadesSaudeExpanded: $isUnidadesSaudeExpanded,
                                            isPontosTuristicosExpanded: $isPontosTuristicosExpanded
                                        )
                                        
                                        Color.clear.frame(height: 200)
                                    }
                                }
                            }
                        }
                        .onChange(of: scrollOffset) { newValue in
                            scrollDebounceTimer?.invalidate()
                            scrollDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: false) { _ in
                                withAnimation(.easeOut(duration: 0.2)) {
                                    debouncedScrollOffset = newValue
                                }
                            }
                        }
                        // Espaço superior seguro: TopBar + margem
                        .safeAreaInset(edge: .top) {
                            Color.clear
                                .frame(height: topSafe + 70)
                        }
                        
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
                            .zIndex(10)
                            
                            Spacer()
                        }
                    }
                }
                
                if viewModel.isLoading && viewModel.isDataLoaded {
                    LoadingOverlay()
                        .transition(.opacity)
                        .zIndex(20)
                }
            }
            .onDisappear {
                scrollDebounceTimer?.invalidate()
            }
        }
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
    }
}

// MARK: - Novo Cabeçalho de Clima Local (compactado)
struct ClimaLocalHeaderView: View {
    @StateObject private var climaVM = ClimaViewModel()
    @StateObject private var locationManager = LocationManager()
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @EnvironmentObject private var appVM: CORViewModel
    
    @State private var bairro: String = ""
    @State private var isGeocoding = false
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Spacer()
                Text(bairro.isEmpty ? localizationManager.string(for: "getting_location") : bairro)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
                Spacer()
            }
            .padding(.horizontal, 16)
            
            if let cond = climaVM.condicaoClimatica {
                Image(systemName: cond.iconeCondicao)
                    .font(.system(size: 44, weight: .bold))
                    .symbolRenderingMode(.multicolor)
                    .foregroundColor(.white)
                    .padding(.top, -2)
            }
            
            if let cond = climaVM.condicaoClimatica {
                HStack(spacing: 8) {
                    Button { } label: {
                        Pill(icon: "thermometer.sun.fill", value: cond.calorValor)
                    }
                    Button { } label: {
                        Pill(icon: cond.isChovendo ? "umbrella.fill" : "umbrella", value: cond.chuvaValor)
                    }
                    Button { } label: {
                        Pill(icon: "wind", value: cond.ventoValor)
                    }
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.top, -2)
            } else if climaVM.isLoading {
                HStack {
                    BrandedLoadingView()
                        .frame(height: 40)
                    Spacer()
                }
                .padding(.horizontal, 16)
            } else {
                HStack {
                    Image(systemName: "wifi.exclamationmark")
                        .foregroundColor(.white)
                    Text(localizationManager.string(for: "data_unavailable"))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 8)
        .background(.clear)
        .padding(.horizontal, 12)
        .task {
            await climaVM.fetchData()
        }
        .onAppear {
            if locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways {
                locationManager.startUpdatingLocation()
            } else if locationManager.authorizationStatus == .notDetermined {
                locationManager.requestLocationPermission()
            }
        }
        .onChange(of: locationManager.location) { _ in
            atualizarBairro()
        }
        .onChange(of: locationManager.authorizationStatus) { status in
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                locationManager.startUpdatingLocation()
            }
        }
    }
    
    private func atualizarBairro() {
        guard !isGeocoding, let location = locationManager.location else { return }
        isGeocoding = true
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            defer { isGeocoding = false }
            if let error = error {
                print("Erro no reverse geocoding: \(error)")
                return
            }
            if let placemark = placemarks?.first {
                let sub = placemark.subLocality?.trimmingCharacters(in: .whitespacesAndNewlines)
                let loc = placemark.locality?.trimmingCharacters(in: .whitespacesAndNewlines)
                self.bairro = (sub?.isEmpty == false ? sub : loc) ?? ""
            }
        }
    }
    
    private struct Pill: View {
        let icon: String
        let value: String
        
        var body: some View {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .symbolRenderingMode(.multicolor)
                    .foregroundColor(.white)
                Text(value)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, minHeight: 36)
            .background(Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
        }
    }
}

// MARK: - Loading Overlay Component
struct LoadingOverlay: View {
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
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
            if abs(offset - value) > 2 {
                isScrolling = true
                offset = value
                scrollTimer?.invalidate()
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
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, minHeight: 100)
            .background(
                LinearGradient(
                    colors: [Color.blue, Color.blue.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

//====================================================================//
// MARK: - Subviews Locais (REMOVIDO: EstagioView antigo e troféus)
//====================================================================//

//====================================================================//
// MARK: - View do Card de Alertas (mantida em outro arquivo, se necessário)
//====================================================================//

//====================================================================//
// MARK: - ViewModel de Clima e Model (RESTAURADOS)
//====================================================================//

struct Clima {
    let cidade: String
    let temperatura: String
    let sensacaoTermica: String
    let condicaoTexto: String
    let velocidadeVentoCompleto: String
    let umidade: String
    let chanceChuvaCompleto: String
    let iconeCondicao: String
    let nivelCalorCompleto: String
    let isChovendo: Bool
    let isNoite: Bool
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
