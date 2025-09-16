import SwiftUI
import MapKit
import Combine

struct SistemaAlarmeMapView: View {
    let sirenes: [Sirene]
    let onExpand: () -> Void

    @StateObject private var locationManager = LocationManager()
    @StateObject private var localizationManager = LocalizationManager.shared
    
    @State private var region = MKCoordinateRegion()
    @State private var userTrackingMode: MapUserTrackingMode = .follow
    @State private var hasInitializedToUserLocation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Cabeçalho
            HStack {
                Image(systemName: "siren.fill").foregroundColor(.red)
                Text(localizationManager.string(for: "alarm_system"))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Button(action: onExpand) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .foregroundColor(.white)
                }
                .accessibilityLabel(localizationManager.string(for: "expand_map"))
            }
            .padding([.top, .horizontal])
            
            ZStack(alignment: .bottomTrailing) {
                Map(
                    coordinateRegion: $region,
                    showsUserLocation: true,
                    userTrackingMode: $userTrackingMode,
                    annotationItems: sirenes
                ) { sirene in
                    MapAnnotation(coordinate: sirene.coordinate ?? CLLocationCoordinate2D()) {
                        ZStack {
                            Circle().fill(Color.white).frame(width: 40, height: 40).shadow(radius: 3)
                            Image(systemName: "bell.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(getStatusColor(for: sirene.status))
                        }
                    }
                }
                
                // Botão de localização flutuante
                Button(action: {
                    if let userLocation = locationManager.location?.coordinate {
                        withAnimation {
                            region.center = userLocation
                            region.span = MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
                            userTrackingMode = .follow
                        }
                    }
                }) {
                    Image(systemName: userTrackingMode == .follow ? "location.fill" : "location")
                        .font(.title2)
                        .padding(12)
                        .background(.thinMaterial)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .accessibilityLabel(localizationManager.string(for: "center_on_my_location"))
                .padding()
            }
            .frame(height: 300)
            .cornerRadius(12)
            .padding([.horizontal, .bottom])
        }
        .background(cardGradient)
        .cornerRadius(12)
        .overlay(cardBorder)
        .shadow(color: Color.black.opacity(0.8), radius: 4, x: 0, y: 1)
        .padding(.horizontal, 16)
        .onChange(of: locationManager.location) { newLocation in
            DispatchQueue.main.async {
                // Centraliza no usuário apenas na primeira vez
                if let location = newLocation, !hasInitializedToUserLocation {
                    region = MKCoordinateRegion(
                        center: location.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
                    )
                    hasInitializedToUserLocation = true
                } else if !hasInitializedToUserLocation {
                    // Se não tem localização do usuário, centraliza no Rio
                    region = MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: -22.908333, longitude: -43.196388),
                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    )
                }
            }
        }
    }
    
    private func getStatusColor(for status: String?) -> Color {
        guard let status = status?.lowercased() else { return .gray }
        
        if status.contains("acionada") || status.contains("ativa") || status.contains("ligada") {
            return .red
        } else if status.contains("teste") {
            return .orange
        } else {
            return .green
        }
    }
}

//====================================================================//
// MARK: - View de Detalhes e Estilos
//====================================================================//


// Estilos
private let cardGradient = LinearGradient(gradient: Gradient(colors: [
    Color(red: 0.1, green: 0.5, blue: 0.9),
    Color(red: 0.3, green: 0.6, blue: 0.9)
]), startPoint: .top, endPoint: .bottom)

private var cardBorder: some View {
    RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.2), lineWidth: 1)
}
