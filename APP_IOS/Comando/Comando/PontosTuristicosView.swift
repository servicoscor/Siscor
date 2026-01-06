import SwiftUI
import MapKit

// MARK: - Modelo Expandido
enum CategoriaPonto: String, CaseIterable {
    case todos = "Todos"
    case patrimonio = "Patrimônio"
    case praia = "Praia"
    case parque = "Parque"
    case museu = "Museu"
    case cultura = "Cultura"
    case esporte = "Esporte"
    case arte = "Arte"
    case biblioteca = "Biblioteca"
    case mirante = "Mirante"
    
    func displayName(localizationManager: LocalizationManager) -> String {
        switch self {
        case .todos: return localizationManager.string(for: "category_all")
        case .patrimonio: return localizationManager.string(for: "category_heritage")
        case .praia: return localizationManager.string(for: "category_beach")
        case .parque: return localizationManager.string(for: "category_park")
        case .museu: return localizationManager.string(for: "category_museum")
        case .cultura: return localizationManager.string(for: "category_culture")
        case .esporte: return localizationManager.string(for: "category_sports")
        case .arte: return localizationManager.string(for: "category_art")
        case .biblioteca: return localizationManager.string(for: "category_library")
        case .mirante: return localizationManager.string(for: "category_viewpoint")
        }
    }
    
    var icone: String {
        switch self {
        case .todos: return "square.grid.2x2"
        case .patrimonio: return "building.columns"
        case .praia: return "beach.umbrella"
        case .parque: return "leaf"
        case .museu: return "building.2"
        case .cultura: return "theatermasks"
        case .esporte: return "sportscourt"
        case .arte: return "paintbrush"
        case .biblioteca: return "books.vertical"
        case .mirante: return "binoculars"
        }
    }
    
