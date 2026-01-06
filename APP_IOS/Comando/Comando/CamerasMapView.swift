import SwiftUI
import MapKit
import CoreLocation
import Combine
import WebKit

// MARK: - Extensões

extension MKCoordinateRegion: Equatable {
    public static func == (lhs: MKCoordinateRegion, rhs: MKCoordinateRegion) -> Bool {
        lhs.center.latitude == rhs.center.latitude &&
        lhs.center.longitude == rhs.center.longitude &&
        lhs.span.latitudeDelta == rhs.span.latitudeDelta &&
        lhs.span.longitudeDelta == rhs.span.longitudeDelta
    }
}

// MARK: - Modelos de Dados

enum MapItemType {
    case single(Camera)
    case cluster([Camera])
}

struct MapItem: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let type: MapItemType
    
    var camerasCount: Int {
        switch type {
        case .single:
            return 1
        case .cluster(let cameras):
            return cameras.count
        }
    }
    
    var camera: Camera? {
        switch type {
        case .single(let camera):
            return camera
        case .cluster:
            return nil
        }
    }
}

// MARK: - Serviço de Busca de Endereços

class AddressSearchService: ObservableObject {
    private let searchCompleter = MKLocalSearchCompleter()
    @Published var searchResults: [MKLocalSearchCompletion] = []
    @Published var isSearching = false
    
    func searchAddress(_ query: String) async -> MKMapItem? {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = query
        
        let search = MKLocalSearch(request: searchRequest)
        
        do {
            let response = try await search.start()
            return response.mapItems.first
        } catch {
            print("Erro na busca: \(error)")
            return nil
        }
    }
}

// MARK: - Serviço de Clustering

class ClusteringService {
    private let baseClusterDistance: Double = 50.0
    private let noClusteringZoomThreshold: Double = 0.005
    private let maxClusteringZoomThreshold: Double = 0.5
    
    func clusterCameras(_ cameras: [Camera], forRegion region: MKCoordinateRegion) -> [MapItem] {
        let validCameras = cameras.compactMap { camera -> (Camera, CLLocationCoordinate2D)? in
            guard let coordinate = camera.coordinate else { return nil }
            return (camera, coordinate)
        }
        
        if validCameras.count <= 5 {
            return validCameras.map { MapItem(coordinate: $0.1, type: .single($0.0)) }
        }
        
        let zoomLevel = min(region.span.latitudeDelta, region.span.longitudeDelta)
        
        if zoomLevel < noClusteringZoomThreshold {
            return validCameras.map { MapItem(coordinate: $0.1, type: .single($0.0)) }
        }
        
        var clusters: [String: [(Camera, CLLocationCoordinate2D)]] = [:]
        
        let cellSize = calculateCellSize(forRegion: region)
        
        for (camera, coordinate) in validCameras {
            let cellX = Int(coordinate.latitude / cellSize.lat)
            let cellY = Int(coordinate.longitude / cellSize.lon)
            let cellKey = "\(cellX):\(cellY)"
            
            if clusters[cellKey] == nil {
                clusters[cellKey] = [(camera, coordinate)]
            } else {
                clusters[cellKey]?.append((camera, coordinate))
            }
        }
        
        var mapItems: [MapItem] = []
        
        for (_, camerasInCell) in clusters {
            if camerasInCell.count == 1 {
                let (camera, coordinate) = camerasInCell[0]
                mapItems.append(MapItem(coordinate: coordinate, type: .single(camera)))
            } else {
                let cameras = camerasInCell.map { $0.0 }
                let centerCoordinate = calculateCenterCoordinate(for: camerasInCell)
                mapItems.append(MapItem(coordinate: centerCoordinate, type: .cluster(cameras)))
            }
        }
        
        return mapItems
    }
    
