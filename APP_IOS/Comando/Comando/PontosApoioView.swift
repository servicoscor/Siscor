import SwiftUI
import MapKit
import CoreLocation

// MARK: - View Principal (Tela Cheia com Filtros e Zoom)
struct PontosApoioView: View {
    let pontos: [PontoDeApoio]
    @Environment(\.dismiss) private var dismiss
    @StateObject private var localizationManager = LocalizationManager.shared

    // Estados da View
    @State private var region: MKCoordinateRegion
    @StateObject private var locationManager = LocationManager()
    
    // Estados dos Filtros
    @State private var comunidadeSelecionada: String = ""
    @State private var comunidades: [String] = []
    
    // Estados para a seleção de detalhes
    @State private var pontoSelecionado: PontoDeApoio? = nil
    @State private var detalhesAbertos: Bool = false
    @State private var mostrarDetalhesCompletos: Bool = false
    
    // Flag para controlar se já centralizamos na localização do usuário
    @State private var hasInitializedToUserLocation: Bool = false
    
    // Inicializador
    init(pontos: [PontoDeApoio]) {
        self.pontos = pontos
        // Inicializa com coordenadas do Rio, mas será sobrescrito pela localização do usuário
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: -22.908333, longitude: -43.196388),
            span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
        ))
    }
    
    // Filtra os pontos com base no filtro de comunidade
    private var filteredPontos: [PontoDeApoio] {
        var pontosVisiveis = pontos

        if comunidadeSelecionada != localizationManager.string(for: "all_communities") {
            pontosVisiveis = pontosVisiveis.filter { $0.loc == comunidadeSelecionada }
        }
        
        return pontosVisiveis
    }
    
    var body: some View {
        Group {
            if locationManager.location != nil {
                mapView
            } else {
                loadingView
            }
        }
        .onAppear(perform: setupView)
        .onChange(of: comunidadeSelecionada, perform: zoomParaComunidade)
        .onChange(of: locationManager.location) { newLocation in
            // Centraliza no usuário apenas na primeira vez que obtém a localização
            if let newLocation, !hasInitializedToUserLocation {
                withAnimation {
                    region = MKCoordinateRegion(
                        center: newLocation.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                    )
                }
                hasInitializedToUserLocation = true
            }
        }
        .sheet(isPresented: $mostrarDetalhesCompletos) {
            if let ponto = pontoSelecionado {
                PontoApoioPreviewView(
                    ponto: ponto,
                    userLocation: locationManager.location,
                    onClose: {
                        withAnimation {
                            pontoSelecionado = nil
                            detalhesAbertos = false
                        }
                    }
                )
            }
        }
    }
    
    // View do mapa e seus controles
    private var mapView: some View {
        ZStack {
            Map(coordinateRegion: $region,
                showsUserLocation: true,
                annotationItems: filteredPontos) { ponto in
                MapAnnotation(coordinate: ponto.coordinate ?? CLLocationCoordinate2D()) {
                    PontoMapaView(
                        ponto: ponto,
                        isSelected: pontoSelecionado?.id == ponto.id,
                        action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                pontoSelecionado = ponto
                                detalhesAbertos = true
                                
                                // Centraliza no ponto selecionado
                                if let coordinate = ponto.coordinate {
                                    region.center = coordinate
                                }
                            }
                        }
                    )
                }
            }
            .ignoresSafeArea()

            // Controles sobrepostos
            VStack(spacing: 0) {
                // Header com filtros
                VStack(spacing: 12) {
                    HStack {
                        Text(localizationManager.string(for: "support_points"))
                            .font(.title3.bold())
                            .foregroundColor(.primary)
                        Spacer()
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.body.weight(.bold))
                                .foregroundColor(.white.opacity(0.8))
                                .padding(8)
                                .background(VisualEffectBlur(blurStyle: .systemUltraThinMaterialDark))
                                .clipShape(Circle())
                        }
                    }
                    
                    HStack {
                        Text(localizationManager.string(for: "filter_by_community"))
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Picker(localizationManager.string(for: "community"), selection: $comunidadeSelecionada) {
                            ForEach(comunidades, id: \.self) { comunidade in
                                Text(comunidade).tag(comunidade)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.primary)
                    }
                }
                .padding().background(.thinMaterial)
                
                Spacer()
                
                // Botão de localização
                HStack {
                    Spacer()
                    Button(action: {
                        if let location = locationManager.location {
                            withAnimation {
                                region.center = location.coordinate
                                region.span = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                            }
                        }
                    }) {
                        Image(systemName: "location.fill")
                            .font(.title2).padding()
                            .background(.thinMaterial).clipShape(Circle()).shadow(radius: 4)
                    }
                    .accessibilityLabel(localizationManager.string(for: "center_on_my_location"))
                    .padding(.trailing)
                    .padding(.bottom, pontoSelecionado != nil && detalhesAbertos ? 20 : 16)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: detalhesAbertos)
                }
                
                // Preview rápido
                if let ponto = pontoSelecionado, detalhesAbertos {
                    PontoApoioPreviewView(
                        ponto: ponto,
                        userLocation: locationManager.location,
                        onClose: {
                            withAnimation {
                                pontoSelecionado = nil
                                detalhesAbertos = false
                            }
                        }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }
    
    // View de carregamento
    private var loadingView: some View {
        VStack {
            ProgressView().scaleEffect(1.5)
            Text(localizationManager.string(for: "getting_location"))
                .font(.headline)
                .padding(.top)
        }
    }
    
    // MARK: - Funções da View
    private func setupView() {
        let todasComunidades = Set(pontos.compactMap { $0.loc })
        self.comunidades = [localizationManager.string(for: "all_communities")] + todasComunidades.sorted()
        self.comunidadeSelecionada = localizationManager.string(for: "all_communities")
    }
    
    private func zoomParaComunidade(nome: String) {
        let pontosParaZoom: [PontoDeApoio]
        var zoomSpan = MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)

        if nome == localizationManager.string(for: "all_communities") {
            pontosParaZoom = self.pontos
        } else {
            pontosParaZoom = self.pontos.filter { $0.loc == nome }
            zoomSpan = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        }
        
        guard !pontosParaZoom.isEmpty else {
            // Se não houver pontos, centraliza na localização do usuário ou no Rio
            withAnimation {
                if let userLocation = locationManager.location {
                    region = MKCoordinateRegion(
                        center: userLocation.coordinate,
                        span: zoomSpan
                    )
                } else {
                    region = MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: -22.908333, longitude: -43.196388),
                        span: zoomSpan
                    )
                }
            }
            return
        }
        
        var minLat = 90.0, maxLat = -90.0, minLon = 180.0, maxLon = -180.0
        
        for ponto in pontosParaZoom {
            if let lat = ponto.lat, let lon = ponto.lon {
                minLat = min(minLat, lat); maxLat = max(maxLat, lat)
                minLon = min(minLon, lon); maxLon = max(maxLon, lon)
            }
        }
        
        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2)
        let span = MKCoordinateSpan(latitudeDelta: (maxLat - minLat) * 1.5, longitudeDelta: (maxLon - minLon) * 1.5)
        
        withAnimation {
            region = MKCoordinateRegion(center: center, span: span.latitudeDelta > 0 ? span : zoomSpan)
        }
    }
}

