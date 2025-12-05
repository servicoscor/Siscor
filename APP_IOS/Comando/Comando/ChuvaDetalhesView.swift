import SwiftUI
import MapKit

//====================================================================//
// MARK: - View Principal: Detalhes de Chuva (com Legenda)
//====================================================================//
struct ChuvaDetalhesView: View {
    let estacoes: [EstacaoChuva]
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var locationManager = LocationManager()
    @StateObject private var localizationManager = LocalizationManager.shared
    
    @State private var region: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -22.9068, longitude: -43.1729),
        span: MKCoordinateSpan(latitudeDelta: 0.3, longitudeDelta: 0.3)
    )
    @State private var estacaoSelecionada: EstacaoChuva?
    @State private var showLegendaSheet = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // O Mapa como camada de fundo
            Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: estacoes) { estacao in
                MapAnnotation(coordinate: estacao.coordinate ?? CLLocationCoordinate2D()) {
                    Button(action: { self.estacaoSelecionada = estacao }) {
                        PluviometroAnnotationView(estacao: estacao)
                    }
                }
            }
            .ignoresSafeArea()
            
            // Camada do Cabeçalho
            VStack {
                HeaderChuvaView(onDismiss: { dismiss() })
                Spacer()
            }
            
            // Os botões em uma VStack
            VStack(spacing: 16) {
                // Botão da legenda
                Button(action: { showLegendaSheet = true }) {
                    Image(systemName: "info.circle.fill")
                        .font(.title2).padding()
                        .background(.thinMaterial).clipShape(Circle()).shadow(radius: 4)
                }
                .accessibilityLabel(localizationManager.string(for: "rain_legend"))
                
                // Botão de localização
                Button(action: centerOnUser) {
                    Image(systemName: "location.fill")
                        .font(.title2).padding()
                        .background(.thinMaterial).clipShape(Circle()).shadow(radius: 4)
                }
                .accessibilityLabel(localizationManager.string(for: "center_on_location"))
            }
            .padding()
        }
        .onAppear(perform: centerOnUser)
        .sheet(item: $estacaoSelecionada) { estacao in
            PluviometroDetalhesSheet(estacao: estacao)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showLegendaSheet) {
            LegendaSheetView()
                .presentationDetents([.height(300)])
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
// MARK: - Componentes da Tela de Chuva
//====================================================================//

// Cabeçalho da tela
private struct HeaderChuvaView: View {
    var onDismiss: () -> Void
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        HStack {
            Text(localizationManager.string(for: "rain_gauges"))
                .font(.title3.bold())
                .foregroundColor(.primary)
            Spacer()
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.body.weight(.bold))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .accessibilityLabel(localizationManager.string(for: "close"))
        }
        .padding().background(.thinMaterial)
    }
}

// View da Legenda do Mapa (Sheet)
struct LegendaSheetView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            Capsule().fill(Color.secondary).frame(width: 40, height: 5)
            
            Text(localizationManager.string(for: "rain_legend_1h"))
                .font(.headline)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                LegendaItem(
                    color: .red,
                    label: localizationManager.string(for: "rain_heavy")
                )
                LegendaItem(
                    color: .yellow,
                    label: localizationManager.string(for: "rain_moderate")
                )
                LegendaItem(
                    color: .green,
                    label: localizationManager.string(for: "rain_light")
                )
                LegendaItem(
                    color: .blue,
                    label: localizationManager.string(for: "rain_none")
                )
                LegendaItem(
                    color: .gray,
                    label: localizationManager.string(for: "data_unavailable")
                )
            }
            
            Spacer()
            
            Button(localizationManager.string(for: "close")) {
                dismiss()
            }
            .padding()
        }
        .padding()
    }
}

// Item individual da legenda
private struct LegendaItem: View {
    let color: Color
    let label: String
    var body: some View {
        HStack {
            Circle().fill(color).frame(width: 14, height: 14)
                .overlay(Circle().stroke(Color.black.opacity(0.1), lineWidth: 1))
            Text(label).font(.body)
        }
    }
}

// O pino do mapa (annotation)
private struct PluviometroAnnotationView: View {
    let estacao: EstacaoChuva
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: "umbrella.fill").font(.body).foregroundColor(.white)
                .background(Circle().fill(corParaChuva(chuva1h: estacao.chuva_1)).frame(width: 40, height: 40).shadow(radius: 3))
                .scaleEffect(isAnimating ? 1.2 : 1.0)
            Image(systemName: "triangle.fill").font(.caption).foregroundColor(corParaChuva(chuva1h: estacao.chuva_1)).rotationEffect(.degrees(180)).offset(y: -2)
        }
        .onAppear {
            if (estacao.chuva_1 ?? 0) >= 5 {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) { isAnimating = true }
            }
        }
    }
    
    private func corParaChuva(chuva1h: Float?) -> Color {
        guard let chuva = chuva1h else { return .gray }
        if chuva <= 0 { return .blue }
        if chuva < 5 { return .green }
        if chuva < 25 { return .yellow }
        return .red
    }
}

