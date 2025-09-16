import SwiftUI
import MapKit
import CoreLocation
import Combine

//====================================================================//
// MARK: - View de Tela Cheia: Pontos de Apoio (Versão Otimizada)
//====================================================================//
struct PontosResfriamentoView: View {
    // Dados recebidos
    let pontosUnidadesSaude: [PontoDeApoio]
    let pontosResfriamento: [PontoDeApoio]
    let nivelCalor: NivelCalor
    let recomendacoes: [Recomendacao]
    
    // Estados da View
    @Environment(\.dismiss) private var dismiss
    @StateObject private var locationManager = LocationManager()
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var region: MKCoordinateRegion
    @State private var searchText: String = ""
    @State private var showingRecommendations = false
    @State private var showingLegend = false
    @State private var hasInitializedLocation = false
    @State private var mapReady = false
    
    // Pontos criados apenas uma vez
    private let allAnnotatedPoints: [AnnotatedPoint]
    
    // Computed property apenas para filtrar
    private var filteredPontos: [AnnotatedPoint] {
        if searchText.isEmpty {
            return allAnnotatedPoints
        }
        return allAnnotatedPoints.filter {
            $0.nome.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    init(pontosUnidadesSaude: [PontoDeApoio], pontosResfriamento: [PontoDeApoio],
         nivelCalor: NivelCalor, recomendacoes: [Recomendacao]) {
        self.pontosUnidadesSaude = pontosUnidadesSaude
        self.pontosResfriamento = pontosResfriamento
        self.nivelCalor = nivelCalor
        self.recomendacoes = recomendacoes
        
        // Criar os pontos anotados apenas UMA VEZ
        self.allAnnotatedPoints = pontosUnidadesSaude.map { AnnotatedPoint(original: $0, tipo: .unidadeSaude) } +
                                  pontosResfriamento.map { AnnotatedPoint(original: $0, tipo: .pontoResfriamento) }
        
        // Usar uma região temporária bem pequena
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        ))
    }

    var body: some View {
        ZStack {
            // Mostrar o mapa apenas quando tivermos uma localização ou após timeout
            if mapReady {
                Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: filteredPontos) { ponto in
                    MapAnnotation(coordinate: ponto.coordinate) {
                        PontoAnnotationView(ponto: ponto)
                    }
                }
                .ignoresSafeArea()
                .transition(.opacity)
            } else {
                // Tela de carregamento enquanto obtém localização
                ZStack {
                    Color(.systemBackground)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        
                        Text(localizationManager.string(for: "locating_you"))
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        if locationManager.authorizationStatus == .denied ||
                           locationManager.authorizationStatus == .restricted {
                            Text(localizationManager.string(for: "location_permission_needed"))
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                }
            }
            
            // Feedback visual para estados vazios
            if mapReady && filteredPontos.isEmpty && !searchText.isEmpty {
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Text(String(format: localizationManager.string(for: "no_points_found_for"), searchText))
                    }
                    .padding()
                    .background(Color.black.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding()
                    Spacer()
                }
            }

            if mapReady {
                VStack(spacing: 0) {
                    HeaderResfriamentoView(searchText: $searchText, onDismiss: { dismiss() })
                    NivelCalorBarra(nivelCalor: nivelCalor, action: { showingRecommendations = true })
                    Spacer()
                    ControlesMapaFlutuantes(
                        onInfo: { showingLegend = true },
                        onCenter: centerOnUser
                    )
                }
            }
        }
        .onAppear {
            setupInitialLocation()
        }
        .onReceive(locationManager.$location) { location in
            if let location = location, !hasInitializedLocation {
                hasInitializedLocation = true
                updateRegionToUserLocation(location)
            }
        }
        .sheet(isPresented: $showingRecommendations) {
            RecomendacoesView(recomendacoes: recomendacoes, nivelCalor: nivelCalor)
        }
        .sheet(isPresented: $showingLegend) {
            LegendaResfriamentoSheetView().presentationDetents([.height(250)])
        }
    }
    
    private func setupInitialLocation() {
        // Se já temos uma localização, usar ela imediatamente
        if let location = locationManager.location {
            updateRegionToUserLocation(location)
            return
        }
        
        // Caso contrário, aguardar um pouco e então mostrar o mapa
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if !mapReady {
                // Se ainda não temos localização após 2 segundos,
                // mostrar o mapa centralizado nos pontos disponíveis
                if allAnnotatedPoints.isEmpty {
                    // Usar localização padrão do Rio se não houver pontos
                    region = MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: -22.9068, longitude: -43.1729),
                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    )
                } else {
                    // Centralizar nos pontos disponíveis
                    let coordinates = allAnnotatedPoints.map { $0.coordinate }
                    region = .fitting(coordinates: coordinates)
                }
                withAnimation(.easeIn(duration: 0.3)) {
                    mapReady = true
                }
            }
        }
    }
    
    private func updateRegionToUserLocation(_ location: CLLocation) {
        withAnimation(.easeOut(duration: 0.5)) {
            region = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
            mapReady = true
        }
    }
    
    private func centerOnUser() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let userLocation = locationManager.location?.coordinate {
                withAnimation(.easeOut) {
                    region = MKCoordinateRegion(
                        center: userLocation,
                        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                    )
                }
            }
        }
    }
}

