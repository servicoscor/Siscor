import SwiftUI
import MapKit
import CoreLocation
import Combine

//====================================================================//
// MARK: - Modelos e Estruturas de Dados
//====================================================================//

struct Camera: Identifiable, Hashable {
    let id = UUID()
    var nome: String?; var lat: Double?; var lon: Double?
    var coordinate: CLLocationCoordinate2D? {
        guard let lat, let lon else { return nil }; return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: Camera, rhs: Camera) -> Bool { lhs.id == rhs.id }
}
enum CameraAnnotationType { case single, cluster }
struct CameraAnnotationItem: Identifiable {
    let id = UUID(); let coordinate: CLLocationCoordinate2D; let type: CameraAnnotationType; let camera: Camera?; let clusterCount: Int
}

//====================================================================//
// MARK: - Gerenciador de Clustering
//====================================================================//

class CameraClusterManager {
    private func gridSize(for zoomLevel: Double) -> Double {
        if zoomLevel < 8 { return 60000 }; if zoomLevel < 10 { return 30000 }; if zoomLevel < 12 { return 15000 }
        if zoomLevel < 14 { return 7000 }; return 3000
    }
    func createClusters(from cameras: [Camera], for region: MKCoordinateRegion) -> [CameraAnnotationItem] {
        let zoomLevel = log2(360 / region.span.longitudeDelta)
        guard zoomLevel < 14.5 else {
            return cameras.compactMap { .init(coordinate: $0.coordinate!, type: .single, camera: $0, clusterCount: 1) }
        }
        struct GridKey: Hashable { let x: Int; let y: Int }
        var grid = [GridKey: [Camera]]()
        let mapRect = region.toMapRect()
        let gridSize = self.gridSize(for: zoomLevel)
        for camera in cameras {
            guard let coordinate = camera.coordinate else { continue }
            let mapPoint = MKMapPoint(coordinate)
            let key = GridKey(x: Int(floor((mapPoint.x - mapRect.minX) / gridSize)), y: Int(floor((mapPoint.y - mapRect.minY) / gridSize)))
            grid[key, default: []].append(camera)
        }
        return grid.values.compactMap { cluster in
            guard let firstCam = cluster.first, let coord = firstCam.coordinate else { return nil }
            if cluster.count == 1 { return .init(coordinate: coord, type: .single, camera: firstCam, clusterCount: 1) }
            else { return .init(coordinate: calculateClusterCenter(for: cluster), type: .cluster, camera: firstCam, clusterCount: cluster.count) }
        }
    }
    private func calculateClusterCenter(for cameras: [Camera]) -> CLLocationCoordinate2D {
        let c = cameras.compactMap { $0.coordinate }; guard !c.isEmpty else { return CLLocationCoordinate2D() }
        return CLLocationCoordinate2D(latitude: c.reduce(0, {$0+$1.latitude})/Double(c.count), longitude: c.reduce(0, {$0+$1.longitude})/Double(c.count))
    }
}

private extension MKCoordinateRegion {
    func toMapRect() -> MKMapRect {
        let a=MKMapPoint(CLLocationCoordinate2D(latitude:center.latitude+span.latitudeDelta/2,longitude:center.longitude-span.longitudeDelta/2)); let b=MKMapPoint(CLLocationCoordinate2D(latitude:center.latitude-span.latitudeDelta/2,longitude:center.longitude+span.longitudeDelta/2)); return MKMapRect(x:min(a.x,b.x),y:min(a.y,b.y),width:abs(a.x-b.x),height:abs(a.y-b.y))
    }
}

//====================================================================//
// MARK: - ViewModel das Câmeras
//====================================================================//
class CamerasMapViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var mapAnnotations: [CameraAnnotationItem] = []
    @Published var region: MKCoordinateRegion { didSet { updateAnnotationsWithDebounce() } }
    
    private var updateDebouncer: Timer?; private let allCameras: [Camera]; private let clusterManager = CameraClusterManager()
    
    init(cameras: [Camera]) {
        self.allCameras = cameras; self.region = MKCoordinateRegion.fittingAll(coordinates: cameras.compactMap { $0.coordinate })
    }
    
    func updateAnnotations() {
        let filtered = allCameras.filter { ($0.nome ?? "").localizedCaseInsensitiveContains(searchText) || searchText.isEmpty }
        self.mapAnnotations = clusterManager.createClusters(from: filtered, for: region)
    }
    
    private func updateAnnotationsWithDebounce() {
        updateDebouncer?.invalidate()
        updateDebouncer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false) { [weak self] _ in self?.updateAnnotations() }
    }
    
    func zoomIntoCluster(item: CameraAnnotationItem) { withAnimation(.easeOut) { region.span = MKCoordinateSpan(latitudeDelta:max(region.span.latitudeDelta/3,0.005),longitudeDelta:max(region.span.longitudeDelta/3,0.005)); region.center = item.coordinate } }
}

