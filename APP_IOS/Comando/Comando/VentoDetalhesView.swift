import SwiftUI
import MapKit

//====================================================================//
// MARK: - View Principal: Detalhes de Vento
//====================================================================//
struct VentoDetalhesView: View {
    let estacoes: [EstacaoMeteorologica]
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var locationManager = LocationManager()
    @StateObject private var localizationManager = LocalizationManager.shared
    
    @State private var region: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -22.9068, longitude: -43.1729),
        span: MKCoordinateSpan(latitudeDelta: 0.3, longitudeDelta: 0.3)
    )
    
    @State private var estacaoSelecionada: EstacaoMeteorologica?
    @State private var showLegendaSheet = false

    var body: some View {
        ZStack {
            // O Mapa como camada de fundo
            Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: estacoes) { estacao in
                MapAnnotation(coordinate: estacao.coordinate ?? CLLocationCoordinate2D()) {
                    Button(action: { self.estacaoSelecionada = estacao }) {
                        EstacaoVentoAnnotationView(estacao: estacao)
                    }
                }
            }
            .ignoresSafeArea()
            
            // Camada de Controles sobre o mapa
            VStack(spacing: 0) {
                HeaderVentoView(onDismiss: { dismiss() })
                Spacer()
                ControlesMapaVentoView(
                    onInfo: { showLegendaSheet = true },
                    onCenter: centerOnUser
                )
            }
        }
        .onAppear(perform: centerOnUser)
        .sheet(item: $estacaoSelecionada) { estacao in
            EstacaoVentoDetalhesSheet(estacao: estacao)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showLegendaSheet) {
            VentoLegendaSheetView()
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
// MARK: - Componentes da Tela de Vento
//====================================================================//

private struct HeaderVentoView: View {
    var onDismiss: () -> Void
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        HStack {
            Text(localizationManager.string(for: "weather_stations"))
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
        }
        .padding()
        .background(.thinMaterial)
    }
}

private struct ControlesMapaVentoView: View {
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
                .accessibilityLabel(localizationManager.string(for: "wind_legend"))
                
                Button(action: onCenter) {
                    Image(systemName: "location.fill")
                        .font(.title2)
                        .padding()
                        .background(.thinMaterial)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .accessibilityLabel(localizationManager.string(for: "center_on_location"))
            }
        }
        .padding()
    }
}

private struct EstacaoVentoAnnotationView: View {
    let estacao: EstacaoMeteorologica
    
    var body: some View {
        Image(systemName: "location.north.circle.fill")
            .font(.title)
            .symbolRenderingMode(.palette)
            .foregroundStyle(.white, corParaVento(velocidade: estacao.vel_med))
            .rotationEffect(rotationForDirection(estacao.dir_med))
            .background(Circle().fill(.white.opacity(0.6)).blur(radius: 1))
            .shadow(color: .black.opacity(0.3), radius: 3, y: 2)
    }
    
    private func rotationForDirection(_ direction: String?) -> Angle {
        guard let dir = direction?.uppercased() else { return .zero }
        switch dir {
            case "N": return .degrees(0); case "NNE": return .degrees(22.5); case "NE": return .degrees(45)
            case "ENE": return .degrees(67.5); case "E": return .degrees(90); case "ESE": return .degrees(112.5)
            case "SE": return .degrees(135); case "SSE": return .degrees(157.5); case "S": return .degrees(180)
            case "SSW": return .degrees(202.5); case "SW": return .degrees(225); case "WSW": return .degrees(247.5)
            case "W": return .degrees(270); case "WNW": return .degrees(292.5); case "NW": return .degrees(315)
            case "NNW": return .degrees(337.5)
            default: return .zero
        }
    }

    private func corParaVento(velocidade: Float?) -> Color {
        guard let vel_ms = velocidade else { return .gray }
        let vel_kmh = vel_ms * 3.6
        if vel_kmh < 19 { return .blue }
        if vel_kmh < 38 { return .green }
        if vel_kmh < 61 { return .yellow }
        return .red
    }
}