//====================================================================//
// MARK: - Componentes da Tela
//====================================================================//

private struct HeaderResfriamentoView: View {
    @Binding var searchText: String
    var onDismiss: () -> Void
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(localizationManager.string(for: "cooling_health_points"))
                    .font(.title3.bold())
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.body.weight(.bold))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(8)
                        .background(VisualEffectBlur(blurStyle: .systemUltraThinMaterialDark))
                        .clipShape(Circle())
                }
                .accessibilityLabel(localizationManager.string(for: "close_map"))
            }
            HStack {
                Image(systemName: "magnifyingglass").foregroundColor(.gray)
                TextField(localizationManager.string(for: "search_points"), text: $searchText)
                    .accessibilityLabel(localizationManager.string(for: "search_points_field"))
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .accessibilityLabel(localizationManager.string(for: "clear_search"))
                }
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .padding()
        .background(.thinMaterial)
    }
}

private struct NivelCalorBarra: View {
    let nivelCalor: NivelCalor
    let action: () -> Void
    @StateObject private var localizationManager = LocalizationManager.shared
    
    private var corGradiente: [Color] {
        let situacao = nivelCalor.situacao?.lowercased() ?? ""
        if situacao.contains("5") { return [Color(red: 0.8, green: 0, blue: 0.2), Color(red: 0.5, green: 0, blue: 0.1)] }
        if situacao.contains("4") { return [.red, .orange] }
        if situacao.contains("3") { return [.orange, .yellow] }
        if situacao.contains("2") { return [.yellow, .green] }
        return [.cyan, .blue]
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: "thermometer.sun.fill")
                    .font(.title)
                    .symbolRenderingMode(.multicolor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(localizationManager.string(for: "we_are_in"))
                        .font(.caption.bold())
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(localizeHeatLevel(nivelCalor.situacao ?? localizationManager.string(for: "unavailable")))
                        .font(.headline.weight(.heavy))
                        .foregroundColor(.white)
                }

                Spacer()
                
                Text(localizationManager.string(for: "recommendations"))
                    .font(.footnote.weight(.semibold))
                Image(systemName: "chevron.right")
            }
            .foregroundColor(.white)
            .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
            .background(
                LinearGradient(
                    gradient: Gradient(colors: corGradiente),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .shadow(color: .black.opacity(0.4), radius: 5, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(format: localizationManager.string(for: "heat_level_accessibility"),
                                  localizeHeatLevel(nivelCalor.situacao ?? localizationManager.string(for: "unavailable"))))
    }
    
    private func localizeHeatLevel(_ level: String) -> String {
        // Se necessário, traduzir os níveis de calor
        // Por enquanto, retorna como está
        return level
    }
}