// A folha de detalhes
private struct PluviometroDetalhesSheet: View {
    let estacao: EstacaoChuva
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            Capsule().fill(Color.secondary).frame(width: 40, height: 5).padding(.vertical, 8)
            Text(estacao.nome ?? localizationManager.string(for: "rain_gauge_station"))
                .font(.title2.bold())
                .padding(.bottom)
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Divider()
                    InfoRow(
                        label: localizationManager.string(for: "last_reading"),
                        value: formatarData(estacao.data)
                    )
                    Divider()
                    InfoRow(
                        label: localizationManager.string(for: "rain_last_hour"),
                        value: formatarChuva(estacao.chuva_1)
                    )
                    Divider()
                    InfoRow(
                        label: localizationManager.string(for: "rain_accumulated_4h"),
                        value: formatarChuva(estacao.chuva_4)
                    )
                    Divider()
                    InfoRow(
                        label: localizationManager.string(for: "rain_accumulated_24h"),
                        value: formatarChuva(estacao.chuva_24)
                    )
                    Divider()
                    InfoRow(
                        label: localizationManager.string(for: "rain_accumulated_96h"),
                        value: formatarChuva(estacao.chuva_96)
                    )
                    Divider()
                    InfoRow(
                        label: localizationManager.string(for: "rain_accumulated_30d"),
                        value: formatarChuva(estacao.chuva_30)
                    )
                    Divider()
                    InfoRow(
                        label: localizationManager.string(for: "source"),
                        value: estacao.fonte ?? localizationManager.string(for: "not_available")
                    )
                }.padding()
            }
        }
    }
    
    private func formatarChuva(_ valor: Float?) -> String {
        guard let valor else { return localizationManager.string(for: "not_available") }
        return String(format: "%.1f mm", valor)
    }
    
    private func formatarData(_ dateString: String?) -> String {
        guard let dateString else { return localizationManager.string(for: "not_available") }
        // Aqui você pode melhorar com DateFormatter localizado
        return dateString
    }
}



// MARK: - Chaves de Localização para adicionar ao Localizable.strings

/*
// Português (pt)
"rain_gauges" = "Pluviômetros";
"rain_legend" = "Legenda de chuva";
"rain_legend_1h" = "Legenda de Chuva (1h)";
"rain_heavy" = "Forte (≥ 25mm)";
"rain_moderate" = "Moderada (≥ 5mm)";
"rain_light" = "Fraca (< 5mm)";
"rain_none" = "Sem Chuva";
"rain_gauge_station" = "Estação Pluviométrica";
"last_reading" = "Última Leitura";
"rain_last_hour" = "Chuva na Última Hora";
"rain_accumulated_4h" = "Acumulado em 4h";
"rain_accumulated_24h" = "Acumulado em 24h";
"rain_accumulated_96h" = "Acumulado em 96h";
"rain_accumulated_30d" = "Acumulado em 30 dias";

// English (en)
"rain_gauges" = "Rain Gauges";
"rain_legend" = "Rain legend";
"rain_legend_1h" = "Rain Legend (1h)";
"rain_heavy" = "Heavy (≥ 25mm)";
"rain_moderate" = "Moderate (≥ 5mm)";
"rain_light" = "Light (< 5mm)";
"rain_none" = "No Rain";
"rain_gauge_station" = "Rain Gauge Station";
"last_reading" = "Last Reading";
"rain_last_hour" = "Rain in Last Hour";
"rain_accumulated_4h" = "4h Accumulation";
"rain_accumulated_24h" = "24h Accumulation";
"rain_accumulated_96h" = "96h Accumulation";
"rain_accumulated_30d" = "30 Day Accumulation";

// Español (es)
"rain_gauges" = "Pluviómetros";
"rain_legend" = "Leyenda de lluvia";
"rain_legend_1h" = "Leyenda de Lluvia (1h)";
"rain_heavy" = "Fuerte (≥ 25mm)";
"rain_moderate" = "Moderada (≥ 5mm)";
"rain_light" = "Ligera (< 5mm)";
"rain_none" = "Sin Lluvia";
"rain_gauge_station" = "Estación Pluviométrica";
"last_reading" = "Última Lectura";
"rain_last_hour" = "Lluvia en la Última Hora";
"rain_accumulated_4h" = "Acumulado en 4h";
"rain_accumulated_24h" = "Acumulado en 24h";
"rain_accumulated_96h" = "Acumulado en 96h";
"rain_accumulated_30d" = "Acumulado en 30 días";

// Strings já existentes reutilizadas:
// - close
// - center_on_location
// - data_unavailable
// - source
// - not_available
*/