private struct EstacaoVentoDetalhesSheet: View {
    let estacao: EstacaoMeteorologica
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            Capsule().fill(Color.secondary).frame(width: 40, height: 5).padding(.vertical, 8)
            Text(estacao.nome ?? localizationManager.string(for: "weather_station"))
                .font(.title2.bold())
                .padding(.bottom)
            ScrollView {
                VStack(spacing: 16) {
                    Divider()
                    InfoRowVento(
                        label: localizationManager.string(for: "last_reading"),
                        value: estacao.data ?? localizationManager.string(for: "not_available")
                    )
                    Divider()
                    InfoRowVento(
                        label: localizationManager.string(for: "average_temperature"),
                        value: formatarTemperatura(estacao.tem_med)
                    )
                    Divider()
                    InfoRowVento(
                        label: localizationManager.string(for: "average_humidity"),
                        value: formatarUmidade(estacao.umd_med)
                    )
                    Divider()
                    InfoRowVento(
                        label: localizationManager.string(for: "wind_speed"),
                        value: formatarVelocidade(estacao.vel_med)
                    )
                    Divider()
                    InfoRowVento(
                        label: localizationManager.string(for: "wind_direction"),
                        value: traduzirDirecao(estacao.dir_med)
                    )
                    Divider()
                    InfoRowVento(
                        label: localizationManager.string(for: "source"),
                        value: estacao.fonte ?? localizationManager.string(for: "not_available")
                    )
                }.padding()
            }
        }
    }
    
    private func formatarTemperatura(_ valor: Float?) -> String {
        guard let valor else { return localizationManager.string(for: "not_available") }
        if localizationManager.currentLanguage == "en" {
            // Converter para Fahrenheit se inglês
            let fahrenheit = (valor * 9/5) + 32
            return String(format: "%.1f °F", fahrenheit)
        }
        return String(format: "%.1f °C", valor)
    }
    
    private func formatarUmidade(_ valor: Float?) -> String {
        guard let valor else { return localizationManager.string(for: "not_available") }
        return String(format: "%.1f%%", valor)
    }
    
    private func formatarVelocidade(_ valor: Float?) -> String {
        guard let valor else { return localizationManager.string(for: "not_available") }
        let kmh = valor * 3.6
        return String(format: "%.1f km/h", kmh)
    }
    
    private func traduzirDirecao(_ direcao: String?) -> String {
        guard let dir = direcao else { return localizationManager.string(for: "not_available") }
        
        // Se não for português, traduz as direções
        if localizationManager.currentLanguage != "pt" {
            let traducoes: [String: [String: String]] = [
                "en": [
                    "N": "N", "S": "S", "E": "E", "W": "W",
                    "NE": "NE", "SE": "SE", "SW": "SW", "NW": "NW",
                    "NNE": "NNE", "ENE": "ENE", "ESE": "ESE", "SSE": "SSE",
                    "SSW": "SSW", "WSW": "WSW", "WNW": "WNW", "NNW": "NNW"
                ],
                "es": [
                    "N": "N", "S": "S", "E": "E", "W": "O",
                    "NE": "NE", "SE": "SE", "SW": "SO", "NW": "NO",
                    "NNE": "NNE", "ENE": "ENE", "ESE": "ESE", "SSE": "SSE",
                    "SSW": "SSO", "WSW": "OSO", "WNW": "ONO", "NNW": "NNO"
                ]
            ]
            
            if let traduzido = traducoes[localizationManager.currentLanguage]?[dir.uppercased()] {
                return traduzido
            }
        }
        
        return dir
    }
}

struct VentoLegendaSheetView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            Capsule().fill(Color.secondary).frame(width: 40, height: 5)
            Text(localizationManager.string(for: "wind_legend"))
                .font(.headline)
            Divider()
            VStack(alignment: .leading, spacing: 12) {
                LegendaItemVento(
                    color: .red,
                    label: localizationManager.string(for: "wind_strong")
                )
                LegendaItemVento(
                    color: .yellow,
                    label: localizationManager.string(for: "wind_moderate")
                )
                LegendaItemVento(
                    color: .green,
                    label: localizationManager.string(for: "wind_weak")
                )
                LegendaItemVento(
                    color: .blue,
                    label: localizationManager.string(for: "wind_calm")
                )
                LegendaItemVento(
                    color: .gray,
                    label: localizationManager.string(for: "data_unavailable")
                )
            }
            Spacer()
            Button(localizationManager.string(for: "close"), action: { dismiss() })
                .padding()
        }.padding()
    }
}

private struct InfoRowVento: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label).foregroundColor(.secondary)
            Spacer()
            Text(value).fontWeight(.bold)
        }
    }
}

private struct LegendaItemVento: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 14, height: 14)
                .overlay(Circle().stroke(Color.black.opacity(0.1)))
            Text(label).font(.body)
        }
    }
}

// MARK: - Chaves de Localização para adicionar ao Localizable.strings

/*
// Português (pt)
"weather_stations" = "Estações Meteorológicas";
"weather_station" = "Estação Meteorológica";
"wind_legend" = "Legenda de Vento";
"center_on_location" = "Centralizar na localização";
"last_reading" = "Última Leitura";
"average_temperature" = "Temperatura Média";
"average_humidity" = "Umidade Média";
"wind_speed" = "Velocidade do Vento";
"wind_direction" = "Direção do Vento";
"source" = "Fonte";
"not_available" = "N/D";
"close" = "Fechar";
"wind_strong" = "Forte (≥ 61 km/h)";
"wind_moderate" = "Moderado (≥ 38 km/h)";
"wind_weak" = "Fraco (≥ 19 km/h)";
"wind_calm" = "Calmo (< 19 km/h)";
"data_unavailable" = "Dados Indisponíveis";

// English (en)
"weather_stations" = "Weather Stations";
"weather_station" = "Weather Station";
"wind_legend" = "Wind Legend";
"center_on_location" = "Center on location";
"last_reading" = "Last Reading";
"average_temperature" = "Average Temperature";
"average_humidity" = "Average Humidity";
"wind_speed" = "Wind Speed";
"wind_direction" = "Wind Direction";
"source" = "Source";
"not_available" = "N/A";
"close" = "Close";
"wind_strong" = "Strong (≥ 61 km/h)";
"wind_moderate" = "Moderate (≥ 38 km/h)";
"wind_weak" = "Weak (≥ 19 km/h)";
"wind_calm" = "Calm (< 19 km/h)";
"data_unavailable" = "Data Unavailable";

// Español (es)
"weather_stations" = "Estaciones Meteorológicas";
"weather_station" = "Estación Meteorológica";
"wind_legend" = "Leyenda de Viento";
"center_on_location" = "Centrar en ubicación";
"last_reading" = "Última Lectura";
"average_temperature" = "Temperatura Media";
"average_humidity" = "Humedad Media";
"wind_speed" = "Velocidad del Viento";
"wind_direction" = "Dirección del Viento";
"source" = "Fuente";
"not_available" = "N/D";
"close" = "Cerrar";
"wind_strong" = "Fuerte (≥ 61 km/h)";
"wind_moderate" = "Moderado (≥ 38 km/h)";
"wind_weak" = "Débil (≥ 19 km/h)";
"wind_calm" = "Calmo (< 19 km/h)";
"data_unavailable" = "Datos No Disponibles";
*/