//====================================================================//
// MARK: - View do Card de Câmeras
//====================================================================//
struct CamerasMapView: View {
    @StateObject private var viewModel: CamerasMapViewModel
    @State private var isMapExpanded: Bool = false
    
    init(cameras: [Camera]) {
        _viewModel = StateObject(wrappedValue: CamerasMapViewModel(cameras: cameras))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) { Image(systemName: "camera.fill").foregroundColor(.white); Text("Câmeras").font(.system(size: 20, weight: .bold)).foregroundColor(.white); Spacer(); Button(action:{isMapExpanded=true}){Image(systemName:"arrow.up.left.and.arrow.down.right").font(.system(size:16,weight:.semibold)).foregroundColor(.white)} }.padding([.top, .horizontal])
            HStack { Image(systemName: "magnifyingglass").foregroundColor(.gray); TextField("Buscar câmera...", text: $viewModel.searchText); if !viewModel.searchText.isEmpty { Button(action:{viewModel.searchText=""}){Image(systemName:"xmark.circle.fill").foregroundColor(.gray)}}}.padding(10).background(Color(.systemGray6)).cornerRadius(10).padding(.horizontal)
            
            Map(coordinateRegion: $viewModel.region, annotationItems: viewModel.mapAnnotations) { item in
                MapAnnotation(coordinate: item.coordinate) {
                    CameraMapAnnotationView(item: item).onTapGesture {
                        if item.type == .cluster { viewModel.zoomIntoCluster(item: item) }
                        else { print("Abrir stream para: \(item.camera?.nome ?? "")") }
                    }
                }
            }
            .frame(height: 450).cornerRadius(12).padding([.horizontal, .bottom])
        }
        .background(LinearGradient(colors: [.blue, .purple.opacity(0.8)], startPoint: .top, endPoint: .bottom)).cornerRadius(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.2), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.8), radius: 4, x: 0, y: 1).padding(.horizontal, 16)
        .fullScreenCover(isPresented: $isMapExpanded) { FullScreenCamerasMapView(viewModel: viewModel) }
        .onAppear { viewModel.updateAnnotations() } // Carga inicial
        .onChange(of: viewModel.searchText) { _ in viewModel.updateAnnotations() }
    }
}

//====================================================================//
// MARK: - View de Tela Cheia e Componentes
//====================================================================//
struct FullScreenCamerasMapView: View {
    @ObservedObject var viewModel: CamerasMapViewModel; @Environment(\.dismiss) private var dismiss
    var body: some View { /* ... código da tela cheia ... */ }
}
struct CameraMapAnnotationView: View {
    let item: CameraAnnotationItem
    var body: some View { /* ... código da anotação ... */ }
}

//====================================================================//
// MARK: - Preview com Dados de Teste
//====================================================================//
struct CamerasMapView_Previews: PreviewProvider {
    static let sampleCameras: [Camera] = [
        Camera(nome: "Copacabana", lat: -22.9698, lon: -43.185),
        Camera(nome: "Ipanema", lat: -22.9845, lon: -43.205),
        Camera(nome: "Maracanã", lat: -22.9122, lon: -43.230),
        Camera(nome: "Centro", lat: -22.9035, lon: -43.181),
        Camera(nome: "Barra da Tijuca", lat: -22.9995, lon: -43.365),
        // Adicionando mais câmeras próximas para testar o cluster
        Camera(nome: "Leme", lat: -22.963, lon: -43.169),
        Camera(nome: "Botafogo", lat: -22.9519, lon: -43.182),
        Camera(nome: "Urca", lat: -22.955, lon: -43.165)
    ]
    
    static var previews: some View {
        ScrollView { // Colocamos em uma ScrollView para simular uma tela real
            CamerasMapView(cameras: sampleCameras)
        }
        .background(Color.gray.opacity(0.2))
    }
}


// Extensão auxiliar para centralizar o mapa
extension MKCoordinateRegion {
    static func fittingAll(coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        var minLat:CLLocationDegrees=90,maxLat:CLLocationDegrees = -90,minLon:CLLocationDegrees=180,maxLon:CLLocationDegrees = -180
        for coordinate in coordinates { minLat=min(minLat,coordinate.latitude);maxLat=max(maxLat,coordinate.latitude);minLon=min(minLon,coordinate.longitude);maxLon=max(maxLon,coordinate.longitude)}
        let center = CLLocationCoordinate2D(latitude:(minLat+maxLat)/2,longitude:(minLon+maxLon)/2)
        let span = MKCoordinateSpan(latitudeDelta:(maxLat-minLat)*1.5,longitudeDelta:(maxLon-minLon)*1.5)
        return MKCoordinateRegion(center:center,span:MKCoordinateSpan(latitudeDelta:max(span.latitudeDelta,0.02),longitudeDelta:max(span.longitudeDelta,0.02)))
    }
}