private struct ControlesMapaFlutuantes: View {
    var onInfo: () -> Void
    var onCenter: () -> Void
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        HStack {
            Spacer()
            VStack(spacing: 16) {
                Button(action: onInfo) {
                    Image(systemName: "info.circle.fill")
                        .font(.title2)
                        .padding()
                        .background(.thinMaterial)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .accessibilityLabel(localizationManager.string(for: "info_and_legend"))
                
                Button(action: onCenter) {
                    Image(systemName: "location.fill")
                        .font(.title2)
                        .padding()
                        .background(.thinMaterial)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .accessibilityLabel(localizationManager.string(for: "center_on_map"))
            }
            .padding()
        }
    }
}

private struct PontoAnnotationView: View {
    let ponto: AnnotatedPoint
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .fill(ponto.type.backgroundColor)
                    .frame(width: 36, height: 36)
                    .shadow(radius: 3)
                Image(systemName: ponto.type.icon)
                    .font(.headline.bold())
                    .foregroundColor(ponto.type.color)
            }
            Text(ponto.nome)
                .font(.caption2)
                .padding(4)
                .background(.thinMaterial)
                .cornerRadius(4)
        }
        .accessibilityLabel("\(ponto.type == .unidadeSaude ? localizationManager.string(for: "health_unit") : localizationManager.string(for: "cooling_point")): \(ponto.nome)")
        .accessibilityAddTraits(.isButton)
    }
}

struct LegendaResfriamentoSheetView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            Capsule()
                .fill(Color.secondary)
                .frame(width: 40, height: 5)
                .accessibilityHidden(true)
            
            Text(localizationManager.string(for: "map_legend"))
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 16) {
                    Image(systemName: TipoPonto.pontoResfriamento.icon)
                        .foregroundColor(TipoPonto.pontoResfriamento.color)
                        .font(.title2)
                    Text(localizationManager.string(for: "cooling_point"))
                    Spacer()
                }
                
                HStack(spacing: 16) {
                    Image(systemName: TipoPonto.unidadeSaude.icon)
                        .foregroundColor(TipoPonto.unidadeSaude.color)
                        .font(.title2)
                    Text(localizationManager.string(for: "health_unit"))
                    Spacer()
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            Button(localizationManager.string(for: "close"), action: { dismiss() })
                .buttonStyle(.borderedProminent)
                .padding()
        }
        .padding(.top)
    }
}

struct RecomendacoesView: View {
    let recomendacoes: [Recomendacao]
    let nivelCalor: NivelCalor
    @Environment(\.dismiss) var dismiss
    @StateObject private var localizationManager = LocalizationManager.shared
    
