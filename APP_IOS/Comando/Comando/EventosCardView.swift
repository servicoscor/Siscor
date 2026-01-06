import SwiftUI
import MapKit

// MARK: - Enum de Tipos de Evento
enum TipoEvento: String, CaseIterable {
    case todos = "Todos"
    case congresso = "Congresso"
    case cultural = "Cultural"
    case esportivo = "Esportivo"
    case feira = "Feira"
    case musical = "Musical"
    case manifestacao = "Manifestação"
    case religioso = "Religioso"
    case reveillon = "Réveillon"
    case carnavalBairro = "Carnaval de bairro"
    case carnavalDesfiles = "Carnaval: Desfiles"
    case carnavalEnsaios = "Carnaval: Ensaios Técnicos"
    case carnavalBlocos = "Carnaval: Blocos"
    case carnavalPalcos = "Carnaval: Palcos"
    case blocosNaoOficiais = "Blocos não oficiais"
    case simulado = "Simulado"
    case academicos = "Acadêmicos"
    case g20 = "G20"
    case corporativo = "Corporativo"
    case politico = "Político"
    case gastronomico = "Gastronômico"
    case educacional = "Educacional"
    case outro = "Outro"
    
    func displayName(localizationManager: LocalizationManager) -> String {
        switch self {
        case .todos: return localizationManager.string(for: "event_type_all")
        case .congresso: return localizationManager.string(for: "event_type_congress")
        case .cultural: return localizationManager.string(for: "event_type_cultural")
        case .esportivo: return localizationManager.string(for: "event_type_sports")
        case .feira: return localizationManager.string(for: "event_type_fair")
        case .musical: return localizationManager.string(for: "event_type_musical")
        case .manifestacao: return localizationManager.string(for: "event_type_protest")
        case .religioso: return localizationManager.string(for: "event_type_religious")
        case .reveillon: return localizationManager.string(for: "event_type_new_year")
        case .carnavalBairro: return localizationManager.string(for: "event_type_carnival_neighborhood")
        case .carnavalDesfiles: return localizationManager.string(for: "event_type_carnival_parades")
        case .carnavalEnsaios: return localizationManager.string(for: "event_type_carnival_rehearsals")
        case .carnavalBlocos: return localizationManager.string(for: "event_type_carnival_blocks")
        case .carnavalPalcos: return localizationManager.string(for: "event_type_carnival_stages")
        case .blocosNaoOficiais: return localizationManager.string(for: "event_type_unofficial_blocks")
        case .simulado: return localizationManager.string(for: "event_type_simulation")
        case .academicos: return localizationManager.string(for: "event_type_academic")
        case .g20: return "G20"
        case .corporativo: return localizationManager.string(for: "event_type_corporate")
        case .politico: return localizationManager.string(for: "event_type_political")
        case .gastronomico: return localizationManager.string(for: "event_type_gastronomic")
        case .educacional: return localizationManager.string(for: "event_type_educational")
        case .outro: return localizationManager.string(for: "event_type_other")
        }
    }
    
    var icon: String {
        switch self {
        case .todos: return "square.grid.2x2"
        case .congresso, .g20, .corporativo: return "building.2.fill"
        case .cultural: return "theatermasks.fill"
        case .esportivo: return "sportscourt.fill"
        case .feira: return "bag.fill"
        case .musical: return "music.note"
        case .manifestacao: return "megaphone.fill"
        case .religioso: return "hands.sparkles.fill"
        case .reveillon: return "sparkles"
        case .carnavalBairro, .carnavalDesfiles, .carnavalEnsaios, .carnavalBlocos, .carnavalPalcos, .blocosNaoOficiais:
            return "party.popper.fill"
        case .simulado: return "doc.text.fill"
        case .academicos, .educacional: return "book.fill"
        case .politico: return "flag.fill"
        case .gastronomico: return "fork.knife"
        case .outro: return "star.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .todos: return .gray
        case .congresso, .g20, .corporativo: return .indigo
        case .cultural: return .purple
        case .esportivo: return .green
        case .feira: return .teal
        case .musical: return .orange
        case .manifestacao: return .yellow
        case .religioso: return .mint
        case .reveillon: return .cyan
        case .carnavalBairro, .carnavalDesfiles, .carnavalEnsaios, .carnavalBlocos, .carnavalPalcos, .blocosNaoOficiais:
            return .pink
        case .simulado: return .brown
        case .academicos, .educacional: return .blue
        case .politico: return Color(red: 0.0, green: 0.4, blue: 0.0)
        case .gastronomico: return .red
        case .outro: return .gray
        }
    }
}

