import SwiftUI
import MapKit
import Combine

class CORViewModel: ObservableObject {
    // MARK: - Propriedades de Estado Completas
    @Published var eventos: [Evento] = []
    @Published var alertas: [Alerta] = []
    @Published var infoTempo: [InformeTempo] = []
    @Published var infoTransito: [InformeTrânsito] = []
    @Published var cameras: [Camera] = []
    @Published var sirenes: [Sirene] = []
    @Published var pontosDeApoio: [PontoDeApoio] = []
    @Published var unidadesDeSaude: [PontoDeApoio] = []
    @Published var pontosDeResfriamento: [PontoDeApoio] = []
    @Published var nivelCalor: NivelCalor?
    @Published var recomendacoes: [Recomendacao] = []
    
    // Para o estado da UI
    @Published var nomeImagemFundo: String = "ceuclaro"
    @Published var isLoading = false
    @Published var isDataLoaded = false
    
    // Para o estágio operacional
    @Published var estagioOperacional: Int = 1
    
    // Para controle de idioma
    private var cancellables = Set<AnyCancellable>()
    private let localizationManager = LocalizationManager.shared
    
    // Timer para evitar múltiplos reloads simultâneos
    private var reloadTimer: Timer?
    private var lastReloadDate: Date?
    
    init() {
        setupLanguageObserver()
        setupAppLifecycleObservers()
    }
    
    private func setupLanguageObserver() {
        // Observa mudanças no idioma
        NotificationCenter.default.publisher(for: NSNotification.Name("LanguageChanged"))
            .sink { [weak self] _ in
                print("🌐 Idioma mudou, recarregando dados...")
                Task {
                    await self?.fetchData()
                }
            }
            .store(in: &cancellables)
    }
    
    // Configurar observadores do ciclo de vida do app
    private func setupAppLifecycleObservers() {
        // Observa quando o app volta do background
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.appDidBecomeActive()
            }
            .store(in: &cancellables)
        