    var cor: Color {
        switch self {
        case .todos: return .gray
        case .patrimonio: return .orange
        case .praia: return .blue
        case .parque: return .green
        case .museu: return .purple
        case .cultura: return .red
        case .esporte: return .indigo
        case .arte: return .pink
        case .biblioteca: return .brown
        case .mirante: return .teal
        }
    }
}
// MARK: - View Principal Aprimorada
struct PontosTuristicosView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = PontosTuristicosViewModel()
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var searchText = ""
    @State private var selectedCategoria: CategoriaPonto = .todos
    @State private var showingFilters = false
    @State private var showingMap = false
    
    var pontosFiltrados: [PontoTuristico] {
        viewModel.pontos
            .filter { ponto in
                // Filtro de categoria
                if selectedCategoria != .todos && ponto.categoria != selectedCategoria {
                    return false
                }
                
                // Filtro de busca
                if !searchText.isEmpty {
                    let searchLower = searchText.lowercased()
                    let currentLanguage = localizationManager.currentLanguage
                    
                    // Busca nos textos localizados
                    let nomeMatch = ponto.nome.text(for: currentLanguage).lowercased().contains(searchLower)
                    let textoMatch = ponto.texto.text(for: currentLanguage).lowercased().contains(searchLower)
                    let enderecoMatch = ponto.endereco.lowercased().contains(searchLower)
                    
                    return nomeMatch || textoMatch || enderecoMatch
                }
                
                return true
            }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundView
                
                VStack(spacing: 0) {
                    headerView
                    contentView
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingMap) {
                MapaGeralView(pontos: pontosFiltrados)
            }
        }
        .task {
            await viewModel.loadPontosTuristicos()
        }
    }
    
    // MARK: - Subviews
    
    private var backgroundView: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.05, green: 0.1, blue: 0.2),
                Color(red: 0.1, green: 0.2, blue: 0.3)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    private var headerView: some View {
        VStack(spacing: 12) {
            topBarView
            searchBarView
            categoriesScrollView
        }
        .padding()
        .background(.thinMaterial)
    }
    
    private var topBarView: some View {
        HStack {
            Text(localizationManager.string(for: "tourist_spots"))
                .font(.title3.bold())
                .foregroundColor(.primary)
            
            Spacer()
            
            menuButton
            closeButton
        }
    }
    
    private var menuButton: some View {
        Menu {
            Button(action: { showingMap = true }) {
                Label(localizationManager.string(for: "view_all_on_map"), systemImage: "map")
            }
            
            Button(action: shareAllContent) {
                Label(localizationManager.string(for: "share_list"), systemImage: "square.and.arrow.up")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.body.weight(.medium))
                .foregroundColor(.primary)
                .padding(8)
                .background(Color(.systemGray5))
                .clipShape(Circle())
        }
    }
    
    private var closeButton: some View {
        Button(action: { dismiss() }) {
            Image(systemName: "xmark")
                .font(.body.weight(.bold))
                .foregroundColor(.white.opacity(0.8))
                .padding(8)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
        }
    }
    
    private var searchBarView: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField(localizationManager.string(for: "search_tourist_spots"), text: $searchText)
                .autocapitalization(.none)
            
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
    }
    
    private var categoriesScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(CategoriaPonto.allCases, id: \.self) { categoria in
                    CategoryFilterChip(
                        categoria: categoria,
                        isSelected: selectedCategoria == categoria,
                        action: { selectedCategoria = categoria }
                    )
                }
            }
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading {
            VStack(spacing: 12) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.orange)
                Text(localizationManager.string(for: "loading_tourist_spots"))
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding()
        } else if pontosFiltrados.isEmpty {
            EmptyStateView(
                icon: "map.fill",
                message: searchText.isEmpty ?
                    localizationManager.string(for: "no_tourist_spots_available") :
                    String(format: localizationManager.string(for: "no_results_found_for"), searchText)
            )
        } else {
            pontosList
        }
    }
    
    private var pontosList: some View {
        ScrollView {
            VStack(spacing: 16) {
                resultsHeader
                
                ForEach(pontosFiltrados, id: \.id) { ponto in
                    NavigationLink(destination: PontoTuristicoDetailView(ponto: ponto)) {
                        PontoTuristicoCard(ponto: ponto)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.vertical)
        }
    }
    
    private var resultsHeader: some View {
        HStack {
            Text(String(format: localizationManager.string(for: "points_found"), pontosFiltrados.count))
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            
            Spacer()
            
            Button(action: { showingMap = true }) {
                Label(localizationManager.string(for: "view_on_map"), systemImage: "map")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Functions
    
    private func shareAllContent() {
        let currentLanguage = localizationManager.currentLanguage
        let intro = localizationManager.string(for: "tourist_spots_rio")
        let texto = pontosFiltrados.map { ponto in
            let nome = ponto.nome.text(for: currentLanguage)
            let descricao = ponto.texto.text(for: currentLanguage)
            return "\(nome)\n\(ponto.endereco)\n\(descricao)"
        }.joined(separator: "\n\n---\n\n")
        
        let av = UIActivityViewController(
            activityItems: ["\(intro):\n\n\(texto)"],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(av, animated: true)
        }
    }
}

// MARK: - Chip de Filtro de Categoria
struct CategoryFilterChip: View {
    let categoria: CategoriaPonto
    let isSelected: Bool
    let action: () -> Void
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: categoria.icone)
                    .font(.caption)
                
                Text(categoria.displayName(localizationManager: localizationManager))
                    .font(.caption.weight(.medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                isSelected ? categoria.cor : Color.white.opacity(0.1)
            )
            .foregroundColor(isSelected ? .white : .white.opacity(0.8))
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(isSelected ? Color.clear : Color.white.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

// MARK: - Tag de Informação
struct InfoTag: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption2)
        }
        .foregroundColor(.white.opacity(0.7))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Botão de Ação
struct ActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.caption2)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color)
            .cornerRadius(12)
        }
    }
}

// MARK: - Seção de Informação
struct InfoSection: View {
    let icon: String
    let title: String
    let content: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            Text(content)
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Preview do Mapa
struct MapPreview: View {
    let coordinate: CLLocationCoordinate2D
    let nome: String
    @StateObject private var localizationManager = LocalizationManager.shared
    
    @State private var region: MKCoordinateRegion
    
    init(coordinate: CLLocationCoordinate2D, nome: String) {
        self.coordinate = coordinate
        self.nome = nome
        self._region = State(initialValue: MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }
    
    var body: some View {
        Map(coordinateRegion: $region, annotationItems: [MapPin(coordinate: coordinate, nome: nome)]) { item in
            MapMarker(coordinate: item.coordinate, tint: .red)
        }
        .disabled(true)
        .overlay(
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text(localizationManager.string(for: "tap_to_expand"))
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(20)
                        .padding()
                }
            }
        )
    }
}

// MARK: - Estrutura para Anotações do Mapa
struct MapPin: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let nome: String
}