    private func calculateCellSize(forRegion region: MKCoordinateRegion) -> (lat: Double, lon: Double) {
        let zoomLevel = min(region.span.latitudeDelta, region.span.longitudeDelta)
        
        let normalizedZoom = min(max(zoomLevel, noClusteringZoomThreshold), maxClusteringZoomThreshold)
        
        let scaleFactor = log10(normalizedZoom * 100 + 1) / 2.0
        let adjustedDistance = baseClusterDistance * (1 + scaleFactor * 10)
        
        let latDegrees = adjustedDistance / 111000.0
        let lonDegrees = adjustedDistance / (111000.0 * cos(region.center.latitude * .pi / 180.0))
        
        return (lat: latDegrees, lon: lonDegrees)
    }
    
    private func calculateCenterCoordinate(for cameras: [(Camera, CLLocationCoordinate2D)]) -> CLLocationCoordinate2D {
        let sumLat = cameras.reduce(0.0) { $0 + $1.1.latitude }
        let sumLon = cameras.reduce(0.0) { $0 + $1.1.longitude }
        return CLLocationCoordinate2D(
            latitude: sumLat / Double(cameras.count),
            longitude: sumLon / Double(cameras.count)
        )
    }
}

// MARK: - Componentes de Anotação

struct CameraAnnotationView: View {
    @State private var isPressed = false
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 36, height: 36)
                .shadow(radius: 2)
            
            Image(systemName: "video.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.blue)
        }
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
                }
            }
        }
    }
}

struct ClusterAnnotationView: View {
    let count: Int
    @State private var isPressed = false
    
    private var clusterSize: CGFloat {
        if count < 10 {
            return 44
        } else if count < 50 {
            return 52
        } else {
            return 60
        }
    }
    
    private var fontSize: CGFloat {
        if count < 10 {
            return 16
        } else if count < 50 {
            return 18
        } else {
            return 20
        }
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.9))
                .frame(width: clusterSize, height: clusterSize)
                .shadow(radius: 3)
            
            Circle()
                .stroke(Color.white, lineWidth: 2)
                .frame(width: clusterSize, height: clusterSize)
            
            Text("\(count)")
                .font(.system(size: fontSize, weight: .bold))
                .foregroundColor(.white)
        }
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
                }
            }
        }
    }
}

// MARK: - Vista Principal de Câmeras

struct CamerasMapView: View {
    let cameras: [Camera]
    