    private var corTema: Color {
        let situacao = nivelCalor.situacao?.lowercased() ?? ""
        if situacao.contains("5") { return Color(red: 0.8, green: 0, blue: 0.2) }
        if situacao.contains("4") { return .red }
        if situacao.contains("3") { return .orange }
        if situacao.contains("2") { return .yellow }
        return .blue
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header com informação do nível
                    HStack {
                        Image(systemName: "thermometer.sun.fill")
                            .font(.largeTitle)
                            .symbolRenderingMode(.multicolor)
                        
                        VStack(alignment: .leading) {
                            Text(localizationManager.string(for: "recommendations_for"))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(nivelCalor.situacao ?? localizationManager.string(for: "current_situation"))
                                .font(.title2.bold())
                        }
                        Spacer()
                    }
                    .padding()
                    .background(corTema.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Lista de recomendações
                    ForEach(recomendacoes) { recomendacao in
                        RecomendacaoCard(recomendacao: recomendacao, corTema: corTema)
                    }
                }
                .padding()
            }
            .navigationTitle(localizationManager.string(for: "essential_care"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localizationManager.string(for: "close")) { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

private struct RecomendacaoCard: View {
    let recomendacao: Recomendacao
    let corTema: Color
    @StateObject private var localizationManager = LocalizationManager.shared
    
    // Função para escolher ícone baseado no conteúdo
    private var icone: String {
        let titulo = (recomendacao.nome ?? "").lowercased()
        if titulo.contains("água") || titulo.contains("hidrat") || titulo.contains("water") || titulo.contains("hydrat") {
            return "drop.fill"
        }
        if titulo.contains("sol") || titulo.contains("protetor") || titulo.contains("sun") || titulo.contains("protect") {
            return "sun.max.fill"
        }
        if titulo.contains("roupa") || titulo.contains("vest") || titulo.contains("cloth") || titulo.contains("wear") {
            return "tshirt.fill"
        }
        if titulo.contains("médic") || titulo.contains("saúde") || titulo.contains("medic") || titulo.contains("health") {
            return "heart.fill"
        }
        if titulo.contains("exercício") || titulo.contains("atividade") || titulo.contains("exercis") || titulo.contains("activ") {
            return "figure.walk"
        }
        if titulo.contains("casa") || titulo.contains("ambiente") || titulo.contains("home") || titulo.contains("indoor") {
            return "house.fill"
        }
        return "info.circle.fill"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(recomendacao.nome!.replacingOccurrences(of: "pulalinha", with: "\n") ?? "")
                .font(.footnote)
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

//====================================================================//
// MARK: - Estruturas de Dados e Helpers
//====================================================================//

private enum TipoPonto {
    case unidadeSaude, pontoResfriamento
    var icon: String { self == .unidadeSaude ? "cross.case.fill" : "snowflake" }
    var color: Color { self == .unidadeSaude ? .red : .blue }
    var backgroundColor: Color { .white }
}

private struct AnnotatedPoint: Identifiable {
    let id: UUID
    let nome: String
    let coordinate: CLLocationCoordinate2D
    let type: TipoPonto
    
    init(original: PontoDeApoio, tipo: TipoPonto? = nil) {
        self.id = original.id ?? UUID()
        self.nome = original.nome ?? "Desconhecido"
        self.coordinate = original.coordinate ?? CLLocationCoordinate2D()
        
        // Se o tipo foi especificado, usa ele. Senão, tenta inferir pelo nome
        if let tipo = tipo {
            self.type = tipo
        } else {
            self.type = (original.nome?.lowercased().contains("saúde") ?? false)
                ? .unidadeSaude : .pontoResfriamento
        }
    }
}

// Extensão para centralizar o mapa nos pontos
extension MKCoordinateRegion {
    static func fitting(coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        guard !coordinates.isEmpty else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: -22.9068, longitude: -43.1729),
                span: MKCoordinateSpan(latitudeDelta: 0.3, longitudeDelta: 0.3)
            )
        }
        
        var minLat: CLLocationDegrees = 90.0
        var maxLat: CLLocationDegrees = -90.0
        var minLon: CLLocationDegrees = 180.0
        var maxLon: CLLocationDegrees = -180.0
        
        for coordinate in coordinates {
            minLat = min(minLat, coordinate.latitude)
            maxLat = max(maxLat, coordinate.latitude)
            minLon = min(minLon, coordinate.longitude)
            maxLon = max(maxLon, coordinate.longitude)
        }
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2.0,
            longitude: (minLon + maxLon) / 2.0
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.5,
            longitudeDelta: (maxLon - minLon) * 1.5
        )
        
        let finalSpan = MKCoordinateSpan(
            latitudeDelta: max(span.latitudeDelta, 0.01),
            longitudeDelta: max(span.longitudeDelta, 0.01)
        )
        
        return MKCoordinateRegion(center: center, span: finalSpan)
    }
}

// MARK: - Chaves de Localização para adicionar ao Localizable.strings

/*
// Português (pt)

*/