// MARK: - View do Ponto no Mapa (com animação)
struct PontoMapaView: View {
    let ponto: PontoDeApoio
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isAnimating = false
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Marcador principal
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: isSelected ? 50 : 40, height: isSelected ? 50 : 40)
                        .shadow(color: .blue.opacity(0.3), radius: isSelected ? 8 : 3)
                
                    Image(systemName: "house.circle.fill")
                        .font(.system(size: isSelected ? 35 : 28))
                        .foregroundColor(.blue)
                }
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
            }
        }
        .onAppear {
            if isSelected {
                isAnimating = true
            }
        }
        .onChange(of: isSelected) { newValue in
            isAnimating = newValue
        }
    }
}

// MARK: - View de Detalhes Completos (Modal)
struct PontoApoioPreviewView: View {
    let ponto: PontoDeApoio
    let userLocation: CLLocation?
    let onClose: () -> Void
    
    @State private var dragOffset: CGFloat = 0
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var distancia: String {
        guard let userLocation = userLocation,
              let pontoCoordinate = ponto.coordinate else { return localizationManager.string(for: "not_available") }
        
        let pontoLocation = CLLocation(latitude: pontoCoordinate.latitude, longitude: pontoCoordinate.longitude)
        let distance = userLocation.distance(from: pontoLocation)
        
        if distance < 1000 {
            return String(format: "%.0f m", distance)
        } else {
            return String(format: "%.1f km", distance / 1000)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.secondary)
                .frame(width: 40, height: 5)
                .padding(.vertical, 8)
         
            Text(ponto.nome ?? localizationManager.string(for: "support_point"))
                .font(.title2.bold())
                .padding(.bottom)
            
            // Informações
            VStack(alignment: .leading, spacing: 16) {
                Divider()
                InfoRow(
                    label: localizationManager.string(for: "address"),
                    value: ponto.endereco ?? localizationManager.string(for: "not_available")
                )
                Divider()
                InfoRow(
                    label: localizationManager.string(for: "community"),
                    value: ponto.loc ?? localizationManager.string(for: "not_available")
                )
                Divider()
                InfoRow(
                    label: localizationManager.string(for: "distance"),
                    value: distancia
                )
                Divider()
                
                // Ações
                HStack(spacing: 12) {
                    Button(action: {
                        if let coordinate = ponto.coordinate {
                            let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
                            mapItem.name = ponto.nome
                            mapItem.openInMaps(launchOptions: [
                                MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
                            ])
                        }
                    }) {
                        Label(localizationManager.string(for: "get_directions"), systemImage: "location.fill")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    Button(action: onClose) {
                        Text(localizationManager.string(for: "close"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.primary)
                            .cornerRadius(10)
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 8)
            }
            .padding(.horizontal)
            .padding(.top)
        }
        .background(
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
        )
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.15), radius: 20, y: -5)
        )
        .offset(y: dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if value.translation.height > 0 {
                        dragOffset = value.translation.height
                    }
                }
                .onEnded { value in
                    if value.translation.height > 50 {
                        onClose()
                    } else {
                        withAnimation(.spring()) {
                            dragOffset = 0
                        }
                    }
                }
        )
    }
}

// MARK: - Componente InfoRow Simples
struct InfoRow: View {
    let label: String
    let value: String
    var color: Color? = nil
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(color ?? .primary)
        }
    }
}

// MARK: - Extensões
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}

// MARK: - LocationManager
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    // CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.last
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            startUpdatingLocation()
        case .denied, .restricted:
            print("Acesso à localização negado")
        case .notDetermined:
            requestLocationPermission()
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Erro de localização: \(error.localizedDescription)")
    }
}