// MARK: - Card Aprimorado
struct PontoTuristicoCard: View {
    let ponto: PontoTuristico
    @StateObject private var localizationManager = LocalizationManager.shared
    
    private var nome: String {
        ponto.nome.text(for: localizationManager.currentLanguage)
    }
    
    private var texto: String {
        ponto.texto.text(for: localizationManager.currentLanguage)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Ícone da categoria
                Image(systemName: ponto.categoria.icone)
                    .font(.title2)
                    .foregroundColor(ponto.categoria.cor)
                    .frame(width: 40, height: 40)
                    .background(ponto.categoria.cor.opacity(0.2))
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(nome)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(ponto.endereco)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Indicador de navegação
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Text(texto)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            // Tags de informação
            HStack(spacing: 8) {
                if ponto.coordenadas != nil {
                    InfoTag(icon: "location", text: localizationManager.string(for: "map"))
                }
                
                if let avaliacao = ponto.avaliacao {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                        Text(String(format: "%.1f", avaliacao))
                            .font(.caption2.weight(.medium))
                    }
                    .foregroundColor(.yellow)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.yellow.opacity(0.2))
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(ponto.categoria.cor.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }
}

// MARK: - Tela de Detalhes
struct PontoTuristicoDetailView: View {
    let ponto: PontoTuristico
    @Environment(\.dismiss) private var dismiss
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var showingMap = false
    @State private var showingShare = false
    
    private var nome: String {
        ponto.nome.text(for: localizationManager.currentLanguage)
    }
    
    private var texto: String {
        ponto.texto.text(for: localizationManager.currentLanguage)
    }
    
    var body: some View {
        ZStack {
            backgroundView
            
            VStack(spacing: 0) {
                headerView
                contentView
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingMap) {
            if let coordenadas = ponto.coordenadas {
                MapaDetalhesView(ponto: ponto, coordinate: coordenadas)
            }
        }
    }
    
    // MARK: - Subviews
    
    private var backgroundView: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.05, green: 0.1, blue: 0.2),
                Color(red: 0.1, green: 0.2, blue: 0.3)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .foregroundColor(.primary)
                        .padding(8)
                        .background(Color(.systemGray5))
                        .clipShape(Circle())
                }
                
                Text(nome)
                    .font(.title3.bold())
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Spacer()
                
                menuButton
            }
        }
        .padding()
        .background(.thinMaterial)
    }
    
    private var menuButton: some View {
        Menu {
            Button(action: { showingMap = true }) {
                Label(localizationManager.string(for: "view_on_map"), systemImage: "map")
            }
            .disabled(ponto.coordenadas == nil)
            
            if let telefone = ponto.telefone {
                Button(action: callPhone) {
                    Label(localizationManager.string(for: "call"), systemImage: "phone")
                }
            }
            
            if let website = ponto.website {
                Button(action: openWebsite) {
                    Label(localizationManager.string(for: "website"), systemImage: "safari")
                }
            }
            
            Button(action: sharePonto) {
                Label(localizationManager.string(for: "share"), systemImage: "square.and.arrow.up")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.body.weight(.medium))
                .foregroundColor(.primary)
                .padding(8)
                .background(Color(.systemGray5))
                .clipShape(Circle())
        }
    }
    
    private var contentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header com imagem
                ZStack(alignment: .bottomLeading) {
                    // Placeholder para imagem
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [ponto.categoria.cor, ponto.categoria.cor.opacity(0.6)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 250)
                        .overlay(
                            Image(systemName: ponto.categoria.icone)
                                .font(.system(size: 80))
                                .foregroundColor(.white.opacity(0.3))
                        )
                    
                    // Gradiente overlay
                    LinearGradient(
                        gradient: Gradient(colors: [.clear, .black.opacity(0.7)]),
                        startPoint: .center,
                        endPoint: .bottom
                    )
                    
                    // Título
                    VStack(alignment: .leading, spacing: 4) {
                        Text(ponto.categoria.displayName(localizationManager: localizationManager))
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(ponto.categoria.cor)
                            .cornerRadius(12)
                        
                        Text(nome)
                            .font(.largeTitle.bold())
                            .foregroundColor(.white)
                    }
                    .padding()
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    // Ações rápidas
                    HStack(spacing: 12) {
                        ActionButton(
                            icon: "map",
                            title: localizationManager.string(for: "view_on_map"),
                            color: .blue,
                            action: { showingMap = true }
                        )
                        .disabled(ponto.coordenadas == nil)
                        
                        ActionButton(
                            icon: "phone",
                            title: localizationManager.string(for: "call"),
                            color: .green,
                            action: callPhone
                        )
                        .disabled(ponto.telefone == nil)
                        
                        ActionButton(
                            icon: "safari",
                            title: localizationManager.string(for: "website"),
                            color: .orange,
                            action: openWebsite
                        )
                        .disabled(ponto.website == nil)
                        
                        ActionButton(
                            icon: "square.and.arrow.up",
                            title: localizationManager.string(for: "share"),
                            color: .purple,
                            action: sharePonto
                        )
                    }
                    .padding(.horizontal)
                    
                    // Informações
                    VStack(alignment: .leading, spacing: 16) {
                        InfoSection(
                            icon: "location.circle.fill",
                            title: localizationManager.string(for: "address"),
                            content: ponto.endereco,
                            color: .blue
                        )
                        
                        InfoSection(
                            icon: "text.alignleft.circle.fill",
                            title: localizationManager.string(for: "description"),
                            content: texto,
                            color: .purple
                        )
                    }
                    .padding(.horizontal)
                    
                    // Mapa inline
                    if let coordenadas = ponto.coordenadas {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(localizationManager.string(for: "location"))
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            MapPreview(coordinate: coordenadas, nome: nome)
                                .frame(height: 200)
                                .cornerRadius(12)
                                .padding(.horizontal)
                                .onTapGesture {
                                    showingMap = true
                                }
                        }
                    }
                }
            }
        }
    }
    
    
    private func callPhone() {
        guard let telefone = ponto.telefone,
              let url = URL(string: "tel://\(telefone.replacingOccurrences(of: " ", with: ""))") else { return }
        UIApplication.shared.open(url)
    }
    
    private func openWebsite() {
        guard let website = ponto.website,
              let url = URL(string: website) else { return }
        UIApplication.shared.open(url)
    }
    
    private func sharePonto() {
        var shareText = "\(nome)\n"
        shareText += "\n\(localizationManager.string(for: "address")): \(ponto.endereco)"
        shareText += "\n\n\(texto)"
        
        let av = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(av, animated: true)
        }
    }
}