    @StateObject private var locationManager = LocationManager()
    @StateObject private var addressSearchService = AddressSearchService()
    @StateObject private var orientationManager = OrientationManager.shared
    @EnvironmentObject private var localizationManager: LocalizationManager
    @EnvironmentObject private var favoritesManager: FavoritesManager
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -22.9068, longitude: -43.1729),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var userTrackingMode: MapUserTrackingMode = .none
    @State private var isMapExpanded = false
    @State private var selectedCamera: Camera?
    @State private var showCameraDetail = false
    @State private var searchText = ""
    @State private var hasInitializedLocation = false
    @State private var isSearchingAddress = false
    @State private var cachedMapItems: [MapItem] = []
    @State private var updateTimer: Timer?
    @State private var showFavorites = false
    
    // Controle da busca via lupa
    @State private var isSearchVisible: Bool = false
    
    // Favoritos por slot (2 visualizadores)
    @State private var favoriteSlot1Id: UUID?
    @State private var favoriteSlot2Id: UUID?
    @State private var showSlotPicker: Bool = false
    @State private var slotToConfigure: Int = 1
    
    private let clusteringService = ClusteringService()
    
    var body: some View {
        cardContent
    }
    
    private var cardContent: some View {
        mainCardView
            .fullScreenCover(isPresented: $isMapExpanded) {
                FullScreenCamerasMapView(cameras: cameras)
                    .environmentObject(favoritesManager)
                    .environmentObject(localizationManager)
            }
            .fullScreenCover(item: $selectedCamera) { camera in
                CameraDetailView(camera: camera)
                    .environmentObject(favoritesManager)
                    .environmentObject(localizationManager)
            }
            // Seletor de câmera por slot
            .sheet(isPresented: $showSlotPicker) {
                CameraSlotPickerView(
                    allCameras: cameras,
                    onPick: { picked in
                        if slotToConfigure == 1 {
                            favoriteSlot1Id = picked.id
                            saveFavoriteSlots()
                        } else {
                            favoriteSlot2Id = picked.id
                            saveFavoriteSlots()
                        }
                    }
                )
                .environmentObject(localizationManager)
            }
            // Lista de favoritos (já existente)
            .sheet(isPresented: $showFavorites) {
                FavoriteCamerasView(allCameras: cameras)
                    .environmentObject(favoritesManager)
                    .environmentObject(localizationManager)
            }
            .onAppear {
                orientationManager.lockToPortrait()
                locationManager.requestLocationPermission()
                loadFavoriteSlots()
                updateClustering()
                favoritesManager.printDebugInfo()
            }
            .onChange(of: region) { _ in
                updateTimer?.invalidate()
                updateTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                    updateClustering()
                }
            }
            .onChange(of: locationManager.location) { newLocation in
                if !hasInitializedLocation, let location = newLocation {
                    withAnimation {
                        region = MKCoordinateRegion(
                            center: location.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                        )
                        userTrackingMode = .follow
                    }
                    hasInitializedLocation = true
                }
            }
    }
    
    private var mainCardView: some View {
        VStack(alignment: .leading, spacing: 8) { // reduzido de 10
            // TopBar
            HStack(spacing: 10) { // reduzido de 12
                Image(systemName: "camera.fill").font(.system(size: 22)).foregroundColor(.white) // 24 -> 22
                Text(localizationManager.string(for: "cameras")).font(.system(size: 22, weight: .bold)).foregroundColor(.white) // 24 -> 22
                Spacer()
                
                // Favoritos
                Button(action: { showFavorites = true }) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.system(size: 16)) // 18 -> 16
                }
                .accessibilityLabel(localizationManager.string(for: "view_favorites"))
                
                // Lupa
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isSearchVisible.toggle()
                    }
                }) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(isSearchVisible ? .blue : .white)
                        .font(.system(size: 16)) // 18 -> 16
                }
                .accessibilityLabel(localizationManager.string(for: "search"))
                
                // Expandir
                Button(action: { isMapExpanded = true }) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                }
                .accessibilityLabel(localizationManager.string(for: "expand_map"))
            }
            .padding(.top, 10) // top reduzido
            .padding(.horizontal, 12) // horizontal levemente menor
            
            // Campo de busca (aparece/ some com animação)
            if isSearchVisible {
                HStack {
                    Image(systemName: "location.magnifyingglass")
                        .foregroundColor(.gray)
                    TextField(localizationManager.string(for: "search_address"), text: $searchText)
                        .foregroundColor(.primary)
                        .onSubmit { searchAddressInline() }
                    
                    if isSearchingAddress {
                        ProgressView().scaleEffect(0.8)
                    } else if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                        .accessibilityLabel(localizationManager.string(for: "clear_search"))
                    }
                    
                    Button(action: { searchAddressInline() }) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white)
                            .padding(6) // 8 -> 6
                            .background(Color.blue)
                            .clipShape(Circle())
                    }
                    .accessibilityLabel(localizationManager.string(for: "search"))
                }
                .padding(8) // 10 -> 8
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal, 12)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // Dois visualizadores lado a lado (compactos 66–70pt)
            HStack(spacing: 8) { // 10 -> 8
                CameraPreviewCard(
                    camera: cameras.first(where: { $0.id == favoriteSlot1Id }),
                    placeholderText: localizationManager.string(for: "select_camera_slot_1"),
                    onOpen: { cam in selectedCamera = cam },
                    onConfigure: {
                        slotToConfigure = 1
                        showSlotPicker = true
                    }
                )
                .frame(height: 68) // 72 -> 68
                
                CameraPreviewCard(
                    camera: cameras.first(where: { $0.id == favoriteSlot2Id }),
                    placeholderText: localizationManager.string(for: "select_camera_slot_2"),
                    onOpen: { cam in selectedCamera = cam },
                    onConfigure: {
                        slotToConfigure = 2
                        showSlotPicker = true
                    }
                )
                .frame(height: 68) // 72 -> 68
            }
            .padding(.horizontal, 12)
            
            // Mapa reduzido (135–140pt)
            ZStack(alignment: .bottomTrailing) {
                Map(
                    coordinateRegion: $region,
                    showsUserLocation: true,
                    userTrackingMode: $userTrackingMode,
                    annotationItems: cachedMapItems
                ) { item in
                    MapAnnotation(coordinate: item.coordinate) {
                        Group {
                            switch item.type {
                            case .single(let camera):
                                CameraAnnotationView()
                                    .simultaneousGesture(TapGesture().onEnded {
                                        selectedCamera = camera
                                    })
                                    .accessibilityLabel(camera.nome ?? localizationManager.string(for: "camera"))
                                    .accessibilityHint(localizationManager.string(for: "tap_to_view_details"))
                            case .cluster(let cameras):
                                ClusterAnnotationView(count: cameras.count)
                                    .simultaneousGesture(TapGesture().onEnded {
                                        zoomIntoCluster(at: item.coordinate)
                                    })
                                    .accessibilityLabel(String(format: localizationManager.string(for: "cameras_cluster"), cameras.count))
                                    .accessibilityHint(localizationManager.string(for: "tap_to_zoom_in"))
                            }
                        }
                    }
                }
                
                LocationButton(userTrackingMode: $userTrackingMode) {
                    centerOnUserLocation()
                }
                .padding(8) // 12 -> 8
            }
            .frame(height: 138) // 180 -> 138
            .cornerRadius(12)
            .padding(.horizontal, 12)
            .padding(.bottom, 10) // reduzir padding inferior
            
        }
        .background(cardGradient)
        .cornerRadius(12)
        .overlay(cardBorder)
        .shadow(color: Color.black.opacity(0.8), radius: 4, x: 0, y: 1)
        .padding(.horizontal, 16)
        // Ao tocar fora do campo de busca, fecha-o
        .contentShape(Rectangle())
        .onTapGesture {
            if isSearchVisible {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isSearchVisible = false
                    isSearchingAddress = false
                }
            }
        }
    }

    private func searchAddressInline() {
        guard !searchText.isEmpty else { return }
        isSearchingAddress = true
        Task {
            if let mapItem = await addressSearchService.searchAddress(searchText) {
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        region = MKCoordinateRegion(
                            center: mapItem.placemark.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        )
                    }
                    isSearchingAddress = false
                }
            } else {
                await MainActor.run {
                    isSearchingAddress = false
                }
            }
        }
    }
    
    private func zoomIntoCluster(at coordinate: CLLocationCoordinate2D) {
        withAnimation(.easeInOut(duration: 0.5)) {
            region.center = coordinate
            region.span = MKCoordinateSpan(
                latitudeDelta: max(region.span.latitudeDelta * 0.5, 0.005),
                longitudeDelta: max(region.span.longitudeDelta * 0.5, 0.005)
            )
        }
    }
    
    private func centerOnUserLocation() {
        if let userLocation = locationManager.location?.coordinate {
            withAnimation(.easeInOut(duration: 0.5)) {
                region.center = userLocation
                region.span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                userTrackingMode = .follow
            }
        }
    }
    
    private func updateClustering() {
        let newItems = clusteringService.clusterCameras(cameras, forRegion: region)
        cachedMapItems = newItems
    }
    
    func selectCamera(_ camera: Camera?) {
        withAnimation {
            self.selectedCamera = camera
        }
    }
    
    // MARK: - Persistência dos slots favoritos
    private let slot1Key = "com.cocr.favoriteCamera.slot1"
    private let slot2Key = "com.cocr.favoriteCamera.slot2"
    
    private func loadFavoriteSlots() {
        let defaults = UserDefaults.standard
        if let s1 = defaults.string(forKey: slot1Key), let id1 = UUID(uuidString: s1) {
            favoriteSlot1Id = id1
        }
        if let s2 = defaults.string(forKey: slot2Key), let id2 = UUID(uuidString: s2) {
            favoriteSlot2Id = id2
        }
    }
    
    private func saveFavoriteSlots() {
        let defaults = UserDefaults.standard
        if let id1 = favoriteSlot1Id {
            defaults.set(id1.uuidString, forKey: slot1Key)
        }
        if let id2 = favoriteSlot2Id {
            defaults.set(id2.uuidString, forKey: slot2Key)
        }
        defaults.synchronize()
    }
}