// MARK: - View Principal de Eventos (Tela Cheia)
// MARK: - View Principal de Eventos (Tela Cheia)
struct EventosView: View {
    let eventos: [Evento]
    @Environment(\.dismiss) private var dismiss
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var searchText = ""
    @State private var selectedTipo: TipoEvento = .todos
    @State private var selectedEvento: Evento?
    @State private var showingMap = false
    
    var eventosFiltrados: [Evento] {
        eventos.filter { evento in
            if selectedTipo != .todos && evento.tipo != selectedTipo {
                return false
            }
            if !searchText.isEmpty {
                let searchLower = searchText.lowercased()
                return (evento.nome?.lowercased().contains(searchLower) ?? false) ||
                       (evento.descricao?.lowercased().contains(searchLower) ?? false) ||
                       (evento.local?.lowercased().contains(searchLower) ?? false) ||
                       (evento.zona?.lowercased().contains(searchLower) ?? false)
            }
            return true
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.title3)
                            .foregroundColor(.blue)
                        Text(localizationManager.string(for: "city_events"))
                            .font(.title3.bold())
                            .foregroundColor(.primary)
                    }
                    Spacer()
                    if eventosFiltrados.contains(where: { $0.lat != nil && $0.lon != nil }) {
                        Button(action: { showingMap = true }) {
                            Image(systemName: "map")
                                .font(.body.weight(.bold))
                                .foregroundColor(.white.opacity(0.8))
                                .padding(8)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                        .accessibilityLabel(localizationManager.string(for: "show_map"))
                    }
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
                HStack {
                    Image(systemName: "magnifyingglass").foregroundColor(.gray)
                    TextField(localizationManager.string(for: "search_events"), text: $searchText)
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(TipoEvento.allCases, id: \.self) { tipo in
                            FilterChip(
                                tipo: tipo,
                                isSelected: selectedTipo == tipo,
                                action: { selectedTipo = tipo }
                            )
                        }
                    }
                }
            }
            .padding()
            .background(.thinMaterial)
            if eventosFiltrados.isEmpty {
                Spacer()
                EmptyStateView(
                    icon: "calendar.badge.exclamationmark",
                    message: searchText.isEmpty ?
                        localizationManager.string(for: "no_events_available") :
                        localizationManager.string(for: "no_events_found")
                )
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        HStack {
                            Text(String(format: localizationManager.string(for: "events_found"), eventosFiltrados.count))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal)
                        ForEach(eventosFiltrados) { evento in
                            EventoListCard(evento: evento)
                                .onTapGesture {
                                    selectedEvento = evento
                                }
                        }
                    }
                    .padding()
                }
            }
        }
        .sheet(item: $selectedEvento) { evento in
            EventoDetailView(evento: evento)
        }
        .sheet(isPresented: $showingMap) {
            EventosMapView(eventos: eventosFiltrados)
        }
    }
}

// MARK: - Chip de Filtro
struct FilterChip: View {
    let tipo: TipoEvento
    let isSelected: Bool
    let action: () -> Void
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: tipo.icon)
                    .font(.caption)
                Text(tipo.displayName(localizationManager: localizationManager))
                    .font(.caption.weight(.medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                isSelected ? tipo.color : Color(.systemGray5)
            )
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(isSelected ? Color.clear : Color(.systemGray4), lineWidth: 1)
            )
        }
    }
}