        // Observa quando o app vai para background
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.appDidEnterBackground()
            }
            .store(in: &cancellables)
        
        // Observa notificação customizada do AppDelegate
        NotificationCenter.default.publisher(for: NSNotification.Name("AppDidBecomeActive"))
            .sink { [weak self] _ in
                print("📱 Notificação AppDidBecomeActive recebida")
                self?.appDidBecomeActive()
            }
            .store(in: &cancellables)
    }
    
    // Método chamado quando o app volta do background
    private func appDidBecomeActive() {
        print("🔄 App voltou do background - verificando se deve recarregar dados...")
        
        // Evita reloads muito frequentes (mínimo 30 segundos entre reloads)
        if let lastReload = lastReloadDate {
            let timeSinceLastReload = Date().timeIntervalSince(lastReload)
            if timeSinceLastReload < 30 {
                print("⏱ Reload ignorado - último reload há \(Int(timeSinceLastReload)) segundos")
                return
            }
        }
        
        // Cancela timer anterior se existir
        reloadTimer?.invalidate()
        
        // Aguarda 1 segundo antes de recarregar (evita múltiplas chamadas)
        reloadTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
            Task {
                await self?.fetchData()
            }
        }
    }
    
    // Método chamado quando o app vai para background
    private func appDidEnterBackground() {
        print("💤 App foi para background")
        // Cancela qualquer timer de reload pendente
        reloadTimer?.invalidate()
        reloadTimer = nil
    }

    // MARK: - Funções de Busca
    
    // ✅✅✅ FUNÇÃO ADICIONADA ✅✅✅
    /// Esta é a função que será chamada pela UI na inicialização.
    @MainActor
    func fetchInitialData() {
        // Garante que os dados não sejam carregados novamente se já existirem.
        guard !isDataLoaded else {
            print("ℹ️ Dados iniciais já carregados. Ignorando a busca.")
            return
        }
        
        // Chama a função principal de busca de dados.
        Task {
            await fetchData()
        }
    }
    
    @MainActor
    func fetchData() async {
        // Evita múltiplos fetchs simultâneos
        guard !self.isLoading else {
            print("⚠️ Fetch já em andamento, ignorando...")
            return
        }
        
        self.isLoading = true
        self.lastReloadDate = Date()
        
        print("🔄 Iniciando carregamento de dados às \(Date())")
        
        do {
            // Buscando todos os dados necessários em paralelo.
            async let alertasData = ColetaDados_Alertas.getdata()
            async let tempoData = ColetaDados_TTA.getdata()
            async let transitoData = ColetaDados_TTT.getdata()
            async let camerasData = ColetaDados_Cameras.getdata()
            async let sirenesData = ColetaDados_Sirene.getdata()
            async let pontosApoioData = ColetaDados_PA.getdata()
            async let unidadesSaudeData = ColetaDados_CF.getdata()
            async let pontosResfriamentoData = ColetaDados_FR.getdata()
            async let nivelCalorData = ColetaDados_NCSitu.getdata()
            async let recomendacoesData = ColetaDados_Recomenda.getdata()
            async let eventosData = ColetaDados_Eventos.getdata()
            async let estacoesChuvaData = EstacaoSer.getEsta()
            async let estacoesCeuData = EstacaoMetCeu.getEsta()
            async let nascerPorSolData = Porenascer.getEsta()
            async let estagioData = ColetaDados_Situ.getdata()
            
            // Atribuindo todos os resultados.
            self.alertas = try await alertasData
            self.infoTempo = try await tempoData
            self.infoTransito = try await transitoData
            self.cameras = try await camerasData
            self.sirenes = try await sirenesData
            self.pontosDeApoio = try await pontosApoioData
            self.unidadesDeSaude = try await unidadesSaudeData
            self.pontosDeResfriamento = try await pontosResfriamentoData
            self.nivelCalor = try await nivelCalorData
            self.recomendacoes = try await recomendacoesData
            self.eventos = try await eventosData
            
            // Atualiza o estágio operacional
            if let estagioStr = (try await estagioData).estagio,
               let estagioNum = Int(estagioStr) {
                self.estagioOperacional = estagioNum
            }
            
            self.atualizarImagemFundo(
                estacoesChuva: try await estacoesChuvaData,
                estacoesCeu: try await estacoesCeuData,
                solInfo: try await nascerPorSolData.first
            )
            
            print("✅ Dados carregados com sucesso para o idioma: \(localizationManager.currentLanguage)")
            print("📊 Resumo: \(alertas.count) alertas, \(eventos.count) eventos, \(cameras.count) câmeras")
            
        } catch {
            print("❌ Erro ao carregar dados: \(error)")
        }
        
        self.isLoading = false
        self.isDataLoaded = true
    }

    // MARK: - Lógica do Background Dinâmico
    
    private func atualizarImagemFundo(estacoesChuva: [EstacaoChuva], estacoesCeu: [EstacaoCeu], solInfo: InfoTempoSol?) {
        var chuvaMedia: Double = 0.0
        if !estacoesChuva.isEmpty {
            let chuvasValidas = estacoesChuva.filter { !($0.situ?.contains("atraso") ?? true) }
            let valoresChuva = chuvasValidas.compactMap { $0.chuva_1 }.map { Double($0) }
            chuvaMedia = valoresChuva.max() ?? 0.0
        }

        let condicaoCeu = estacoesCeu.first?.ceu ?? "0"
        let isNight = isNightTime(solInfo: solInfo)
        
        if chuvaMedia > 1 {
            self.nomeImagemFundo = isNight ? "chuva_noite" : "chuva_dia"
            return
        } else if chuvaMedia != 0 {
            self.nomeImagemFundo = isNight ? "noite_nublado_p" : "dia_nublado_p"
            return
        }

        switch condicaoCeu {
        case "0":
            self.nomeImagemFundo = isNight ? "noite_claro_p" : "dia_claro_p"
        case "1":
            self.nomeImagemFundo = isNight ? "noite_nuvens_p" : "dia_nuvens_p"
        case "2":
            self.nomeImagemFundo = isNight ? "noite_nublado_p" : "dia_nublado_p"
        default:
            self.nomeImagemFundo = isNight ? "noite_claro_p" : "dia_claro_p"
        }
        print("🌤 Imagem de fundo atualizada para: \(self.nomeImagemFundo)")
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
    
    // MARK: - Refresh Manual
    @MainActor
    func refresh() async {
        print("🔄 Refresh manual solicitado")
        await fetchData()
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
        reloadTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
}