// MARK: - Mapa Detalhado
struct MapaDetalhesView: View {
    let ponto: PontoTuristico
    let coordinate: CLLocationCoordinate2D
    @Environment(\.dismiss) private var dismiss
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var region: MKCoordinateRegion
    
    private var nome: String {
        ponto.nome.text(for: localizationManager.currentLanguage)
    }
    
    init(ponto: PontoTuristico, coordinate: CLLocationCoordinate2D) {
        self.ponto = ponto
        self.coordinate = coordinate
        self._region = State(initialValue: MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        ))
    }
    
    var body: some View {
        ZStack {
            Map(coordinateRegion: $region, annotationItems: [MapPin(coordinate: coordinate, nome: nome)]) { item in
                MapAnnotation(coordinate: item.coordinate) {
                    VStack {
                        Image(systemName: ponto.categoria.icone)
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(ponto.categoria.cor)
                            .clipShape(Circle())
                        
                        Image(systemName: "triangle.fill")
                            .font(.caption)
                            .foregroundColor(ponto.categoria.cor)
                            .offset(y: -5)
                    }
                }
            }
            .ignoresSafeArea()
            
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text(nome)
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(8)
                        
                    
                    }
                }
                .padding()
                
                Spacer()
            }
        }
    }
    
    private func openInMaps() {
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = nome
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}

// MARK: - Mapa Geral
struct MapaGeralView: View {
    let pontos: [PontoTuristico]
    @Environment(\.dismiss) private var dismiss
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -22.9068, longitude: -43.1729),
        span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
    )
    
    var mapPins: [MapPin] {
        let currentLanguage = localizationManager.currentLanguage
        return pontos.compactMap { ponto in
            guard let coord = ponto.coordenadas else { return nil }
            return MapPin(coordinate: coord, nome: ponto.nome.text(for: currentLanguage))
        }
    }
    
    var body: some View {
        NavigationView {
            Map(coordinateRegion: $region, annotationItems: mapPins) { item in
                MapMarker(coordinate: item.coordinate, tint: .red)
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
                    Text(localizationManager.string(for: "all_points"))
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
        }
    }
}
// MARK: - Estrutura para Anotações do Mapa


// MARK: - ViewModel Atualizado
@MainActor
class PontosTuristicosViewModel: ObservableObject {
    @Published var pontos: [PontoTuristico] = []
    @Published var isLoading = false
    
