import SwiftUI
import MapKit
import CoreLocation

// MARK: - Enum para Status das Sirenes
enum SireneStatus: String, CaseIterable {
    case todas = "todas"
    case mobilizada = "mobilizada"
    case desmobilizada = "desmobilizada"
    
    func displayName(localizationManager: LocalizationManager) -> String {
        switch self {
        case .todas: return localizationManager.string(for: "siren_status_all")
        case .mobilizada: return localizationManager.string(for: "siren_status_mobilized")
        case .desmobilizada: return localizationManager.string(for: "siren_status_demobilized")
        }
    }
    
    var color: Color {
        switch self {
        case .todas: return .blue
        case .mobilizada: return .red
        case .desmobilizada: return .green
        }
    }
    
    var icon: String {
        switch self {
        case .todas: return "list.bullet"
        case .mobilizada: return "bell.fill"
        case .desmobilizada: return "bell.slash.fill"
        }
    }
}

// MARK: - View do Mapa de Sirenes (Versão Evoluída)
struct FullScreenAlarmeView: View {
    let sirenes: [Sirene]
    @Environment(\.dismiss) private var dismiss
    @StateObject private var localizationManager = LocalizationManager.shared

    // Estados da View
    @State private var region: MKCoordinateRegion
    @StateObject private var locationManager = LocationManager()
    @State private var hasInitializedToUserLocation = false
    
    // Estados dos Filtros
    @State private var filtroStatus: SireneStatus = .todas
    @State private var comunidadeSelecionada: String = ""
    @State private var comunidades: [String] = []
    
    // Estados para Detalhes
    @State private var sireneSelecionada: Sirene? = nil
    @State private var detalhesAbertos: Bool = false

