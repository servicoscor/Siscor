import SwiftUI
import MapKit
import CoreLocation

// MARK: - View Principal do Mapa de Unidades de Saúde
struct UnidadesSaudeView: View {
    // A view recebe a lista de unidades como uma constante.
    let unidades: [PontoDeApoio]
    
    // Propriedades de ambiente e gerenciadores de estado.
    @Environment(\.dismiss) private var dismiss
    @StateObject private var localizationManager = LocalizationManager.shared
    @StateObject private var locationManager = LocationManager()
    
    // Estados para controlar a UI
    @State private var region: MKCoordinateRegion
    @State private var searchText: String = ""
    @State private var unidadeSelecionada: PontoDeApoio? = nil
    
    // Estado para a lista de unidades que será exibida no mapa.
    // Esta lista é atualizada de forma inteligente para otimizar a performance.
    @State private var displayableUnidades: [PontoDeApoio] = []

    // Inicializador que define a região inicial do mapa.
    init(unidades: [PontoDeApoio]) {
        self.unidades = unidades
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: -22.908333, longitude: -43.196388), // Centro do Rio de Janeiro
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        ))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header com estilo integrado
            VStack(spacing: 12) {
                HStack {
                    Text(localizationManager.string(for: "health_units"))
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
                
                // Barra de busca integrada ao header
                HStack {
                    Image(systemName: "magnifyingglass").foregroundColor(.gray)
                    TextField(localizationManager.string(for: "search_unit_placeholder"), text: $searchText)
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            .padding()
            .background(.thinMaterial)
            
            Group {
                // Mostra uma tela de carregamento até a localização do usuário ser obtida.
                if locationManager.location != nil {
                    mapView
                } else {
                    loadingView
                }
            }
            // Centraliza o mapa no usuário na primeira vez que a localização é encontrada.
            .onChange(of: locationManager.location) { newLocation in
                if let newLocation, region.center.latitude == -22.908333 {
                    region = MKCoordinateRegion(
                        center: newLocation.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    )
                }
            }
            // Exibe o painel de detalhes quando uma unidade é selecionada.
            .sheet(item: $unidadeSelecionada) { unidade in
                UnidadeDetalheView(unidade: unidade, userLocation: locationManager.location)
                    .presentationDetents([.height(280), .medium])
            }
            // Otimização de performance: executa a filtragem apenas quando a busca muda.
            // Isso evita que os pinos pisquem ao mover o mapa.
            .task(id: searchText) {
                filterUnits()
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }
    
    // MARK: - Subviews
    
    private var mapView: some View {
        ZStack {
            // O Mapa, usando a lista otimizada 'displayableUnidades'.
            Map(coordinateRegion: $region,
                showsUserLocation: true,
                annotationItems: displayableUnidades) { unidade in
                MapAnnotation(coordinate: unidade.coordinate!) { // O '!' é seguro devido à filtragem.
                    Button(action: { unidadeSelecionada = unidade }) {
                        AnnotationView(isSelected: unidadeSelecionada?.id == unidade.id)
                    }
                }
            }
            .ignoresSafeArea()
            
            // Camada de controles sobre o mapa.
            overlayControls
        }
    }
    
    private var overlayControls: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Elementos inferiores com contador e botão de localização.
            BottomBarView(
                unidadesCount: displayableUnidades.count,
                centerAction: centerOnUserLocation
            )
        }
    }
    
    private var loadingView: some View {
        VStack {
            ProgressView().scaleEffect(1.5)
            Text(localizationManager.string(for: "getting_location"))
                .font(.headline)
                .padding(.top)
        }
    }
    
    // MARK: - Funções
    
    /// Filtra as unidades com base no texto de busca e atualiza o estado `displayableUnidades`.
    private func filterUnits() {
        // 1. Garante que todas as unidades tenham coordenadas válidas.
        let unidadesComCoordenadas = unidades.filter { $0.coordinate != nil }

        // 2. Aplica o filtro de busca de texto, se houver.
        if searchText.isEmpty {
            displayableUnidades = unidadesComCoordenadas
        } else {
            let lowercasedSearchText = searchText.lowercased()
            displayableUnidades = unidadesComCoordenadas.filter {
                $0.nome?.lowercased().contains(lowercasedSearchText) ?? false
            }
        }
    }
    
    /// Centraliza o mapa na localização atual do usuário.
    private func centerOnUserLocation() {
        if let location = locationManager.location {
            withAnimation {
                region.center = location.coordinate
                region.span = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            }
        }
    }
}

// MARK: - Componentes da UI Reutilizáveis

/// View customizada para a anotação (pino) no mapa.
struct AnnotationView: View {
    let isSelected: Bool
    
    var body: some View {
        ZStack {
            // Círculo branco de fundo que muda de tamanho e sombra
            Circle()
                .fill(Color.white)
                .frame(width: isSelected ? 50 : 40, height: isSelected ? 50 : 40)
                .shadow(color: .red.opacity(0.4), radius: isSelected ? 8 : 3)
        
            // Ícone da unidade de saúde, que também muda de tamanho
            Image(systemName: "cross.circle.fill")
                .font(.system(size: isSelected ? 35 : 28))
                .foregroundColor(.red)
        }
        // Efeito de escala para dar a sensação de "pulso"
        .scaleEffect(isSelected ? 1.1 : 1.0)
        // Animação suave para todas as mudanças
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

/// Barra inferior com o contador de unidades e o botão de centralizar.
struct BottomBarView: View {
    let unidadesCount: Int
    let centerAction: () -> Void
    @StateObject private var localizationManager = LocalizationManager.shared

    var body: some View {
        VStack(spacing: 12) {
            if unidadesCount > 0 {
                Text(localizationManager.string(for: "units_found").localized(with: unidadesCount))
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.thinMaterial)
                    .cornerRadius(20)
            }
            HStack {
                Spacer()
                Button(action: centerAction) {
                    Image(systemName: "location.fill")
                        .font(.title2)
                        .padding()
                        .background(.thinMaterial)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
            }
        }
        .padding()
    }
}

/// Painel de detalhes exibido ao tocar em uma unidade.
struct UnidadeDetalheView: View {
    let unidade: PontoDeApoio
    let userLocation: CLLocation?
    
    private var distancia: String {
        guard let userLocation = userLocation, let unidadeCoordinate = unidade.coordinate else { return "N/D" }
        let unidadeLocation = CLLocation(latitude: unidadeCoordinate.latitude, longitude: unidadeCoordinate.longitude)
        let distanceInMeters = userLocation.distance(from: unidadeLocation)
        
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .naturalScale
        formatter.numberFormatter.maximumFractionDigits = 1
        return formatter.string(from: Measurement(value: distanceInMeters, unit: UnitLength.meters))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(unidade.nome ?? "Unidade de Saúde")
                .font(.title2.bold())

            if let endereco = unidade.endereco {
                InfoRow(label: "Endereço", value: endereco)
            }
            
            InfoRow(label: "Distância Aprox.", value: distancia)
            
            Button(action: {
                if let coordinate = unidade.coordinate {
                    let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
                    mapItem.name = unidade.nome
                    mapItem.openInMaps()
                }
            }) {
                Label("Ver Rotas no Mapa", systemImage: "arrow.triangle.turn.up.right.circle.fill")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .font(.headline)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical)
    }
}