    func loadPontosTuristicos() async {
        isLoading = true
        
        // Por enquanto, usa dados de exemplo com coordenadas
        self.pontos = getExemplosPontosTuristicos()
        
        isLoading = false
    }
    
    private func getExemplosPontosTuristicos() -> [PontoTuristico] {
        // Mantém os dados hardcoded como estão
        return [
            // PATRIMÔNIO
            PontoTuristico(
                id: "1",
                nome: LocalizedText(
                    pt: "Cristo Redentor",
                    en: "Christ the Redeemer",
                    es: "Cristo Redentor",
                    fr: "Christ Rédempteur",
                    zh: "救世基督像"
                ),
                categoria: .patrimonio,
                texto: LocalizedText(
                    pt: "Uma das sete maravilhas do mundo moderno, o Cristo Redentor é o cartão postal mais famoso do Rio de Janeiro. A estátua art déco de Jesus Cristo fica no topo do Corcovado, a 709 metros de altitude.",
                    en: "One of the seven wonders of the modern world, Christ the Redeemer is Rio de Janeiro's most famous postcard. The art deco statue of Jesus Christ sits atop Corcovado mountain at 709 meters altitude.",
                    es: "Una de las siete maravillas del mundo moderno, el Cristo Redentor es la postal más famosa de Río de Janeiro. La estatua art déco de Jesucristo se encuentra en la cima del Corcovado, a 709 metros de altitud.",
                    fr: "L'une des sept merveilles du monde moderne, le Christ Rédempteur est la carte postale la plus célèbre de Rio de Janeiro. La statue art déco de Jésus-Christ se trouve au sommet du Corcovado, à 709 mètres d'altitude.",
                    zh: "作为现代世界七大奇迹之一，救世基督像是里约热内卢最著名的地标。这座装饰艺术风格的耶稣基督雕像坐落在科尔科瓦多山顶，海拔709米。"
                ),
                endereco: "Parque Nacional da Tijuca - Alto da Boa Vista, Rio de Janeiro",
                telefone: "(21) 2558-1329",
                website: "https://cristoredentoroficial.com.br",
                coordenadas: CLLocationCoordinate2D(latitude: -22.9519, longitude: -43.2105),
                avaliacao: 4.8
            ),
            
            PontoTuristico(
                id: "2",
                nome: LocalizedText(
                    pt: "Escadaria Selarón",
                    en: "Selarón Steps",
                    es: "Escalera de Selarón",
                    fr: "Escalier Selarón",
                    zh: "塞勒隆阶梯"
                ),
                categoria: .patrimonio,
                texto: LocalizedText(
                    pt: "Obra do artista chileno Jorge Selarón, a escadaria conecta os bairros da Lapa e Santa Teresa com seus 215 degraus cobertos por mais de 2000 azulejos de mais de 60 países.",
                    en: "Created by Chilean artist Jorge Selarón, the stairway connects the Lapa and Santa Teresa neighborhoods with its 215 steps covered by over 2000 tiles from more than 60 countries.",
                    es: "Obra del artista chileno Jorge Selarón, la escalera conecta los barrios de Lapa y Santa Teresa con sus 215 peldaños cubiertos por más de 2000 azulejos de más de 60 países.",
                    fr: "Œuvre de l'artiste chilien Jorge Selarón, l'escalier relie les quartiers de Lapa et Santa Teresa avec ses 215 marches couvertes de plus de 2000 carreaux de plus de 60 pays.",
                    zh: "由智利艺术家豪尔赫·塞拉隆创作，这个阶梯连接了拉帕和圣特雷莎社区，215级台阶上覆盖着来自60多个国家的2000多块瓷砖。"
                ),
                endereco: "R. Joaquim Silva, S/N - Lapa, Rio de Janeiro",
                telefone: nil,
                website: nil,
                coordenadas: CLLocationCoordinate2D(latitude: -22.9152, longitude: -43.1795),
                avaliacao: 4.6
            ),
            
            // ... (restante dos dados permanece igual)
        ]
    }
}

import MapKit

// MARK: - Estrutura para textos localizados
struct LocalizedText {
    let pt: String
    let en: String
    let es: String
    let fr: String
    let zh: String
    
    func text(for language: String) -> String {
        switch language {
        case "en": return en
        case "es": return es
        case "fr": return fr
        case "zh": return zh
        default: return pt
        }
    }
}