    // Inicializador
    init(sirenes: [Sirene]) {
        self.sirenes = sirenes
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: -22.908333, longitude: -43.196388),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        ))
    }

    // Filtra por Status e Comunidade
    private var filteredSirenes: [Sirene] {
        var sirenesVisiveis = sirenes

        // Filtro por status de mobilização
        if filtroStatus != .todas {
            sirenesVisiveis = sirenesVisiveis.filter { sirene in
                guard let status = sirene.status?.lowercased() else {
                    return filtroStatus == .desmobilizada // Se não tem status, considera desmobilizada
                }
                
                let isMobilizada = status.contains("acionada") ||
                                 status.contains("ativa") ||
                                 status.contains("ligada") ||
                                 status.contains("mobilizada")
                
                switch filtroStatus {
                case .mobilizada:
                    return isMobilizada
                case .desmobilizada:
                    return !isMobilizada
                case .todas:
                    return true
                }
            }
        }
        
        // Filtro por comunidade
        if comunidadeSelecionada != localizationManager.string(for: "all_communities") {
            sirenesVisiveis = sirenesVisiveis.filter { $0.loc == comunidadeSelecionada }
        }
        
        return sirenesVisiveis
    }
    
    // Contador de sirenes por status
    private var contadorSirenes: (mobilizadas: Int, desmobilizadas: Int, total: Int) {
        let mobilizadas = sirenes.filter { sirene in
            guard let status = sirene.status?.lowercased() else { return false }
            return status.contains("acionada") || status.contains("ativa") || status.contains("ligada") || status.contains("mobilizada")
        }.count
        
        return (
            mobilizadas: mobilizadas,
            desmobilizadas: sirenes.count - mobilizadas,
            total: sirenes.count
        )
    }
    
    var body: some View {
        Group {
            if locationManager.location != nil || hasInitializedToUserLocation {
                mapView
            } else {
                loadingView
            }
        }
        .onAppear(perform: setupView)
        .onChange(of: comunidadeSelecionada, perform: zoomParaComunidade)
        .onChange(of: locationManager.location) { newLocation in
            // Centraliza no usuário apenas na primeira vez com zoom mais próximo
            if let location = newLocation, !hasInitializedToUserLocation {
                centerOnUserLocationInitial(location: location)
                hasInitializedToUserLocation = true
            }
        }
        
    }
    
    private var mapView: some View {
        ZStack {
            Map(coordinateRegion: $region,
                showsUserLocation: true,
                annotationItems: filteredSirenes) { sirene in
                MapAnnotation(coordinate: sirene.coordinate ?? CLLocationCoordinate2D()) {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            sireneSelecionada = sirene
                            detalhesAbertos = true
                            
                            // Centraliza na sirene selecionada
                            if let coordinate = sirene.coordinate {
                                region.center = coordinate
                            }
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 40, height: 40)
                                .shadow(radius: 3)
                            
                            Image(systemName: "bell.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(getStatusColor(for: sirene.status))
                        }
                        .scaleEffect(sireneSelecionada?.id == sirene.id ? 1.2 : (filtroStatus != .todas ? 1.1 : 1.0))
                        .animation(.easeInOut(duration: 0.2), value: filtroStatus)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: sireneSelecionada?.id == sirene.id)
                    }
                    .accessibilityLabel(localizationManager.string(for: "siren"))
                }
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 12) {
                    // Header com título e botão fechar
                    HStack {
                        Text(localizationManager.string(for: "alarm_system"))
                            .font(.title3.bold())
                            .foregroundColor(.primary)
                            .accessibilityAddTraits(.isHeader)
                        Spacer()
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.body.weight(.bold))
                                .foregroundColor(.white.opacity(0.8))
                                .padding(8)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                        .accessibilityLabel(localizationManager.string(for: "close"))
                    }
                    
                    // Picker de Status com design moderno centralizado
                    HStack(spacing: 0) {
                        ForEach(SireneStatus.allCases, id: \.self) { status in
                            Button(action: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    filtroStatus = status
                                }
                            }) {
                                VStack(spacing: 8) {
                                    // Ícone em círculo
                                    ZStack {
                                        Circle()
                                            .fill(filtroStatus == status ? status.color : Color.white)
                                            .frame(width: 48, height: 48)
                                            .shadow(
                                                color: filtroStatus == status ? status.color.opacity(0.3) : Color.black.opacity(0.08),
                                                radius: filtroStatus == status ? 8 : 3,
                                                x: 0,
                                                y: filtroStatus == status ? 4 : 2
                                            )
                                        
                                        Image(systemName: status.icon)
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundColor(filtroStatus == status ? .white : status.color)
                                    }
                                    
                                    // Texto
                                    Text(status.displayName(localizationManager: localizationManager))
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(filtroStatus == status ? status.color : .primary)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                    
                                    // Badge com contador
                                    Text(getCountText(for: status))
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(minWidth: 24)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(
                                            Capsule()
                                                .fill(filtroStatus == status ? status.color : Color.gray.opacity(0.8))
                                        )
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(filtroStatus == status ? status.color.opacity(0.08) : Color.clear)
                                        .stroke(
                                            filtroStatus == status ? status.color.opacity(0.2) : Color.clear,
                                            lineWidth: 1.5
                                        )
                                )
                            }
                            .scaleEffect(filtroStatus == status ? 1.03 : 1.0)
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: filtroStatus)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                    )
                    
                    // Filtro por comunidade
                    HStack {
                        Text(localizationManager.string(for: "filter_by_community"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Picker(localizationManager.string(for: "community"), selection: $comunidadeSelecionada) {
                            ForEach(comunidades, id: \.self) { comunidade in
                                Text(comunidade).tag(comunidade)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.primary)
                    }
                    
                    // Resumo de sirenes filtradas
                    if filtroStatus != .todas {
                        HStack {
                            Image(systemName: filtroStatus.icon)
                                .foregroundColor(filtroStatus.color)
                            Text("\(filteredSirenes.count) sirenes \(filtroStatus.displayName(localizationManager: localizationManager).lowercased())")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal, 4)
                    }
                }
                .padding()
                .background(.regularMaterial)
                
                Spacer()
                
                // Botão de localização flutuante
                HStack {
                    Spacer()
                    Button(action: centerOnUserLocation) {
                        Image(systemName: "location.fill")
                            .font(.title2)
                            .padding()
                            .background(.thinMaterial)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .accessibilityLabel(localizationManager.string(for: "center_on_my_location"))
                    .padding(.trailing)
                    .padding(.bottom, sireneSelecionada != nil && detalhesAbertos ? 20 : 16)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: detalhesAbertos)
                }
                
                // Preview de detalhes - IGUAL ao PontosApoioView
                if let sirene = sireneSelecionada, detalhesAbertos {
                    SireneDetalhesView(
                        sirene: sirene,
                        userLocation: locationManager.location,
                        onClose: {
                            withAnimation {
                                sireneSelecionada = nil
                                detalhesAbertos = false
                            }
                        }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.blue)
            
            Text(localizationManager.string(for: "getting_location"))
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Aguardando localização do GPS...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial)
    }
    
    // MARK: - Funções Auxiliares
    
    private func centerOnUserLocationInitial(location: CLLocation) {
        withAnimation(.easeInOut(duration: 1.0)) {
            region = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015) // Zoom mais próximo
            )
        }
    }
    
    private func centerOnUserLocation() {
        if let userLocation = locationManager.location?.coordinate {
            withAnimation(.easeInOut(duration: 0.8)) {
                region.center = userLocation
                region.span = MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
            }
        }
    }
    
    private func getStatusColor(for status: String?) -> Color {
        guard let status = status?.lowercased() else { return .green }
        
        if status.contains("acionada") || status.contains("ativa") || status.contains("ligada") || status.contains("mobilizada") {
            return .red
        } else if status.contains("teste") {
            return .orange
        } else {
            return .green
        }
    }
    
    private func getCountText(for status: SireneStatus) -> String {
        switch status {
        case .todas:
            return "\(contadorSirenes.total)"
        case .mobilizada:
            return "\(contadorSirenes.mobilizadas)"
        case .desmobilizada:
            return "\(contadorSirenes.desmobilizadas)"
        }
    }
    
    private func setupView() {
        let todasComunidades = Set(sirenes.compactMap { $0.loc })
        self.comunidades = [localizationManager.string(for: "all_communities")] + todasComunidades.sorted()
        self.comunidadeSelecionada = localizationManager.string(for: "all_communities")
        
        // Se já tem localização ao aparecer, centraliza
        if let location = locationManager.location, !hasInitializedToUserLocation {
            centerOnUserLocationInitial(location: location)
            hasInitializedToUserLocation = true
        }
    }
    
    private func zoomParaComunidade(nome: String) {
        let sirenesParaZoom: [Sirene]
        var zoomSpan = MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)

        if nome == localizationManager.string(for: "all_communities") {
            sirenesParaZoom = self.sirenes
        } else {
            sirenesParaZoom = self.sirenes.filter { $0.loc == nome }
            zoomSpan = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02) // Zoom mais próximo para comunidade específica
        }
        
        guard !sirenesParaZoom.isEmpty else {
            withAnimation {
                region = MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: -22.908333, longitude: -43.196388),
                    span: zoomSpan
                )
            }
            return
        }
        
        var minLat = 90.0, maxLat = -90.0, minLon = 180.0, maxLon = -180.0
        
        for sirene in sirenesParaZoom {
            if let lat = sirene.lat, let lon = sirene.lon {
                minLat = min(minLat, lat); maxLat = max(maxLat, lat)
                minLon = min(minLon, lon); maxLon = max(maxLon, lon)
            }
        }
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.3, 0.01),
            longitudeDelta: max((maxLon - minLon) * 1.3, 0.01)
        )
        
        withAnimation(.easeInOut(duration: 0.8)) {
            region = MKCoordinateRegion(center: center, span: span)
        }
    }
}