// MARK: - Vista de Tela Cheia (sem mudanças de layout aqui)

struct FullScreenCamerasMapView: View {
    let cameras: [Camera]
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var favoritesManager: FavoritesManager
    @EnvironmentObject private var localizationManager: LocalizationManager
    
    @StateObject private var locationManager = LocationManager()
    @StateObject private var addressSearchService = AddressSearchService()
    @StateObject private var orientationManager = OrientationManager.shared
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -22.9068, longitude: -43.1729),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var userTrackingMode: MapUserTrackingMode = .none
    @State private var searchText = ""
    @State private var selectedCamera: Camera?
    @State private var hasInitializedLocation = false
    @State private var isSearchingAddress = false
    @State private var cachedMapItems: [MapItem] = []
    @State private var updateTimer: Timer?
    @State private var showFavorites = false
    
    private let clusteringService = ClusteringService()
    
    var body: some View {
        fullScreenContent
            .onAppear {
                orientationManager.unlockOrientation()
            }
            .onDisappear {
                orientationManager.lockToPortrait()
            }
    }
    
    private var fullScreenContent: some View {
        ZStack {
            Map(
                coordinateRegion: $region,
                showsUserLocation: true,
                userTrackingMode: $userTrackingMode,
                annotationItems: cachedMapItems
            ) { item in
                MapAnnotation(coordinate: item.coordinate) {
                    Group {
                        switch item.type {
                        case .single(let camera):
                            CameraAnnotationView()
                                .simultaneousGesture(
                                    TapGesture().onEnded { _ in
                                        selectedCamera = camera
                                    }
                                )
                                .accessibilityLabel(camera.nome ?? localizationManager.string(for: "camera"))
                                .accessibilityHint(localizationManager.string(for: "tap_to_view_details"))
                        case .cluster(let cameras):
                            ClusterAnnotationView(count: cameras.count)
                                .simultaneousGesture(
                                    TapGesture().onEnded { _ in
                                        zoomIntoCluster(at: item.coordinate)
                                    }
                                )
                                .accessibilityLabel(String(format: localizationManager.string(for: "cameras_cluster"), cameras.count))
                                .accessibilityHint(localizationManager.string(for: "tap_to_zoom_in"))
                        }
                    }
                }
            }
            .ignoresSafeArea()
            
            VStack {
                VStack(spacing: 12) {
                    HStack {
                        Text(localizationManager.string(for: "cameras"))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .accessibilityAddTraits(.isHeader)
                        Spacer()
                        
                        Button(action: { showFavorites = true }) {
                            Image(systemName: "star.fill")
                                .font(.body.weight(.bold))
                                .foregroundColor(.yellow)
                                .padding(8)
                                .clipShape(Circle())
                        }
                        .accessibilityLabel(localizationManager.string(for: "view_favorites"))
                        .padding(.trailing, 8)
                        
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.body.weight(.bold))
                                .foregroundColor(.white.opacity(0.8))
                                .padding(8)
                                .clipShape(Circle())
                        }
                        .accessibilityLabel(localizationManager.string(for: "close"))
                    }
                    
                    HStack {
                        Image(systemName: "location.magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField(localizationManager.string(for: "search_address"), text: $searchText)
                            .onSubmit {
                                searchAddress()
                            }
                        
                        if isSearchingAddress {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                            .accessibilityLabel(localizationManager.string(for: "clear_search"))
                        }
                        
                        Button(action: { searchAddress() }) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.blue)
                                .clipShape(Circle())
                        }
                        .accessibilityLabel(localizationManager.string(for: "search"))
                    }
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                .padding()
                .background(.thinMaterial)
                
                Spacer()
                
                HStack {
                    Spacer()
                    LocationButton(userTrackingMode: $userTrackingMode) {
                        centerOnUserLocation()
                    }
                    .padding()
                }
            }
        }
        .fullScreenCover(item: $selectedCamera) { camera in
            CameraDetailView(camera: camera)
                .environmentObject(favoritesManager)
                .environmentObject(localizationManager)
        }
        .sheet(isPresented: $showFavorites) {
            FavoriteCamerasView(allCameras: cameras)
                .environmentObject(favoritesManager)
                .environmentObject(localizationManager)
        }
        .onAppear {
            locationManager.requestLocationPermission()
            updateClustering()
        }
        .onChange(of: region) { _ in
            updateTimer?.invalidate()
            updateTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                updateClustering()
            }
        }
        .onChange(of: locationManager.location) { newLocation in
            if !hasInitializedLocation, let location = newLocation {
                withAnimation {
                    region = MKCoordinateRegion(
                        center: location.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                    )
                    userTrackingMode = .follow
                }
                hasInitializedLocation = true
            } else if !hasInitializedLocation {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    if !hasInitializedLocation {
                        fitMapToShowAllCameras()
                        hasInitializedLocation = true
                    }
                }
            }
        }
    }
    
    private func searchAddress() {
        guard !searchText.isEmpty else { return }
        
        isSearchingAddress = true
        
        Task {
            if let mapItem = await addressSearchService.searchAddress(searchText) {
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        region = MKCoordinateRegion(
                            center: mapItem.placemark.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        )
                    }
                    isSearchingAddress = false
                }
            } else {
                await MainActor.run {
                    isSearchingAddress = false
                }
            }
        }
    }
    
    private func zoomIntoCluster(at coordinate: CLLocationCoordinate2D) {
        withAnimation(.easeInOut(duration: 0.5)) {
            region.center = coordinate
            region.span = MKCoordinateSpan(
                latitudeDelta: max(region.span.latitudeDelta * 0.5, 0.005),
                longitudeDelta: max(region.span.longitudeDelta * 0.5, 0.005)
            )
        }
    }
    
    private func centerOnUserLocation() {
        if let userLocation = locationManager.location?.coordinate {
            withAnimation(.easeInOut(duration: 0.5)) {
                region.center = userLocation
                region.span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                userTrackingMode = .follow
            }
        }
    }
    
    private func fitMapToShowAllCameras() {
        let validCoordinates = cameras.compactMap { $0.coordinate }
        
        guard !validCoordinates.isEmpty else { return }
        
        var minLat = validCoordinates[0].latitude
        var maxLat = validCoordinates[0].latitude
        var minLon = validCoordinates[0].longitude
        var maxLon = validCoordinates[0].longitude
        
        for coordinate in validCoordinates {
            minLat = min(minLat, coordinate.latitude)
            maxLat = max(maxLat, coordinate.latitude)
            minLon = min(minLon, coordinate.longitude)
            maxLon = max(maxLon, coordinate.longitude)
        }
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.2, 0.05),
            longitudeDelta: max((maxLon - minLon) * 1.2, 0.05)
        )
        
        withAnimation {
            region = MKCoordinateRegion(center: center, span: span)
        }
    }
    
    private func updateClustering() {
        let newItems = clusteringService.clusterCameras(cameras, forRegion: region)
        cachedMapItems = newItems
    }
}