struct EventoListCard: View {
    let evento: Evento
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: evento.tipo.icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(evento.tipo.color)
                    .cornerRadius(8)
                VStack(alignment: .leading, spacing: 4) {
                    Text(evento.nome ?? localizationManager.string(for: "event"))
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    if let data = evento.data {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption2)
                            Text(formatDate(data))
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                }
                Spacer()
                if let criticidade = evento.criticidade {
                    Text(localizeCriticality(criticidade))
                        .font(.caption.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(colorForCriticality(criticidade))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                if evento.importante == true {
                    Text(localizationManager.string(for: "important"))
                        .font(.caption.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            if let descricao = evento.descricao {
                Text(descricao)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            HStack(spacing: 16) {
                if let local = evento.local {
                    HStack(spacing: 4) {
                        Image(systemName: "location")
                            .font(.caption2)
                        Text(local)
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .foregroundColor(.secondary)
                }
                if let zona = evento.zona {
                    HStack(spacing: 4) {
                        Image(systemName: "location.circle")
                            .font(.caption2)
                        Text(localizeZone(zona))
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
                if let quantidade = evento.quantidadePessoas {
                    HStack(spacing: 4) {
                        Image(systemName: "person.3")
                            .font(.caption2)
                        Text(formatQuantity(quantidade))
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM 'às' HH:mm"
        return formatter.string(from: date)
    }
    
    private func localizeZone(_ zona: String) -> String {
        switch zona.lowercased() {
        case "zona sul": return localizationManager.string(for: "zone_south")
        case "zona norte": return localizationManager.string(for: "zone_north")
        case "zona oeste": return localizationManager.string(for: "zone_west")
        case "centro": return localizationManager.string(for: "zone_center")
        default: return zona
        }
    }
    
    private func localizeCriticality(_ criticidade: String) -> String {
        switch criticidade.lowercased() {
        case "alta": return localizationManager.string(for: "criticality_high")
        case "média": return localizationManager.string(for: "criticality_medium")
        case "normal": return localizationManager.string(for: "criticality_normal")
        default: return criticidade
        }
    }
    
    private func colorForCriticality(_ criticidade: String) -> Color {
        switch criticidade.lowercased() {
        case "alta": return .red
        case "média": return .orange
        case "normal": return .green
        default: return .gray
        }
    }
    
    private func formatQuantity(_ quantidade: Int) -> String {
        if quantidade < 1000 {
            return "\(quantidade)"
        } else if quantidade < 1000000 {
            return "\(quantidade / 1000)k"
        } else {
            return String(format: "%.1fM", Double(quantidade) / 1000000)
        }
    }
}

// MARK: - View de Detalhes do Evento
struct EventoDetailView: View {
    let evento: Evento
    @Environment(\.dismiss) private var dismiss
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var showShareSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(localizationManager.string(for: "event_details"))
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
            .padding()
            .background(.thinMaterial)
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Spacer()
                    HStack {
                        Image(systemName: evento.tipo.icon)
                            .font(.largeTitle)
                            .foregroundColor(evento.tipo.color)
                        VStack(alignment: .leading) {
                            Text(evento.tipo.displayName(localizationManager: localizationManager))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(evento.nome ?? localizationManager.string(for: "event"))
                                .font(.largeTitle.bold())
                                .foregroundColor(.primary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    HStack {
                        if let criticidade = evento.criticidade {
                            Badge(
                                text: localizeCriticality(criticidade),
                                color: colorForCriticality(criticidade)
                            )
                        }
                        if evento.importante == true {
                            Badge(
                                text: localizationManager.string(for: "important"),
                                color: .red
                            )
                        }
                    }
                    .padding(.horizontal)
                    VStack(spacing: 16) {
                        if let data = evento.data {
                            InfoRow2(
                                icon: "calendar",
                                title: localizationManager.string(for: "date"),
                                value: formatFullDate(data)
                            )
                        }
                        if let horaInicio = evento.horaInicio, let horaFim = evento.horaEncerramento {
                            InfoRow2(
                                icon: "clock",
                                title: localizationManager.string(for: "time"),
                                value: "\(horaInicio) - \(horaFim)"
                            )
                        }
                        if let local = evento.local {
                            InfoRow2(
                                icon: "location",
                                title: localizationManager.string(for: "location"),
                                value: local
                            )
                        }
                        if let zona = evento.zona {
                            InfoRow2(
                                icon: "location.circle",
                                title: localizationManager.string(for: "zone"),
                                value: localizeZone(zona)
                            )
                        }
                        if let quantidade = evento.quantidadePessoas {
                            InfoRow2(
                                icon: "person.3",
                                title: localizationManager.string(for: "expected_public"),
                                value: formatFullQuantity(quantidade)
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    if let descricao = evento.descricao {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(localizationManager.string(for: "description"))
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text(descricao)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                    }
                    VStack(spacing: 12) {
                        if evento.lat != nil && evento.lon != nil {
                            Button(action: openInMaps) {
                                Label(localizationManager.string(for: "get_directions"), systemImage: "map")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                        }
                        Button(action: { showShareSheet = true }) {
                            Label(localizationManager.string(for: "share_event"), systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray5))
                                .foregroundColor(.primary)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ActivityView(activityItems: [formatEventForSharing()])
        }
    }
    
    private func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func localizeZone(_ zona: String) -> String {
        switch zona.lowercased() {
        case "zona sul": return localizationManager.string(for: "zone_south")
        case "zona norte": return localizationManager.string(for: "zone_north")
        case "zona oeste": return localizationManager.string(for: "zone_west")
        case "centro": return localizationManager.string(for: "zone_center")
        default: return zona
        }
    }
    
    private func localizeCriticality(_ criticidade: String) -> String {
        switch criticidade.lowercased() {
        case "alta": return localizationManager.string(for: "criticality_high")
        case "média": return localizationManager.string(for: "criticality_medium")
        case "normal": return localizationManager.string(for: "criticality_normal")
        default: return criticidade
        }
    }
    
    private func colorForCriticality(_ criticidade: String) -> Color {
        switch criticidade.lowercased() {
        case "alta": return .red
        case "média": return .orange
        case "normal": return .green
        default: return .gray
        }
    }
    
    private func formatFullQuantity(_ quantidade: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: quantidade)) ?? "\(quantidade)"
    }
    
    private func openInMaps() {
        guard let lat = evento.lat, let lon = evento.lon else { return }
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = evento.nome
        mapItem.openInMaps()
    }
    
    private func formatEventForSharing() -> String {
        var text = evento.nome ?? localizationManager.string(for: "event")
        if let data = evento.data {
            text += "\n\(localizationManager.string(for: "date")): \(formatFullDate(data))"
        }
        if let local = evento.local {
            text += "\n\(localizationManager.string(for: "location")): \(local)"
        }
        if let descricao = evento.descricao {
            text += "\n\n\(descricao)"
        }
        return text
    }
}

struct InfoRow2: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.body)
            }
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Componentes auxiliares
struct Badge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption.bold())
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(12)
    }
}

// MARK: - Mapa de Eventos
struct EventosMapView: View {
    let eventos: [Evento]
    @Environment(\.dismiss) private var dismiss
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -22.9068, longitude: -43.1729),
        span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
    )
    
    var eventosComCoordenadas: [Evento] {
        eventos.filter { $0.lat != nil && $0.lon != nil }
    }
    
    var body: some View {
        NavigationView {
            Map(coordinateRegion: $region, annotationItems: eventosComCoordenadas) { evento in
                MapAnnotation(coordinate: CLLocationCoordinate2D(
                    latitude: evento.lat ?? 0,
                    longitude: evento.lon ?? 0
                )) {
                    VStack {
                        Image(systemName: evento.tipo.icon)
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(evento.tipo.color)
                            .clipShape(Circle())
                        Image(systemName: "triangle.fill")
                            .font(.caption)
                            .foregroundColor(evento.tipo.color)
                            .offset(y: -5)
                    }
                }
            }
            .ignoresSafeArea()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(localizationManager.string(for: "close")) {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                ToolbarItem(placement: .principal) {
                    Text(localizationManager.string(for: "events_map"))
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
        }
    }
}


// MARK: - View para Evento Importante
struct EventoImportanteView: View {
    let evento: Evento
    let onTap: () -> Void
    @StateObject private var localizationManager = LocalizationManager.shared
    
    @State private var imageLoading = true
    @State private var loadedImage: UIImage?
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                if let imagemURL = evento.imagemURL, let url = URL(string: imagemURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ZStack {
                                Rectangle()
                                    .fill(evento.tipo.color.opacity(0.2))
                                    .frame(height: 180)
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 180)
                                .clipped()
                        case .failure(_):
                            ZStack {
                                Rectangle()
                                    .fill(evento.tipo.color.opacity(0.2))
                                    .frame(height: 180)
                                VStack {
                                    Image(systemName: "photo")
                                        .font(.largeTitle)
                                        .foregroundColor(.white.opacity(0.5))
                                    Text(localizationManager.string(for: "image_unavailable"))
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.5))
                                }
                            }
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .overlay(
                        VStack {
                            HStack {
                                Spacer()
                                Text(localizationManager.string(for: "important"))
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.red)
                                    .cornerRadius(12)
                                    .padding()
                            }
                            Spacer()
                        }
                    )
                } else {
                    ZStack {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [evento.tipo.color, evento.tipo.color.opacity(0.6)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(height: 180)
                        Image(systemName: evento.tipo.icon)
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.3))
                        VStack {
                            HStack {
                                Spacer()
                                Text(localizationManager.string(for: "important"))
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.red)
                                    .cornerRadius(12)
                                    .padding()
                            }
                            Spacer()
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 12) {
                    Text(evento.nome ?? localizationManager.string(for: "important_event"))
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    HStack(spacing: 16) {
                        if let data = evento.data, let horaInicio = evento.horaInicio {
                            HStack(spacing: 4) {
                                Image(systemName: "clock.fill")
                                    .font(.caption)
                                Text(formatarDataHora(data: data, hora: horaInicio))
                                    .font(.caption)
                            }
                            .foregroundColor(.white.opacity(0.9))
                        }
                        if let local = evento.local {
                            HStack(spacing: 4) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.caption)
                                Text(local)
                                    .font(.caption)
                                    .lineLimit(1)
                            }
                            .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    HStack {
                        Text(localizationManager.string(for: "touch_for_details"))
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        Spacer()
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatarDataHora(data: Date, hora: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM"
        formatter.locale = Locale(identifier: localizationManager.currentLanguage)
        return String(format: localizationManager.string(for: "date_at_time"), formatter.string(from: data), hora)
    }
}

struct OutrosEventosListView: View {
    let eventos: [Evento]
    let onEventSelect: (Evento) -> Void
    @Environment(\.dismiss) private var dismiss
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(localizationManager.string(for: "other_events_title"))
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
            .padding()
            .background(.thinMaterial)
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(eventos) { evento in
                        Button(action: {
                            onEventSelect(evento)
                        }) {
                            HStack(spacing: 16) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(evento.tipo.color.opacity(0.15))
                                        .frame(width: 50, height: 50)
                                    Image(systemName: evento.tipo.icon)
                                        .font(.title3)
                                        .foregroundColor(evento.tipo.color)
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(evento.nome ?? localizationManager.string(for: "event"))
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.leading)
                                    if let data = evento.data, let hora = evento.horaInicio {
                                        HStack(spacing: 4) {
                                            Image(systemName: "clock")
                                                .font(.caption)
                                            Text(formatarDataHora(data: data, hora: hora))
                                                .font(.caption)
                                        }
                                        .foregroundColor(.secondary)
                                    }
                                    if let local = evento.local {
                                        HStack(spacing: 4) {
                                            Image(systemName: "location")
                                                .font(.caption)
                                            Text(local)
                                                .font(.caption)
                                                .lineLimit(1)
                                        }
                                        .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                                if let criticidade = evento.criticidade {
                                    Text(localizeCriticality(criticidade))
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(corParaCriticidade(criticidade))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(corParaCriticidade(criticidade).opacity(0.15))
                                        .cornerRadius(8)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
            }
        }
    }
    
    private func formatarDataHora(data: Date, hora: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM"
        formatter.locale = Locale(identifier: localizationManager.currentLanguage)
        return "\(formatter.string(from: data)) • \(hora)"
    }
    
    private func localizeCriticality(_ criticidade: String) -> String {
        switch criticidade.lowercased() {
        case "alta": return localizationManager.string(for: "criticality_high")
        case "média": return localizationManager.string(for: "criticality_medium")
        case "normal": return localizationManager.string(for: "criticality_normal")
        default: return criticidade
        }
    }
    
    private func corParaCriticidade(_ criticidade: String) -> Color {
        switch criticidade.lowercased() {
        case "alta": return .red
        case "média": return .orange
        case "normal": return .green
        default: return .gray
        }
    }
}

// MARK: - Carrossel de Eventos
struct EventoCarouselView: View {
    let eventos: [Evento]
    @Binding var currentIndex: Int
    let onEventTap: (Evento) -> Void
    
    var body: some View {
        ZStack {
            if !eventos.isEmpty {
                EventoItemView(
                    evento: eventos[currentIndex],
                    onTap: { onEventTap(eventos[currentIndex]) }
                )
                .id(currentIndex)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.8).combined(with: .opacity),
                    removal: .scale(scale: 1.2).combined(with: .opacity)
                ))
            }
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width < -50 {
                        if currentIndex < eventos.count - 1 {
                            withAnimation(.easeInOut) {
                                currentIndex += 1
                            }
                        }
                    } else if value.translation.width > 50 {
                        if currentIndex > 0 {
                            withAnimation(.easeInOut) {
                                currentIndex -= 1
                            }
                        }
                    }
                }
        )
    }
}

// MARK: - Item Individual do Evento (ATUALIZADO PARA PERMITIR CLIQUE NA DESCRIÇÃO)
struct EventoItemView: View {
    let evento: Evento
    let onTap: () -> Void
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var eventoSelecionado: Evento?
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM • HH:mm"
        formatter.locale = Locale(identifier: localizationManager.currentLanguage)
        return formatter
    }
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(evento.tipo.color.opacity(0.2) ?? Color.gray.opacity(0.2))
                        .frame(width: 60, height: 60)
                    Image(systemName: evento.tipo.icon ?? "calendar")
                        .font(.title2)
                        .foregroundColor(evento.tipo.color ?? .gray)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text(evento.nome ?? localizationManager.string(for: "event"))
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(2)
                    if let data = evento.data, let horaInicio = evento.horaInicio {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption)
                            Text(String(format: localizationManager.string(for: "date_at_time"),
                                       dateFormatter.string(from: data), horaInicio))
                                .font(.caption)
                        }
                        .foregroundColor(.white.opacity(0.8))
                    }
                    if let zona = evento.zona {
                        HStack(spacing: 4) {
                            Image(systemName: "location.circle")
                                .font(.caption)
                            Text(localizeZone(zona))
                                .font(.caption)
                        }
                        .foregroundColor(.white.opacity(0.8))
                    }
                    if let local = evento.local {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.circle")
                                .font(.caption)
                            Text(local)
                                .font(.caption)
                                .lineLimit(1)
                        }
                        .foregroundColor(.white.opacity(0.8))
                    }
                    if let descricao = evento.descricao, !descricao.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.text.fill")
                                .font(.caption2)
                            Text(localizationManager.string(for: "description_available"))
                                .font(.caption2)
                                .italic()
                        }
                        .foregroundColor(.yellow.opacity(0.8))
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
        .onLongPressGesture(minimumDuration: 0.1, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
        .sheet(item: $eventoSelecionado) { evento in
            EventoDetailView(evento: evento)
        }
    }
    
    private func localizeZone(_ zona: String) -> String {
        switch zona.lowercased() {
        case "zona sul": return localizationManager.string(for: "zone_south")
        case "zona norte": return localizationManager.string(for: "zone_north")
        case "zona oeste": return localizationManager.string(for: "zone_west")
        case "centro": return localizationManager.string(for: "zone_center")
        default: return zona
        }
    }
}

// Estilos do card
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

// MARK: - ShareSheet nativo substituto
struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    var excludedActivityTypes: [UIActivity.ActivityType]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        controller.excludedActivityTypes = excludedActivityTypes
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