// MARK: - SireneDetalhesView (Corrigido para ficar igual ao PontoApoioPreviewView)
struct SireneDetalhesView: View {
    let sirene: Sirene
    let userLocation: CLLocation?
    let onClose: () -> Void
    
    @State private var dragOffset: CGFloat = 0
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var status: (displayName: String, color: Color) {
        guard let statusText = sirene.status?.lowercased() else {
            return (localizationManager.string(for: "status_unknown"), .gray)
        }
        
        if statusText.contains("acionada") || statusText.contains("ativa") || statusText.contains("ligada") {
            return (localizationManager.string(for: "status_active"), .red)
        } else if statusText.contains("teste") {
            return (localizationManager.string(for: "status_test"), .orange)
        } else {
            return (localizationManager.string(for: "status_normal"), .green)
        }
    }
    
    var distancia: String {
        guard let userLocation = userLocation,
              let sireneCoordinate = sirene.coordinate else {
            return localizationManager.string(for: "not_available")
        }
        
        let sireneLocation = CLLocation(latitude: sireneCoordinate.latitude, longitude: sireneCoordinate.longitude)
        let distance = userLocation.distance(from: sireneLocation)
        
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
         
            Text(sirene.nome ?? localizationManager.string(for: "siren"))
                .font(.title2.bold())
                .padding(.bottom)
            
            // Informações
            VStack(alignment: .leading, spacing: 16) {
                Divider()
                InfoRow(
                    label: localizationManager.string(for: "status"),
                    value: status.displayName,
                    color: status.color
                )
                Divider()
                InfoRow(
                    label: localizationManager.string(for: "community"),
                    value: sirene.loc ?? localizationManager.string(for: "not_available")
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
                        if let url = URL(string: "https://alertario.rio.rj.gov.br") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Label(localizationManager.string(for: "more_info"), systemImage: "info.circle.fill")
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