// MARK: - Componente de Botão de Localização

struct LocationButton: View {
    @Binding var userTrackingMode: MapUserTrackingMode
    let action: () -> Void
    @EnvironmentObject private var localizationManager: LocalizationManager
    
    var body: some View {
        Button(action: action) {
            Image(systemName: userTrackingMode == .follow ? "location.fill" : "location")
                .font(.title3) // title2 -> title3 para caber melhor
                .padding(10) // 12 -> 10
                .background(.thinMaterial)
                .clipShape(Circle())
                .shadow(radius: 4)
        }
        .accessibilityLabel(localizationManager.string(for: "center_on_my_location"))
    }
}

// MARK: - Estilos

private let cardGradient = LinearGradient(
    gradient: Gradient(colors: [
        Color(red: 0.1, green: 0.5, blue: 0.9),
        Color(red: 0.3, green: 0.6, blue: 0.9)
    ]),
    startPoint: .top,
    endPoint: .bottom
)

private var cardBorder: some View {
    RoundedRectangle(cornerRadius: 12)
        .stroke(Color.white.opacity(0.2), lineWidth: 1)
}

// MARK: - NOVOS COMPONENTES

struct CameraPreviewCard: View {
    let camera: Camera?
    let placeholderText: String
    let onOpen: (Camera) -> Void
    let onConfigure: () -> Void
    
    var body: some View {
        ZStack {
            if let cam = camera {
                Button {
                    onOpen(cam)
                } label: {
                    VStack(spacing: 4) { // 6 -> 4
                        Image(systemName: "video.fill")
                            .font(.system(size: 20)) // 22 -> 20
                            .foregroundColor(.white)
                        Text(cam.nome ?? "Câmera")
                            .font(.caption2.weight(.semibold)) // caption -> caption2
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(6) // 8 -> 6
                    .background(Color.white.opacity(0.12))
                    .cornerRadius(10)
                    .overlay(
                        HStack {
                            Spacer()
                            VStack {
                                Button(action: onConfigure) {
                                    Image(systemName: "gearshape.fill")
                                        .font(.system(size: 11, weight: .bold)) // 12 -> 11
                                        .foregroundColor(.white.opacity(0.9))
                                        .padding(4)
                                        .background(Color.black.opacity(0.3))
                                        .clipShape(Circle())
                                }
                                .padding(4) // 6 -> 4
                                Spacer()
                            }
                        }
                    )
                }
                .buttonStyle(.plain)
            } else {
                VStack(spacing: 4) { // 6 -> 4
                    Image(systemName: "video.slash.fill")
                        .font(.system(size: 20)) // 22 -> 20
                        .foregroundColor(.white.opacity(0.85))
                    Text(placeholderText)
                        .font(.caption2) // caption2
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.8)
                    Button(action: onConfigure) {
                        Label("Selecionar", systemImage: "gearshape.fill")
                            .font(.caption2.weight(.semibold))
                            .padding(.vertical, 3) // 4 -> 3
                            .padding(.horizontal, 8)
                            .background(Color.blue.opacity(0.85))
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(6) // 8 -> 6
                .background(Color.white.opacity(0.08))
                .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct CameraSlotPickerView: View {
    let allCameras: [Camera]
    let onPick: (Camera) -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var localizationManager: LocalizationManager
    
    @State private var search: String = ""
    
    var filtered: [Camera] {
        guard !search.isEmpty else { return allCameras }
        return allCameras.filter { $0.nome?.localizedCaseInsensitiveContains(search) ?? false }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filtered) { camera in
                    Button {
                        onPick(camera)
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "video.circle.fill")
                                .foregroundColor(.blue)
                            Text(camera.nome ?? localizationManager.string(for: "camera"))
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
            .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always))
            .navigationTitle(localizationManager.string(for: "select_camera"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(localizationManager.string(for: "cancel")) {
                        dismiss()
                    }
                }
            }
        }
    }
}
