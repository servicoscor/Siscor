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
                .background(VisualEffectBlur(blurStyle: .systemUltraThinMaterialDark))
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
            LoadingView(message: localizationManager.string(for: "loading_tourist_spots"))
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
            
            // NOVOS PONTOS ADICIONADOS (46-60)
            
            // PATRIMÔNIO
            PontoTuristico(
                id: "46",
                nome: LocalizedText(
                    pt: "Mosteiro de São Bento",
                    en: "São Bento Monastery",
                    es: "Monasterio de São Bento",
                    fr: "Monastère de São Bento",
                    zh: "圣本笃修道院"
                ),
                categoria: .patrimonio,
                texto: LocalizedText(
                    pt: "Fundado em 1590, é uma joia do barroco brasileiro. Interior ricamente decorado com talha dourada. Missas com canto gregoriano aos domingos atraem multidões.",
                    en: "Founded in 1590, it's a jewel of Brazilian baroque. Richly decorated interior with golden carvings. Sunday masses with Gregorian chants attract crowds.",
                    es: "Fundado en 1590, es una joya del barroco brasileño. Interior ricamente decorado con talla dorada. Misas con canto gregoriano los domingos atraen multitudes.",
                    fr: "Fondé en 1590, c'est un joyau du baroque brésilien. Intérieur richement décoré de sculptures dorées. Les messes du dimanche avec chants grégoriens attirent les foules.",
                    zh: "建于1590年，是巴西巴洛克艺术的瑰宝。内部装饰华丽，有镀金雕刻。周日的格里高利圣歌弥撒吸引大量人群。"
                ),
                endereco: "R. Dom Gerardo, 68 - Centro, Rio de Janeiro",
                telefone: "(21) 2206-8100", website: nil,
                coordenadas: CLLocationCoordinate2D(latitude: -22.8969, longitude: -43.1786),
                avaliacao: 4.7
            ),
            
            // MAIS PONTOS ADICIONADOS (61-75)
            
            // PATRIMÔNIO
            PontoTuristico(
                id: "61",
                nome: LocalizedText(
                    pt: "Igreja da Candelária",
                    en: "Candelária Church",
                    es: "Iglesia de la Candelaria",
                    fr: "Église de la Candelária",
                    zh: "坎德拉里亚教堂"
                ),
                categoria: .patrimonio,
                texto: LocalizedText(
                    pt: "Igreja barroca iniciada em 1609. Interior suntuoso com pinturas no teto e cúpula neoclássica. Palco de importantes eventos históricos e religiosos.",
                    en: "Baroque church started in 1609. Sumptuous interior with ceiling paintings and neoclassical dome. Stage of important historical and religious events.",
                    es: "Iglesia barroca iniciada en 1609. Interior suntuoso con pinturas en el techo y cúpula neoclásica. Escenario de importantes eventos históricos y religiosos.",
                    fr: "Église baroque commencée en 1609. Intérieur somptueux avec peintures au plafond et dôme néoclassique. Scène d'événements historiques et religieux importants.",
                    zh: "始建于1609年的巴洛克教堂。奢华的内部装饰，天花板画作和新古典主义圆顶。重要历史和宗教活动的举办地。"
                ),
                endereco: "Praça Pio X - Centro, Rio de Janeiro",
                telefone: "(21) 2233-2324", website: nil,
                coordenadas: CLLocationCoordinate2D(latitude: -22.9017, longitude: -43.1778),
                avaliacao: 4.6
            ),
            
            PontoTuristico(
                id: "62",
                nome: LocalizedText(
                    pt: "Palácio Tiradentes",
                    en: "Tiradentes Palace",
                    es: "Palacio Tiradentes",
                    fr: "Palais Tiradentes",
                    zh: "蒂拉登特斯宫"
                ),
                categoria: .patrimonio,
                texto: LocalizedText(
                    pt: "Sede da Assembleia Legislativa do Rio. Arquitetura eclética de 1926. Nome homenageia o mártir da Inconfidência Mineira. Visitas guiadas gratuitas.",
                    en: "Seat of Rio's Legislative Assembly. Eclectic architecture from 1926. Name honors the martyr of Inconfidência Mineira. Free guided tours.",
                    es: "Sede de la Asamblea Legislativa de Río. Arquitectura ecléctica de 1926. El nombre homenajea al mártir de la Inconfidencia Minera. Visitas guiadas gratuitas.",
                    fr: "Siège de l'Assemblée législative de Rio. Architecture éclectique de 1926. Le nom honore le martyr de l'Inconfidência Mineira. Visites guidées gratuites.",
                    zh: "里约立法议会所在地。1926年的折衷主义建筑。名字是为了纪念米纳斯密谋的烈士。免费导览。"
                ),
                endereco: "R. Primeiro de Março, S/N - Centro, Rio de Janeiro",
                telefone: "(21) 2588-1000", website: nil,
                coordenadas: CLLocationCoordinate2D(latitude: -22.9048, longitude: -43.1744),
                avaliacao: 4.4
            ),
            
            // PRAIAS
            PontoTuristico(
                id: "63",
                nome: LocalizedText(
                    pt: "Praia da Reserva",
                    en: "Reserva Beach",
                    es: "Playa de la Reserva",
                    fr: "Plage de la Réserve",
                    zh: "保护区海滩"
                ),
                categoria: .praia,
                texto: LocalizedText(
                    pt: "Praia selvagem e preservada na Barra. 8 km de extensão com dunas e vegetação de restinga. Área de proteção ambiental com tartarugas marinhas.",
                    en: "Wild and preserved beach in Barra. 8 km long with dunes and restinga vegetation. Environmental protection area with sea turtles.",
                    es: "Playa salvaje y preservada en Barra. 8 km de extensión con dunas y vegetación de restinga. Área de protección ambiental con tortugas marinas.",
                    fr: "Plage sauvage et préservée à Barra. 8 km de long avec dunes et végétation de restinga. Zone de protection environnementale avec tortues marines.",
                    zh: "巴拉的野生保护海滩。8公里长，有沙丘和海岸植被。海龟环境保护区。"
                ),
                endereco: "Av. Lúcio Costa - Recreio dos Bandeirantes, Rio de Janeiro",telefone: nil, website: nil,
                coordenadas: CLLocationCoordinate2D(latitude: -23.0178, longitude: -43.3897),
                avaliacao: 4.7
            ),
            
            PontoTuristico(
                id: "64",
                nome: LocalizedText(
                    pt: "Praia de Grumari",
                    en: "Grumari Beach",
                    es: "Playa de Grumari",
                    fr: "Plage de Grumari",
                    zh: "格鲁马里海滩"
                ),
                categoria: .praia,
                texto: LocalizedText(
                    pt: "Praia selvagem dentro de área de proteção ambiental. Águas cristalinas e areias brancas. Paraíso para surfistas e amantes da natureza intocada.",
                    en: "Wild beach within environmental protection area. Crystal clear waters and white sands. Paradise for surfers and untouched nature lovers.",
                    es: "Playa salvaje dentro de área de protección ambiental. Aguas cristalinas y arenas blancas. Paraíso para surfistas y amantes de la naturaleza intacta.",
                    fr: "Plage sauvage dans une zone de protection environnementale. Eaux cristallines et sables blancs. Paradis pour les surfeurs et amoureux de la nature intacte.",
                    zh: "环境保护区内的野生海滩。水晶般清澈的海水和白色沙滩。冲浪者和原始自然爱好者的天堂。"
                ),
                endereco: "Estrada de Grumari - Grumari, Rio de Janeiro",telefone: nil, website: nil,
                coordenadas: CLLocationCoordinate2D(latitude: -23.0467, longitude: -43.5239),
                avaliacao: 4.8
            ),
            
            // PARQUES
            PontoTuristico(
                id: "65",
                nome: LocalizedText(
                    pt: "Parque Natural Municipal de Marapendi",
                    en: "Marapendi Municipal Natural Park",
                    es: "Parque Natural Municipal de Marapendi",
                    fr: "Parc Naturel Municipal de Marapendi",
                    zh: "马拉彭迪市立自然公园"
                ),
                categoria: .parque,
                texto: LocalizedText(
                    pt: "Reserva de 155 hectares com manguezais e restinga. Rica fauna com jacarés, capivaras e aves. Trilhas ecológicas e mirante sobre a lagoa.",
                    en: "155-hectare reserve with mangroves and restinga. Rich fauna with alligators, capybaras and birds. Ecological trails and viewpoint over the lagoon.",
                    es: "Reserva de 155 hectáreas con manglares y restinga. Rica fauna con caimanes, capibaras y aves. Senderos ecológicos y mirador sobre la laguna.",
                    fr: "Réserve de 155 hectares avec mangroves et restinga. Faune riche avec alligators, capybaras et oiseaux. Sentiers écologiques et belvédère sur le lagon.",
                    zh: "155公顷的保护区，有红树林和海岸植被。丰富的动物群，包括鳄鱼、水豚和鸟类。生态步道和湖泊观景台。"
                ),
                endereco: "Av. Alfredo Baltazar da Silveira - Recreio dos Bandeirantes, Rio de Janeiro",telefone: nil, website: nil,
                coordenadas: CLLocationCoordinate2D(latitude: -23.0089, longitude: -43.3372),
                avaliacao: 4.3
            ),
            
            PontoTuristico(
                id: "66",
                nome: LocalizedText(
                    pt: "Sítio Roberto Burle Marx",
                    en: "Roberto Burle Marx Site",
                    es: "Sitio Roberto Burle Marx",
                    fr: "Site Roberto Burle Marx",
                    zh: "罗伯托·布尔勒·马克思庄园"
                ),
                categoria: .parque,
                texto: LocalizedText(
                    pt: "Casa e jardins do paisagista Burle Marx. Coleção com 3.500 espécies de plantas tropicais. Patrimônio Nacional com visitas guiadas obrigatórias.",
                    en: "House and gardens of landscaper Burle Marx. Collection with 3,500 tropical plant species. National Heritage with mandatory guided tours.",
                    es: "Casa y jardines del paisajista Burle Marx. Colección con 3.500 especies de plantas tropicales. Patrimonio Nacional con visitas guiadas obligatorias.",
                    fr: "Maison et jardins du paysagiste Burle Marx. Collection de 3 500 espèces de plantes tropicales. Patrimoine national avec visites guidées obligatoires.",
                    zh: "景观设计师布尔勒·马克思的房屋和花园。收藏了3500种热带植物。国家遗产，必须参加导览。"
                ),
                endereco: "Estrada Roberto Burle Marx, 2019 - Barra de Guaratiba, Rio de Janeiro",
                telefone: "(21) 2410-1412",website: nil,
                coordenadas: CLLocationCoordinate2D(latitude: -23.0142, longitude: -43.6411),
                avaliacao: 4.8
            ),
            
            // MUSEUS
            PontoTuristico(
                id: "67",
                nome: LocalizedText(
                    pt: "Museu Casa de Rui Barbosa",
                    en: "Rui Barbosa House Museum",
                    es: "Museo Casa de Rui Barbosa",
                    fr: "Musée Maison de Rui Barbosa",
                    zh: "鲁伊·巴尔博萨故居博物馆"
                ),
                categoria: .museu,
                texto: LocalizedText(
                    pt: "Casa do jurista e escritor Rui Barbosa. Biblioteca com 35 mil volumes e jardim histórico. Mobiliário e objetos pessoais preservados do início do século XX.",
                    en: "House of jurist and writer Rui Barbosa. Library with 35,000 volumes and historic garden. Preserved furniture and personal objects from early 20th century.",
                    es: "Casa del jurista y escritor Rui Barbosa. Biblioteca con 35 mil volúmenes y jardín histórico. Mobiliario y objetos personales preservados del inicio del siglo XX.",
                    fr: "Maison du juriste et écrivain Rui Barbosa. Bibliothèque de 35 000 volumes et jardin historique. Mobilier et objets personnels préservés du début du XXe siècle.",
                    zh: "法学家和作家鲁伊·巴尔博萨的故居。拥有3.5万册藏书的图书馆和历史花园。保存了20世纪初的家具和个人物品。"
                ),
                endereco: "R. São Clemente, 134 - Botafogo, Rio de Janeiro",
                telefone: "(21) 3289-4600",
                website: "http://www.casaruibarbosa.gov.br",
                coordenadas: CLLocationCoordinate2D(latitude: -22.9449, longitude: -43.1836),
                avaliacao: 4.5
            ),
            
            // MAIS 25 PONTOS ADICIONADOS (76-100)
            
            // PATRIMÔNIO
            PontoTuristico(
                id: "76",
                nome: LocalizedText(
                    pt: "Igreja de Nossa Senhora da Glória do Outeiro",
                    en: "Our Lady of Glory Church",
                    es: "Iglesia de Nuestra Señora de la Gloria",
                    fr: "Église Notre-Dame de la Gloire",
                    zh: "荣耀圣母教堂"
                ),
                categoria: .patrimonio,
                texto: LocalizedText(
                    pt: "Joia do barroco brasileiro de 1739. Igreja predileta da família imperial onde foram batizados D. Pedro II e a Princesa Isabel. Vista panorâmica da baía.",
                    en: "Brazilian baroque jewel from 1739. Imperial family's favorite church where D. Pedro II and Princess Isabel were baptized. Panoramic bay view.",
                    es: "Joya del barroco brasileño de 1739. Iglesia predilecta de la familia imperial donde fueron bautizados D. Pedro II y la Princesa Isabel. Vista panorámica de la bahía.",
                    fr: "Joyau du baroque brésilien de 1739. Église préférée de la famille impériale où furent baptisés D. Pedro II et la Princesse Isabel. Vue panoramique sur la baie.",
                    zh: "1739年的巴西巴洛克珍宝。帝国家族最喜爱的教堂，佩德罗二世和伊莎贝尔公主在此受洗。海湾全景。"
                ),
                endereco: "Praça Nossa Senhora da Glória - Glória, Rio de Janeiro",
                telefone: "(21) 2225-2869",website: nil,
                coordenadas: CLLocationCoordinate2D(latitude: -22.9249, longitude: -43.1743),
                avaliacao: 4.7
            ),
            
            PontoTuristico(
                id: "77",
                nome: LocalizedText(
                    pt: "Paço Imperial",
                    en: "Imperial Palace",
                    es: "Palacio Imperial",
                    fr: "Palais Impérial",
                    zh: "帝国宫殿"
                ),
                categoria: .patrimonio,
                texto: LocalizedText(
                    pt: "Antiga residência dos governadores e da família real. Marco da proclamação da independência. Centro cultural com exposições e eventos históricos.",
                    en: "Former residence of governors and royal family. Independence proclamation landmark. Cultural center with exhibitions and historical events.",
                    es: "Antigua residencia de gobernadores y familia real. Marco de la proclamación de independencia. Centro cultural con exposiciones y eventos históricos.",
                    fr: "Ancienne résidence des gouverneurs et de la famille royale. Lieu de proclamation de l'indépendance. Centre culturel avec expositions et événements historiques.",
                    zh: "前总督和皇室住所。独立宣言地标。设有展览和历史活动的文化中心。"
                ),
                endereco: "Praça XV de Novembro, 48 - Centro, Rio de Janeiro",
                telefone: "(21) 2215-2093",website: nil,
                coordenadas: CLLocationCoordinate2D(latitude: -22.9033, longitude: -43.1742),
                avaliacao: 4.5
            ),
            
            PontoTuristico(
                id: "78",
                nome: LocalizedText(
                    pt: "Solar Grandjean de Montigny",
                    en: "Grandjean de Montigny Solar",
                    es: "Solar Grandjean de Montigny",
                    fr: "Solar Grandjean de Montigny",
                    zh: "格朗让·德·蒙蒂尼庄园"
                ),
                categoria: .patrimonio,
                texto: LocalizedText(
                    pt: "Casa do arquiteto francês da Missão Artística. Centro Cultural da PUC-Rio com exposições de arte. Arquitetura neoclássica em meio aos jardins.",
                    en: "House of the French architect from the Artistic Mission. PUC-Rio Cultural Center with art exhibitions. Neoclassical architecture amid gardens.",
                    es: "Casa del arquitecto francés de la Misión Artística. Centro Cultural de PUC-Rio con exposiciones de arte. Arquitectura neoclásica en medio de jardines.",
                    fr: "Maison de l'architecte français de la Mission Artistique. Centre Culturel PUC-Rio avec expositions d'art. Architecture néoclassique au milieu des jardins.",
                    zh: "艺术使团法国建筑师的住所。里约天主教大学文化中心，举办艺术展览。花园中的新古典主义建筑。"
                ),
                endereco: "R. Marquês de São Vicente, 225 - Gávea, Rio de Janeiro",
                telefone: "(21) 3527-1001",website: nil,
                coordenadas: CLLocationCoordinate2D(latitude: -22.9789, longitude: -43.2331),
                avaliacao: 4.4
            ),
            
            // PRAIAS
            PontoTuristico(
                id: "79",
                nome: LocalizedText(
                    pt: "Praia do Diabo",
                    en: "Devil's Beach",
                    es: "Playa del Diablo",
                    fr: "Plage du Diable",
                    zh: "魔鬼海滩"
                ),
                categoria: .praia,
                texto: LocalizedText(
                    pt: "Pequena praia entre Ipanema e Copacabana. Acesso por trilha no Arpoador. Piscinas naturais entre as rochas e privacidade única.",
                    en: "Small beach between Ipanema and Copacabana. Access by trail in Arpoador. Natural pools among rocks and unique privacy.",
                    es: "Pequeña playa entre Ipanema y Copacabana. Acceso por sendero en Arpoador. Piscinas naturales entre rocas y privacidad única.",
                    fr: "Petite plage entre Ipanema et Copacabana. Accès par sentier à Arpoador. Piscines naturelles parmi les rochers et intimité unique.",
                    zh: "伊帕内玛和科帕卡巴纳之间的小海滩。通过阿尔波阿多的小径进入。岩石间的天然泳池和独特的私密性。"
                ),
                endereco: "Entre Copacabana e Arpoador - Rio de Janeiro",telefone: nil, website: nil,
                coordenadas: CLLocationCoordinate2D(latitude: -22.9885, longitude: -43.1899),
                avaliacao: 4.6
            ),
            
            PontoTuristico(
                id: "80",
                nome: LocalizedText(
                    pt: "Praia da Macumba",
                    en: "Macumba Beach",
                    es: "Playa de Macumba",
                    fr: "Plage de Macumba",
                    zh: "马昆巴海滩"
                ),
                categoria: .praia,
                texto: LocalizedText(
                    pt: "Praia do Recreio conhecida pelas ondas fortes. Point de surfistas e bodyboarders. Quiosques animados e vida noturna agitada.",
                    en: "Recreio beach known for strong waves. Surfers and bodyboarders spot. Lively kiosks and vibrant nightlife.",
                    es: "Playa de Recreio conocida por las olas fuertes. Punto de surfistas y bodyboarders. Quioscos animados y vida nocturna agitada.",
                    fr: "Plage de Recreio connue pour ses fortes vagues. Spot de surfeurs et bodyboarders. Kiosques animés et vie nocturne vibrante.",
                    zh: "以强浪闻名的雷克雷欧海滩。冲浪者和趴板冲浪者的聚集地。热闹的小摊和充满活力的夜生活。"
                ),
                endereco: "Av. Lúcio Costa - Recreio dos Bandeirantes, Rio de Janeiro",telefone: nil, website: nil,
                coordenadas: CLLocationCoordinate2D(latitude: -23.0311, longitude: -43.4689),
                avaliacao: 4.3
            ),
            
            PontoTuristico(
                id: "81",
                nome: LocalizedText(
                    pt: "Praia do Flamengo",
                    en: "Flamengo Beach",
                    es: "Playa de Flamengo",
                    fr: "Plage de Flamengo",
                    zh: "弗拉门戈海滩"
                ),
                categoria: .praia,
                texto: LocalizedText(
                    pt: "Praia artificial dentro do Parque do Flamengo. Vista para o Pão de Açúcar. Ideal para esportes náuticos como remo e vela.",
                    en: "Artificial beach within Flamengo Park. View of Sugar Loaf. Ideal for water sports like rowing and sailing.",
                    es: "Playa artificial dentro del Parque de Flamengo. Vista al Pan de Azúcar. Ideal para deportes náuticos como remo y vela.",
                    fr: "Plage artificielle dans le Parc du Flamengo. Vue sur le Pain de Sucre. Idéale pour les sports nautiques comme l'aviron et la voile.",
                    zh: "弗拉门戈公园内的人工海滩。糖面包山景观。非常适合划船和帆船等水上运动。"
                ),
                endereco: "Av. Infante Dom Henrique - Flamengo, Rio de Janeiro",telefone: nil, website: nil,
                coordenadas: CLLocationCoordinate2D(latitude: -22.9203, longitude: -43.1724),
                avaliacao: 4.0
            ),
            
            // PARQUES
            PontoTuristico(
                id: "82",
                nome: LocalizedText(
                    pt: "Parque Estadual da Pedra Branca",
                    en: "Pedra Branca State Park",
                    es: "Parque Estatal de Pedra Branca",
                    fr: "Parc d'État de Pedra Branca",
                    zh: "白石州立公园"
                ),
                categoria: .parque,
                texto: LocalizedText(
                    pt: "Maior floresta urbana do mundo com 12.500 hectares. Pico da Pedra Branca é o ponto mais alto da cidade com 1025m. Cachoeiras e fauna exuberante.",
                    en: "World's largest urban forest with 12,500 hectares. Pedra Branca Peak is the city's highest point at 1,025m. Waterfalls and exuberant fauna.",
                    es: "Mayor bosque urbano del mundo con 12.500 hectáreas. El Pico de Pedra Branca es el punto más alto de la ciudad con 1025m. Cascadas y fauna exuberante.",
                    fr: "Plus grande forêt urbaine du monde avec 12 500 hectares. Le Pic de Pedra Branca est le point culminant de la ville à 1 025m. Cascades et faune exubérante.",
                    zh: "世界上最大的城市森林，占地12500公顷。白石峰是城市最高点，海拔1025米。瀑布和丰富的动物群。"
                ),
                endereco: "Estrada do Pau da Fome, 4003 - Jacarepaguá, Rio de Janeiro",
                telefone: "(21) 2332-6608", website: nil,
                coordenadas: CLLocationCoordinate2D(latitude: -22.9319, longitude: -43.4489),
                avaliacao: 4.6
            ),
            
            PontoTuristico(
                id: "83",
                nome: LocalizedText(
                    pt: "Parque Chico Mendes",
                    en: "Chico Mendes Park",
                    es: "Parque Chico Mendes",
                    fr: "Parc Chico Mendes",
                    zh: "奇科·门德斯公园"
                ),
                categoria: .parque,
                texto: LocalizedText(
                    pt: "Área de preservação no Recreio com lagoa e restinga. Nome homenageia o ambientalista assassinado. Jacarés, capivaras e aves nativas.",
                    en: "Preservation area in Recreio with lagoon and restinga. Named after the murdered environmentalist. Alligators, capybaras and native birds.",
                    es: "Área de preservación en Recreio con laguna y restinga. Nombre homenajea al ambientalista asesinado. Caimanes, capibaras y aves nativas.",
                    fr: "Zone de préservation à Recreio avec lagune et restinga. Nommé d'après l'écologiste assassiné. Alligators, capybaras et oiseaux indigènes.",
                    zh: "雷克雷欧的保护区，有泻湖和海岸植被。以被谋杀的环保主义者命名。鳄鱼、水豚和本地鸟类。"
                ),
                endereco: "Av. Jarbas de Carvalho, 679 - Recreio dos Bandeirantes, Rio de Janeiro",telefone: nil, website: nil,
                coordenadas: CLLocationCoordinate2D(latitude: -23.0156, longitude: -43.3231),
                avaliacao: 4.2
            ),
            
            // MUSEUS
            PontoTuristico(
                id: "84",
                nome: LocalizedText(
                    pt: "Museu da Imagem e do Som",
                    en: "Image and Sound Museum",
                    es: "Museo de la Imagen y del Sonido",
                    fr: "Musée de l'Image et du Son",
                    zh: "影像与声音博物馆"
                ),
                categoria: .museu,
                texto: LocalizedText(
                    pt: "Nova sede em Copacabana dedicada à cultura audiovisual brasileira. Acervo de música, cinema e fotografia. Terraço com vista para a praia.",
                    en: "New headquarters in Copacabana dedicated to Brazilian audiovisual culture. Music, cinema and photography collection. Terrace with beach view.",
                    es: "Nueva sede en Copacabana dedicada a la cultura audiovisual brasileña. Acervo de música, cine y fotografía. Terraza con vista a la playa.",
                    fr: "Nouveau siège à Copacabana dédié à la culture audiovisuelle brésilienne. Collection de musique, cinéma et photographie. Terrasse avec vue sur la plage.",
                    zh: "科帕卡巴纳的新总部，致力于巴西视听文化。音乐、电影和摄影收藏。带海滩景观的露台。"
                ),
                endereco: "Av. Atlântica, 3432 - Copacabana, Rio de Janeiro",
                telefone: "(21) 2332-9047",
                website: "http://www.mis.rj.gov.br",
                coordenadas: CLLocationCoordinate2D(latitude: -22.9867, longitude: -43.1903),
                avaliacao: 4.4
            ),
            
            PontoTuristico(
                id: "85",
                nome: LocalizedText(
                    pt: "Museu do Índio",
                    en: "Indian Museum",
                    es: "Museo del Indio",
                    fr: "Musée de l'Indien",
                    zh: "印第安人博物馆"
                ),
                categoria: .museu,
                texto: LocalizedText(
                    pt: "Preserva a cultura indígena brasileira com 15 mil peças. Casa histórica com jardim e loja de artesanato indígena. Programação educativa e cultural.",
                    en: "Preserves Brazilian indigenous culture with 15,000 pieces. Historic house with garden and indigenous craft shop. Educational and cultural programming.",
                    es: "Preserva la cultura indígena brasileña con 15 mil piezas. Casa histórica con jardín y tienda de artesanía indígena. Programación educativa y cultural.",
                    fr: "Préserve la culture indigène brésilienne avec 15 000 pièces. Maison historique avec jardin et boutique d'artisanat indigène. Programmation éducative et culturelle.",
                    zh: "保存巴西原住民文化，拥有15000件藏品。带花园和原住民手工艺品商店的历史建筑。教育和文化活动。"
                ),
                endereco: "R. das Palmeiras, 55 - Botafogo, Rio de Janeiro",
                telefone: "(21) 3214-8702",
                website: "http://www.museudoindio.gov.br",
                coordenadas: CLLocationCoordinate2D(latitude: -22.9508, longitude: -43.1856),
                avaliacao: 4.3
            ),
            
            PontoTuristico(
                id: "86",
                nome: LocalizedText(
                    pt: "Museu Villa-Lobos",
                    en: "Villa-Lobos Museum",
                    es: "Museo Villa-Lobos",
                    fr: "Musée Villa-Lobos",
                    zh: "维拉-洛博斯博物馆"
                ),
                categoria: .museu,
                texto: LocalizedText(
                    pt: "Dedicado ao maior compositor brasileiro. Partituras originais, instrumentos e objetos pessoais. Concertos e atividades musicais regulares.",
                    en: "Dedicated to Brazil's greatest composer. Original scores, instruments and personal objects. Regular concerts and musical activities.",
                    es: "Dedicado al mayor compositor brasileño. Partituras originales, instrumentos y objetos personales. Conciertos y actividades musicales regulares.",
                    fr: "Dédié au plus grand compositeur brésilien. Partitions originales, instruments et objets personnels. Concerts et activités musicales réguliers.",
                    zh: "献给巴西最伟大的作曲家。原始乐谱、乐器和个人物品。定期音乐会和音乐活动。"
                ),
                endereco: "R. Sorocaba, 200 - Botafogo, Rio de Janeiro",
                telefone: "(21) 2266-3845",
                website: "http://museuvillalobos.org.br",
                coordenadas: CLLocationCoordinate2D(latitude: -22.9464, longitude: -43.1811),
                avaliacao: 4.5
            ),
            
            // CULTURA
            PontoTuristico(
                id: "87",
                nome: LocalizedText(
                    pt: "Teatro João Caetano",
                    en: "João Caetano Theater",
                    es: "Teatro João Caetano",
                    fr: "Théâtre João Caetano",
                    zh: "若昂·卡埃塔诺剧院"
                ),
                categoria: .cultura,
                texto: LocalizedText(
                    pt: "Mais antigo teatro em funcionamento no Rio desde 1813. Arquitetura neoclássica restaurada. Peças teatrais clássicas e contemporâneas.",
                    en: "Oldest operating theater in Rio since 1813. Restored neoclassical architecture. Classic and contemporary plays.",
                    es: "Teatro más antiguo en funcionamiento en Río desde 1813. Arquitectura neoclásica restaurada. Obras teatrales clásicas y contemporáneas.",
                    fr: "Plus ancien théâtre en activité à Rio depuis 1813. Architecture néoclassique restaurée. Pièces classiques et contemporaines.",
                    zh: "自1813年以来里约最古老的运营剧院。修复的新古典主义建筑。古典和当代戏剧。"
                ),
                endereco: "Praça Tiradentes, S/N - Centro, Rio de Janeiro",
                telefone: "(21) 2332-9166",website: nil,
                coordenadas: CLLocationCoordinate2D(latitude: -22.9067, longitude: -43.1849),
                avaliacao: 4.4
            ),
            
            PontoTuristico(
                id: "88",
                nome: LocalizedText(
                    pt: "Feira de Antiguidades da Praça XV",
                    en: "Praça XV Antiques Fair",
                    es: "Feria de Antigüedades de la Plaza XV",
                    fr: "Foire aux Antiquités de la Place XV",
                    zh: "十五广场古董集市"
                ),
                categoria: .cultura,
                texto: LocalizedText(
                    pt: "Tradicional feira aos sábados desde 1960. Antiguidades, obras de arte, livros raros e curiosidades. Ponto de encontro de colecionadores.",
                    en: "Traditional Saturday fair since 1960. Antiques, artworks, rare books and curiosities. Collectors meeting point.",
                    es: "Tradicional feria los sábados desde 1960. Antigüedades, obras de arte, libros raros y curiosidades. Punto de encuentro de coleccionistas.",
                    fr: "Foire traditionnelle du samedi depuis 1960. Antiquités, œuvres d'art, livres rares et curiosités. Point de rencontre des collectionneurs.",
                    zh: "自1960年以来的传统周六集市。古董、艺术品、珍本书和古玩。收藏家聚会点。"
                ),
                endereco: "Praça XV de Novembro - Centro, Rio de Janeiro",telefone: nil, website: nil,
                coordenadas: CLLocationCoordinate2D(latitude: -22.9029, longitude: -43.1741),
                avaliacao: 4.2
            ),
            
            PontoTuristico(
                id: "89",
                nome: LocalizedText(
                    pt: "Beco do Batman (Rio)",
                    en: "Batman Alley (Rio)",
                    es: "Callejón de Batman (Río)",
                    fr: "Ruelle de Batman (Rio)",
                    zh: "蝙蝠侠小巷（里约）"
                ),
                categoria: .cultura,
                texto: LocalizedText(
                    pt: "Galeria de arte urbana a céu aberto na Lapa. Grafites e murais constantemente renovados. Inspirado no famoso beco paulista.",
                    en: "Open-air urban art gallery in Lapa. Constantly renewed graffiti and murals. Inspired by the famous São Paulo alley.",
                    es: "Galería de arte urbano al aire libre en Lapa. Grafitis y murales constantemente renovados. Inspirado en el famoso callejón paulista.",
                    fr: "Galerie d'art urbain à ciel ouvert à Lapa. Graffitis et fresques constamment renouvelés. Inspiré de la célèbre ruelle de São Paulo.",
                    zh: "拉帕的露天城市艺术画廊。不断更新的涂鸦和壁画。灵感来自著名的圣保罗小巷。"
                ),
                endereco: "R. Teotônio Regadas - Lapa, Rio de Janeiro",telefone: nil, website: nil,
                coordenadas: CLLocationCoordinate2D(latitude: -22.9143, longitude: -43.1811),
                avaliacao: 4.3
            ),
            
            PontoTuristico(
                id: "90",
                nome: LocalizedText(
                    pt: "Centro de Referência do Artesanato Brasileiro",
                    en: "Brazilian Handicraft Reference Center",
                    es: "Centro de Referencia de la Artesanía Brasileña",
                    fr: "Centre de Référence de l'Artisanat Brésilien",
                    zh: "巴西手工艺参考中心"
                ),
                categoria: .cultura,
                texto: LocalizedText(
                    pt: "Vitrine do artesanato nacional no antigo Correios. Peças de todas as regiões do Brasil. Loja, exposições e oficinas de técnicas tradicionais.",
                    en: "National handicraft showcase in the old Post Office. Pieces from all regions of Brazil. Shop, exhibitions and traditional technique workshops.",
                    es: "Vitrina de la artesanía nacional en el antiguo Correos. Piezas de todas las regiones de Brasil. Tienda, exposiciones y talleres de técnicas tradicionales.",
                    fr: "Vitrine de l'artisanat national dans l'ancien bureau de poste. Pièces de toutes les régions du Brésil. Boutique, expositions et ateliers de techniques traditionnelles.",
                    zh: "旧邮局的国家手工艺品展示。来自巴西各地的作品。商店、展览和传统技术工作坊。"
                ),
                endereco: "Praça Tiradentes, 67-79 - Centro, Rio de Janeiro",
                telefone: "(21) 2532-7405",website: nil,
                coordenadas: CLLocationCoordinate2D(latitude: -22.9063, longitude: -43.1846),
                avaliacao: 4.4
            ),
            
            // ESPORTE
            PontoTuristico(
                id: "91",
                nome: LocalizedText(
                    pt: "Piscinão de Ramos",
                    en: "Ramos Swimming Pool",
                    es: "Piscina de Ramos",
                    fr: "Piscine de Ramos",
                    zh: "拉莫斯游泳池"
                ),
                categoria: .esporte,
                texto: LocalizedText(
                    pt: "Praia artificial na zona norte para quem não pode ir às praias da zona sul. Parque aquático popular com eventos culturais e esportivos.",
                    en: "Artificial beach in the north zone for those who can't go to south zone beaches. Popular water park with cultural and sporting events.",
                    es: "Playa artificial en la zona norte para quienes no pueden ir a las playas de la zona sur. Parque acuático popular con eventos culturales y deportivos.",
                    fr: "Plage artificielle dans la zone nord pour ceux qui ne peuvent pas aller aux plages de la zone sud. Parc aquatique populaire avec événements culturels et sportifs.",
                    zh: "北区的人工海滩，为无法前往南区海滩的人而建。举办文化和体育活动的热门水上乐园。"
                ),
                endereco: "Praia de Ramos - Ramos, Rio de Janeiro",telefone: nil, website: nil,
                coordenadas: CLLocationCoordinate2D(latitude: -22.8467, longitude: -43.2478),
                avaliacao: 3.8
            ),
            
            PontoTuristico(
                id: "92",
                nome: LocalizedText(
                    pt: "Clube de Regatas do Flamengo",
                    en: "Flamengo Rowing Club",
                    es: "Club de Regatas Flamengo",
                    fr: "Club de Régates Flamengo",
                    zh: "弗拉门戈划船俱乐部"
                ),
                categoria: .esporte,
                texto: LocalizedText(
                    pt: "Sede do clube mais popular do Brasil. Museu com troféus e história do futebol. Vista para a Baía de Guanabara e espaços esportivos.",
                    en: "Headquarters of Brazil's most popular club. Museum with trophies and football history. Guanabara Bay view and sports facilities.",
                    es: "Sede del club más popular de Brasil. Museo con trofeos e historia del fútbol. Vista a la Bahía de Guanabara y espacios deportivos.",
                    fr: "Siège du club le plus populaire du Brésil. Musée avec trophées et histoire du football. Vue sur la baie de Guanabara et installations sportives.",
                    zh: "巴西最受欢迎俱乐部的总部。展示奖杯和足球历史的博物馆。瓜纳巴拉湾景观和体育设施。"
                ),
                endereco: "Av. Borges de Medeiros, 997 - Lagoa, Rio de Janeiro",
                telefone: "(21) 2159-0100",
                website: "https://www.flamengo.com.br",
                coordenadas: CLLocationCoordinate2D(latitude: -22.9786, longitude: -43.2172),
                avaliacao: 4.5
            ),
            
            // ARTE
            PontoTuristico(
                id: "93",
                nome: LocalizedText(
                    pt: "Museu Internacional de Arte Naïf",
                    en: "International Naïve Art Museum",
                    es: "Museo Internacional de Arte Naïf",
                    fr: "Musée International d'Art Naïf",
                    zh: "国际素人艺术博物馆"
                ),
                categoria: .arte,
                texto: LocalizedText(
                    pt: "Maior coleção de arte naïf do mundo com 8 mil obras. Artistas brasileiros e internacionais. Vista panorâmica do alto do Cosme Velho.",
                    en: "World's largest naïve art collection with 8,000 works. Brazilian and international artists. Panoramic view from Cosme Velho heights.",
                    es: "Mayor colección de arte naïf del mundo con 8 mil obras. Artistas brasileños e internacionales. Vista panorámica desde las alturas de Cosme Velho.",
                    fr: "Plus grande collection d'art naïf au monde avec 8 000 œuvres. Artistes brésiliens et internationaux. Vue panoramique depuis les hauteurs de Cosme Velho.",
                    zh: "世界上最大的素人艺术收藏，拥有8000件作品。巴西和国际艺术家。从科斯梅维略高地的全景。"
                ),
                endereco: "R. Cosme Velho, 561 - Cosme Velho, Rio de Janeiro",
                telefone: "(21) 2285-8332", website: nil,
                coordenadas: CLLocationCoordinate2D(latitude: -22.9423, longitude: -43.2001),
                avaliacao: 4.4
            ),
            
            PontoTuristico(
                id: "94",
                nome: LocalizedText(
                    pt: "Ateliê de Cerâmica Hélio Pellegrino",
                    en: "Hélio Pellegrino Ceramics Studio",
                    es: "Taller de Cerámica Hélio Pellegrino",
                    fr: "Atelier de Céramique Hélio Pellegrino",
                    zh: "埃利奥·佩莱格里诺陶瓷工作室"
                ),
                categoria: .arte,
                texto: LocalizedText(
                    pt: "Espaço público de arte cerâmica com fornos e equipamentos. Cursos gratuitos e exposições. Produção artística comunitária no Parque Lage.",
                    en: "Public ceramic art space with kilns and equipment. Free courses and exhibitions. Community artistic production in Parque Lage.",
                    es: "Espacio público de arte cerámico con hornos y equipos. Cursos gratuitos y exposiciones. Producción artística comunitaria en Parque Lage.",
                    fr: "Espace public d'art céramique avec fours et équipements. Cours gratuits et expositions. Production artistique communautaire au Parque Lage.",
                    zh: "配有窑炉和设备的公共陶瓷艺术空间。免费课程和展览。拉赫公园的社区艺术创作。"
                ),
                endereco: "Parque Lage - Jardim Botânico, Rio de Janeiro",
                telefone: "(21) 2334-4088",website: nil,
                coordenadas: CLLocationCoordinate2D(latitude: -22.9615, longitude: -43.2109),
                avaliacao: 4.3
            ),
            
            // BIBLIOTECA
            PontoTuristico(
                id: "95",
                nome: LocalizedText(
                    pt: "Biblioteca Parque da Rocinha",
                    en: "Rocinha Park Library",
                    es: "Biblioteca Parque de Rocinha",
                    fr: "Bibliothèque Parc de Rocinha",
                    zh: "罗西尼亚公园图书馆"
                ),
                categoria: .biblioteca,
                texto: LocalizedText(
                    pt: "Biblioteca comunitária na maior favela do Rio. Acervo focado na comunidade local. Programação cultural e inclusão digital.",
                    en: "Community library in Rio's largest favela. Collection focused on local community. Cultural programming and digital inclusion.",
                    es: "Biblioteca comunitaria en la mayor favela de Río. Acervo enfocado en la comunidad local. Programación cultural e inclusión digital.",
                    fr: "Bibliothèque communautaire dans la plus grande favela de Rio. Collection axée sur la communauté locale. Programmation culturelle et inclusion numérique.",
                    zh: "里约最大贫民窟的社区图书馆。专注于当地社区的藏书。文化活动和数字包容。"
                ),
                endereco: "Estrada da Gávea, 454 - Rocinha, Rio de Janeiro",
                telefone: "(21) 2535-8175",website: nil,
                coordenadas: CLLocationCoordinate2D(latitude: -22.9889, longitude: -43.2472),
                avaliacao: 4.4
            ),
            
            PontoTuristico(
                id: "96",
                nome: LocalizedText(
                    pt: "Biblioteca de Manguinhos",
                    en: "Manguinhos Library",
                    es: "Biblioteca de Manguinhos",
                    fr: "Bibliothèque de Manguinhos",
                    zh: "曼吉尼奥斯图书馆"
                ),
                categoria: .biblioteca,
                texto: LocalizedText(
                    pt: "Premiada arquitetura sustentável na zona norte. Acervo diversificado e espaços de leitura inovadores. Atividades culturais para a comunidade.",
                    en: "Award-winning sustainable architecture in the north zone. Diverse collection and innovative reading spaces. Cultural activities for the community.",
                    es: "Premiada arquitectura sostenible en la zona norte. Acervo diversificado y espacios de lectura innovadores. Actividades culturales para la comunidad.",
                    fr: "Architecture durable primée dans la zone nord. Collection diversifiée et espaces de lecture innovants. Activités culturelles pour la communauté.",
                    zh: "北区获奖的可持续建筑。多样化的藏书和创新的阅读空间。为社区举办的文化活动。"
                ),
                endereco: "Av. Dom Hélder Câmara, 1184 - Manguinhos, Rio de Janeiro",
                telefone: "(21) 2334-8922",website: nil,
                coordenadas: CLLocationCoordinate2D(latitude: -22.8789, longitude: -43.2456),
                avaliacao: 4.3
            ),
            
            // MIRANTES
            PontoTuristico(
                id: "97",
                nome: LocalizedText(
                    pt: "Mirante do Soberbo",
                    en: "Soberbo Viewpoint",
                    es: "Mirador del Soberbo",
                    fr: "Belvédère du Soberbo",
                    zh: "索贝尔博观景台"
                ),
                categoria: .mirante,
                texto: LocalizedText(
                    pt: "Vista deslumbrante da Serra dos Órgãos na subida para Teresópolis. Parada obrigatória para fotos. Vista do Dedo de Deus e montanhas.",
                    en: "Stunning view of Serra dos Órgãos on the way up to Teresópolis. Mandatory photo stop. View of God's Finger and mountains.",
                    es: "Vista deslumbrante de la Serra dos Órgãos en la subida a Teresópolis. Parada obligatoria para fotos. Vista del Dedo de Dios y montañas.",
                    fr: "Vue imprenable sur la Serra dos Órgãos en montant vers Teresópolis. Arrêt photo obligatoire. Vue sur le Doigt de Dieu et les montagnes.",
                    zh: "前往特雷索波利斯途中俯瞰器官山脉的壮丽景色。必停拍照点。上帝之指和山脉景观。"
                ),
                endereco: "BR-116, Km 89 - Teresópolis, Rio de Janeiro",telefone: nil, website: nil,
                coordenadas: CLLocationCoordinate2D(latitude: -22.4528, longitude: -43.0347),
                avaliacao: 4.8
            ),
            
            PontoTuristico(
                id: "98",
                nome: LocalizedText(
                    pt: "Mirante do Corcovado (base)",
                    en: "Corcovado Viewpoint (base)",
                    es: "Mirador del Corcovado (base)",
                    fr: "Belvédère du Corcovado (base)",
                    zh: "科尔科瓦多观景台（基地）"
                ),
                categoria: .mirante,
                texto: LocalizedText(
                    pt: "Vista da base do Cristo Redentor. Acesso pela Estrada das Paineiras. Vista para a zona sul sem subir até o Cristo.",
                    en: "View from Christ the Redeemer base. Access via Paineiras Road. South zone view without going up to Christ.",
                    es: "Vista desde la base del Cristo Redentor. Acceso por la Carretera de las Paineiras. Vista de la zona sur sin subir hasta el Cristo.",
                    fr: "Vue depuis la base du Christ Rédempteur. Accès par la route des Paineiras. Vue sur la zone sud sans monter jusqu'au Christ.",
                    zh: "从救世基督像基地的景观。通过帕内拉斯路进入。无需登上基督像即可欣赏南区景色。"
                ),
                endereco: "Estrada das Paineiras - Santa Teresa, Rio de Janeiro", telefone: nil,website: nil,
                coordenadas: CLLocationCoordinate2D(latitude: -22.9494, longitude: -43.2048),
                avaliacao: 4.5
            ),
            
            PontoTuristico(
                id: "99",
                nome: LocalizedText(
                    pt: "Mirante do Pontal",
                    en: "Pontal Viewpoint",
                    es: "Mirador del Pontal",
                    fr: "Belvédère du Pontal",
                    zh: "蓬塔尔观景台"
                ),
                categoria: .mirante,
                texto: LocalizedText(
                    pt: "Vista panorâmica das praias do Recreio e Barra. Pôr do sol cinematográfico. Acesso fácil de carro com estacionamento.",
                    en: "Panoramic view of Recreio and Barra beaches. Cinematic sunset. Easy car access with parking.",
                    es: "Vista panorámica de las playas de Recreio y Barra. Atardecer cinematográfico. Fácil acceso en coche con estacionamiento.",
                    fr: "Vue panoramique sur les plages de Recreio et Barra. Coucher de soleil cinématographique. Accès facile en voiture avec parking.",
                    zh: "雷克雷欧和巴拉海滩的全景。电影般的日落。驾车方便，有停车场。"
                ),
                endereco: "Estrada do Pontal - Recreio dos Bandeirantes, Rio de Janeiro",telefone: nil, website: nil,
                coordenadas: CLLocationCoordinate2D(latitude: -23.0361, longitude: -43.5047),
                avaliacao: 4.6
            ),
            
            PontoTuristico(
                id: "100",
                nome: LocalizedText(
                    pt: "Heliponto do Morro do Cantagalo",
                    en: "Cantagalo Hill Helipad",
                    es: "Helipuerto del Morro do Cantagalo",
                    fr: "Héliport de la Colline Cantagalo",
                    zh: "坎塔加洛山直升机停机坪"
                ),
                categoria: .mirante,
                texto: LocalizedText(
                    pt: "Vista 360° de Copacabana, Ipanema e Lagoa. Acesso pela comunidade do Cantagalo. Vista privilegiada pouco conhecida pelos turistas.",
                    en: "360° view of Copacabana, Ipanema and Lagoa. Access through Cantagalo community. Privileged view little known by tourists.",
                    es: "Vista 360° de Copacabana, Ipanema y Lagoa. Acceso por la comunidad de Cantagalo. Vista privilegiada poco conocida por turistas.",
                    fr: "Vue à 360° sur Copacabana, Ipanema et Lagoa. Accès par la communauté de Cantagalo. Vue privilégiée peu connue des touristes.",
                    zh: "科帕卡巴纳、伊帕内玛和泻湖的360度全景。通过坎塔加洛社区进入。游客鲜知的优越景观。"
                ),
                endereco: "Morro do Cantagalo - Ipanema, Rio de Janeiro",telefone: nil, website: nil,
                coordenadas: CLLocationCoordinate2D(latitude: -22.9856, longitude: -43.1933),
                avaliacao: 4.7
            ),
            
            // CULTURA
            PontoTuristico(
                id: "68",
                nome: LocalizedText(
                    pt: "Circo Voador",
                    en: "Flying Circus",
                    es: "Circo Volador",
                    fr: "Cirque Volant",
                    zh: "飞行马戏团"
                ),
                categoria: .cultura,
                texto: LocalizedText(
                    pt: "Lendária casa de shows da Lapa. Berço de movimentos culturais desde os anos 80. Shows de música brasileira, rock, reggae e festas temáticas.",
                    en: "Legendary Lapa concert venue. Birthplace of cultural movements since the 80s. Brazilian music, rock, reggae shows and themed parties.",
                    es: "Legendaria casa de shows de Lapa. Cuna de movimientos culturales desde los años 80. Shows de música brasileña, rock, reggae y fiestas temáticas.",
                    fr: "Légendaire salle de concert de Lapa. Berceau de mouvements culturels depuis les années 80. Concerts de musique brésilienne, rock, reggae et fêtes à thème.",
                    zh: "拉帕传奇音乐厅。自80年代以来文化运动的发源地。巴西音乐、摇滚、雷鬼演出和主题派对。"
                ),
                endereco: "R. dos Arcos, S/N - Lapa, Rio de Janeiro",
                telefone: "(21) 2533-0354",
                website: "http://www.circovoador.com.br",
                coordenadas: CLLocationCoordinate2D(latitude: -22.9112, longitude: -43.1802),
                avaliacao: 4.4
            ),
            
            PontoTuristico(
                id: "69",
                nome: LocalizedText(
                    pt: "Fundição Progresso",
                    en: "Progress Foundry",
                    es: "Fundición Progreso",
                    fr: "Fonderie Progress",
                    zh: "进步铸造厂"
                ),
                categoria: .cultura,
                texto: LocalizedText(
                    pt: "Antiga fundição transformada em centro cultural. Arquitetura industrial preservada. Shows, exposições, feiras e eventos culturais diversos.",
                    en: "Former foundry transformed into cultural center. Preserved industrial architecture. Shows, exhibitions, fairs and diverse cultural events.",
                    es: "Antigua fundición transformada en centro cultural. Arquitectura industrial preservada. Shows, exposiciones, ferias y eventos culturales diversos.",
                    fr: "Ancienne fonderie transformée en centre culturel. Architecture industrielle préservée. Spectacles, expositions, foires et événements culturels divers.",
                    zh: "前铸造厂改造成的文化中心。保存的工业建筑。演出、展览、集市和各种文化活动。"
                ),
                endereco: "R. dos Arcos, 24 - Lapa, Rio de Janeiro",
                telefone: "(21) 2220-5070",
                website: "http://www.fundicaoprogresso.com.br",
                coordenadas: CLLocationCoordinate2D(latitude: -22.9119, longitude: -43.1798),
                avaliacao: 4.5
            ),
            
            PontoTuristico(
                id: "70",
                nome: LocalizedText(
                    pt: "Feira Hippie de Ipanema",
                    en: "Ipanema Hippie Fair",
                    es: "Feria Hippie de Ipanema",
                    fr: "Foire Hippie d'Ipanema",
                    zh: "伊帕内玛嬉皮集市"
                ),
                categoria: .cultura,
                texto: LocalizedText(
                    pt: "Tradicional feira de artesanato aos domingos desde 1968. Mais de 700 expositores com arte, artesanato, roupas e acessórios. Ponto de encontro cultural.",
                    en: "Traditional Sunday craft fair since 1968. Over 700 exhibitors with art, crafts, clothes and accessories. Cultural meeting point.",
                    es: "Tradicional feria de artesanía los domingos desde 1968. Más de 700 expositores con arte, artesanía, ropa y accesorios. Punto de encuentro cultural.",
                    fr: "Foire artisanale traditionnelle du dimanche depuis 1968. Plus de 700 exposants avec art, artisanat, vêtements et accessoires. Point de rencontre culturel.",
                    zh: "自1968年以来的传统周日手工艺品集市。超过700个摊位，出售艺术品、手工艺品、服装和配饰。文化聚会点。"
                ),
                endereco: "Praça General Osório - Ipanema, Rio de Janeiro",telefone: nil, website: nil,
                coordenadas: CLLocationCoordinate2D(latitude: -22.9846, longitude: -43.1987),
                avaliacao: 4.3
            ),
            
            // ESPORTE
            PontoTuristico(
                id: "71",
                nome: LocalizedText(
                    pt: "Pista Cláudio Coutinho",
                    en: "Cláudio Coutinho Track",
                    es: "Pista Cláudio Coutinho",
                    fr: "Piste Cláudio Coutinho",
                    zh: "克劳迪奥·库蒂尼奥步道"
                ),
                categoria: .esporte,
                texto: LocalizedText(
                    pt: "Pista de caminhada de 1,25 km contornando o Morro da Urca. Vista para o mar e formações rochosas. Ponto de observação de aves e vida marinha.",
                    en: "1.25 km walking track around Urca Hill. Sea views and rock formations. Bird watching and marine life observation point.",
                    es: "Pista de caminata de 1,25 km bordeando el Morro da Urca. Vista al mar y formaciones rocosas. Punto de observación de aves y vida marina.",
                    fr: "Piste de marche de 1,25 km autour de la colline d'Urca. Vue sur la mer et formations rocheuses. Point d'observation des oiseaux et de la vie marine.",
                    zh: "环绕乌尔卡山的1.25公里步行道。海景和岩石地貌。观鸟和海洋生物观察点。"
                ),
                endereco: "Praça General Tibúrcio - Praia Vermelha, Urca, Rio de Janeiro",telefone: nil, website: nil,
                coordenadas: CLLocationCoordinate2D(latitude: -22.9533, longitude: -43.1650),
                avaliacao: 4.6
            ),
            
            // ARTE
            PontoTuristico(
                id: "72",
                nome: LocalizedText(
                    pt: "Escola de Artes Visuais do Parque Lage",
                    en: "Parque Lage Visual Arts School",
                    es: "Escuela de Artes Visuales del Parque Lage",
                    fr: "École d'Arts Visuels du Parque Lage",
                    zh: "拉赫公园视觉艺术学校"
                ),
                categoria: .arte,
                texto: LocalizedText(
                    pt: "Centro de ensino e produção artística em palacete histórico. Cursos, exposições e ateliês abertos. Café com vista para o Cristo em ambiente artístico.",
                    en: "Art teaching and production center in historic mansion. Courses, exhibitions and open studios. Café with Christ view in artistic environment.",
                    es: "Centro de enseñanza y producción artística en palacete histórico. Cursos, exposiciones y talleres abiertos. Café con vista al Cristo en ambiente artístico.",
                    fr: "Centre d'enseignement et de production artistique dans un petit palais historique. Cours, expositions et ateliers ouverts. Café avec vue sur le Christ dans un environnement artistique.",
                    zh: "历史豪宅中的艺术教学和制作中心。课程、展览和开放工作室。在艺术氛围中享用咖啡，欣赏基督像。"
                ),
                endereco: "R. Jardim Botânico, 414 - Jardim Botânico, Rio de Janeiro",
                telefone: "(21) 3257-1800",
                website: "http://eavparquelage.rj.gov.br",
                coordenadas: CLLocationCoordinate2D(latitude: -22.9617, longitude: -43.2110),
                avaliacao: 4.6
            ),
            
            // MIRANTES
            PontoTuristico(
                id: "73",
                nome: LocalizedText(
                    pt: "Mirante da Prainha",
                    en: "Prainha Viewpoint",
                    es: "Mirador de Prainha",
                    fr: "Belvédère de Prainha",
                    zh: "小海滩观景台"
                ),
                categoria: .mirante,
                texto: LocalizedText(
                    pt: "Vista panorâmica da Prainha e Grumari. Parada obrigatória na estrada litorânea. Pôr do sol espetacular sobre o oceano e montanhas.",
                    en: "Panoramic view of Prainha and Grumari. Mandatory stop on the coastal road. Spectacular sunset over ocean and mountains.",
                    es: "Vista panorámica de Prainha y Grumari. Parada obligatoria en la carretera costera. Atardecer espectacular sobre el océano y montañas.",
                    fr: "Vue panoramique sur Prainha et Grumari. Arrêt obligatoire sur la route côtière. Coucher de soleil spectaculaire sur l'océan et les montagnes.",
                    zh: "小海滩和格鲁马里的全景。海岸公路上的必经之地。海洋和山脉上壮观的日落。"
                ),
                endereco: "Av. Estado da Guanabara - Recreio dos Bandeirantes, Rio de Janeiro",telefone: nil, website: nil,
                coordenadas: CLLocationCoordinate2D(latitude: -23.0383, longitude: -43.4939),
                avaliacao: 4.7
            ),
            
            PontoTuristico(
                id: "74",
                nome: LocalizedText(
                    pt: "Mesa do Imperador",
                    en: "Emperor's Table",
                    es: "Mesa del Emperador",
                    fr: "Table de l'Empereur",
                    zh: "皇帝之桌"
                ),
                categoria: .mirante,
                texto: LocalizedText(
                    pt: "Mirante onde D. Pedro II fazia piqueniques. Vista deslumbrante da Floresta da Tijuca e zona norte. Trilha moderada de 45 minutos.",
                    en: "Viewpoint where D. Pedro II had picnics. Stunning view of Tijuca Forest and north zone. Moderate 45-minute trail.",
                    es: "Mirador donde D. Pedro II hacía picnics. Vista deslumbrante del Bosque de Tijuca y zona norte. Sendero moderado de 45 minutos.",
                    fr: "Point de vue où D. Pedro II faisait des pique-niques. Vue imprenable sur la forêt de Tijuca et la zone nord. Sentier modéré de 45 minutes.",
                    zh: "佩德罗二世皇帝野餐的观景点。蒂茹卡森林和北区的壮丽景色。45分钟的中等难度步道。"
                ),
                endereco: "Estrada da Vista Chinesa - Parque Nacional da Tijuca, Rio de Janeiro",telefone: nil, website: nil,
                coordenadas: CLLocationCoordinate2D(latitude: -22.9586, longitude: -43.2450),
                avaliacao: 4.6
            ),
            
            PontoTuristico(
                id: "75",
                nome: LocalizedText(
                    pt: "Parque da Cidade",
                    en: "City Park",
                    es: "Parque de la Ciudad",
                    fr: "Parc de la Ville",
                    zh: "城市公园"
                ),
                categoria: .mirante,
                texto: LocalizedText(
                    pt: "Parque em Niterói com vista única da Baía de Guanabara e Rio. Museu da cidade, trilhas e área de lazer. Vista de 270° incluindo Pão de Açúcar e Cristo.",
                    en: "Park in Niterói with unique view of Guanabara Bay and Rio. City museum, trails and leisure area. 270° view including Sugar Loaf and Christ.",
                    es: "Parque en Niterói con vista única de la Bahía de Guanabara y Río. Museo de la ciudad, senderos y área de ocio. Vista de 270° incluyendo Pan de Azúcar y Cristo.",
                    fr: "Parc à Niterói avec vue unique sur la baie de Guanabara et Rio. Musée de la ville, sentiers et zone de loisirs. Vue à 270° incluant le Pain de Sucre et le Christ.",
                    zh: "尼泰罗伊公园，瓜纳巴拉湾和里约的独特景观。城市博物馆、步道和休闲区。270度全景，包括糖面包山和基督像。"
                ),
                endereco: "Estrada da Viração, S/N - São Francisco, Niterói, Rio de Janeiro",telefone: nil, website: nil,
                coordenadas: CLLocationCoordinate2D(latitude: -22.9147, longitude: -43.0850),
                avaliacao: 4.5
            ),
            
            PontoTuristico(
                id: "47",
                nome: LocalizedText(
                    pt: "Palácio do Catete",
                    en: "Catete Palace",
                    es: "Palacio del Catete",
                    fr: "Palais du Catete",
                    zh: "卡特特宫"
                ),
                categoria: .patrimonio,
                texto: LocalizedText(
                    pt: "Antiga sede da Presidência da República. Museu da República com jardins de 24 mil m². Quarto onde Getúlio Vargas se suicidou preservado como memorial.",
                    en: "Former seat of the Presidency. Museum of the Republic with 24,000 m² gardens. Room where Getúlio Vargas committed suicide preserved as memorial.",
                    es: "Antigua sede de la Presidencia de la República. Museo de la República con jardines de 24 mil m². Habitación donde Getúlio Vargas se suicidó preservada como memorial.",
                    fr: "Ancien siège de la Présidence. Musée de la République avec jardins de 24 000 m². La chambre où Getúlio Vargas s'est suicidé est préservée comme mémorial.",
                    zh: "前总统府。共和国博物馆，拥有2.4万平方米的花园。热图利奥·瓦加斯自杀的房间被保存为纪念馆。"
                ),
                endereco: "R. do Catete, 153 - Catete, Rio de Janeiro",
                telefone: "(21) 2127-0324",
                website: "http://museudarepublica.museus.gov.br",
                coordenadas: CLLocationCoordinate2D(latitude: -22.9259, longitude: -43.1765),
                avaliacao: 4.5
            ),
            
            // PRAIAS
            PontoTuristico(
                id: "48",
                nome: LocalizedText(
                    pt: "Praia Vermelha",
                    en: "Red Beach",
                    es: "Playa Roja",
                    fr: "Plage Rouge",
                    zh: "红海滩"
                ),
                categoria: .praia,
                texto: LocalizedText(
                    pt: "Pequena praia protegida no pé do Pão de Açúcar. Águas calmas ideais para famílias. Nome vem da coloração avermelhada da areia. Trilha do Morro da Urca.",
                    en: "Small protected beach at the foot of Sugar Loaf. Calm waters ideal for families. Name comes from the reddish color of the sand. Trail to Urca Hill.",
                    es: "Pequeña playa protegida al pie del Pan de Azúcar. Aguas tranquilas ideales para familias. El nombre viene del color rojizo de la arena. Sendero al Morro da Urca.",
                    fr: "Petite plage protégée au pied du Pain de Sucre. Eaux calmes idéales pour les familles. Le nom vient de la couleur rougeâtre du sable. Sentier vers la colline d'Urca.",
                    zh: "糖面包山脚下的小型保护海滩。平静的水域非常适合家庭。名字来源于沙子的红色。通往乌尔卡山的小径。"
                ),
                endereco: "Praça General Tibúrcio - Urca, Rio de Janeiro",telefone: nil, website: nil,
                coordenadas: CLLocationCoordinate2D(latitude: -22.9548, longitude: -43.1653),
                avaliacao: 4.4
            ),
            
            PontoTuristico(
                id: "49",
                nome: LocalizedText(
                    pt: "Praia da Joatinga",
                    en: "Joatinga Beach",
                    es: "Playa de Joatinga",
                    fr: "Plage de Joatinga",
                    zh: "若阿廷加海滩"
                ),
                categoria: .praia,
                texto: LocalizedText(
                    pt: "Praia selvagem e isolada acessível apenas por trilha íngreme. Paraíso preservado com águas cristalinas. Popular entre surfistas e aventureiros.",
                    en: "Wild and isolated beach accessible only by steep trail. Preserved paradise with crystal clear waters. Popular among surfers and adventurers.",
                    es: "Playa salvaje y aislada accesible solo por sendero empinado. Paraíso preservado con aguas cristalinas. Popular entre surfistas y aventureros.",
                    fr: "Plage sauvage et isolée accessible uniquement par sentier escarpé. Paradis préservé aux eaux cristallines. Populaire parmi les surfeurs et aventuriers.",
                    zh: "只能通过陡峭小径到达的野生偏僻海滩。水晶般清澈的海水的天堂。受冲浪者和冒险者欢迎。"
                ),
                endereco: "Final da R. Sargento José da Silva - Joá, Rio de Janeiro",telefone: nil, website: nil,
                coordenadas: CLLocationCoordinate2D(latitude: -23.0161, longitude: -43.2897),
                avaliacao: 4.8
            ),
            
            // PARQUES
            PontoTuristico(
                id: "50",
                nome: LocalizedText(
                    pt: "Bosque da Barra",
                    en: "Barra Woods",
                    es: "Bosque de Barra",
                    fr: "Bois de Barra",
                    zh: "巴拉森林"
                ),
                categoria: .parque,
                texto: LocalizedText(
                    pt: "Reserva ambiental com 50 hectares de mata atlântica preservada. Trilhas, lagos e diversidade de fauna. Refúgio verde em meio ao desenvolvimento urbano da Barra.",
                    en: "Environmental reserve with 50 hectares of preserved Atlantic Forest. Trails, lakes and fauna diversity. Green refuge amid Barra's urban development.",
                    es: "Reserva ambiental con 50 hectáreas de mata atlántica preservada. Senderos, lagos y diversidad de fauna. Refugio verde en medio del desarrollo urbano de Barra.",
                    fr: "Réserve environnementale avec 50 hectares de forêt atlantique préservée. Sentiers, lacs et diversité de faune. Refuge vert au milieu du développement urbain de Barra.",
                    zh: "拥有50公顷保护大西洋森林的环境保护区。步道、湖泊和丰富的动物群。巴拉城市发展中的绿色避难所。"
                ),
                endereco: "Av. das Américas, 6000 - Barra da Tijuca, Rio de Janeiro",telefone: nil, website: nil,
                coordenadas: CLLocationCoordinate2D(latitude: -22.9951, longitude: -43.3736),
                avaliacao: 4.3
            ),
            
            // MUSEUS
            PontoTuristico(
                id: "51",
                nome: LocalizedText(
                    pt: "Casa do Pontal",
                    en: "Pontal House",
                    es: "Casa del Pontal",
                    fr: "Maison du Pontal",
                    zh: "蓬塔尔之家"
                ),
                categoria: .museu,
                texto: LocalizedText(
                    pt: "Maior museu de arte popular brasileira, com mais de 8 mil peças. Coleção retrata a diversidade cultural do país através do artesanato e arte popular.",
                    en: "Largest museum of Brazilian folk art, with over 8,000 pieces. Collection portrays the country's cultural diversity through crafts and folk art.",
                    es: "Mayor museo de arte popular brasileño, con más de 8 mil piezas. La colección retrata la diversidad cultural del país a través de la artesanía y el arte popular.",
                    fr: "Plus grand musée d'art populaire brésilien, avec plus de 8 000 pièces. La collection illustre la diversité culturelle du pays à travers l'artisanat et l'art populaire.",
                    zh: "巴西最大的民间艺术博物馆，拥有超过8000件藏品。通过手工艺品和民间艺术展现该国的文化多样性。"
                ),
                endereco: "R. Conde de Bernadotte, 26 - Leblon, Rio de Janeiro",
                telefone: "(21) 2512-3850",
                website: "http://www.museucasadopontal.com.br",
                coordenadas: CLLocationCoordinate2D(latitude: -22.9889, longitude: -43.2258),
                avaliacao: 4.6
            ),
            
            // CULTURA
            PontoTuristico(
                id: "52",
                nome: LocalizedText(
                    pt: "Pedra do Sal",
                    en: "Salt Stone",
                    es: "Piedra de Sal",
                    fr: "Pierre de Sel",
                    zh: "盐石"
                ),
                categoria: .cultura,
                texto: LocalizedText(
                    pt: "Berço do samba carioca e importante sítio arqueológico afro-brasileiro. Rodas de samba às segundas-feiras. Marco da Pequena África no Rio.",
                    en: "Birthplace of Rio samba and important Afro-Brazilian archaeological site. Samba circles on Mondays. Landmark of Little Africa in Rio.",
                    es: "Cuna del samba carioca e importante sitio arqueológico afrobrasileño. Ruedas de samba los lunes. Hito de la Pequeña África en Río.",
                    fr: "Berceau de la samba de Rio et important site archéologique afro-brésilien. Cercles de samba le lundi. Point de repère de la Petite Afrique à Rio.",
                    zh: "里约桑巴的发源地和重要的非裔巴西考古遗址。周一的桑巴圈。里约小非洲的地标。"
                ),
                endereco: "Largo João da Baiana - Saúde, Rio de Janeiro",telefone: nil, website: nil,
                coordenadas: CLLocationCoordinate2D(latitude: -22.8975, longitude: -43.1860),
                avaliacao: 4.5
            ),
            
            PontoTuristico(
                id: "53",
                nome: LocalizedText(
                    pt: "Cais do Valongo",
                    en: "Valongo Wharf",
                    es: "Muelle de Valongo",
                    fr: "Quai de Valongo",
                    zh: "瓦隆戈码头"
                ),
                categoria: .cultura,
                texto: LocalizedText(
                    pt: "Patrimônio Mundial da UNESCO. Principal porto de entrada de africanos escravizados nas Américas. Sítio arqueológico de grande importância histórica.",
                    en: "UNESCO World Heritage Site. Main port of entry for enslaved Africans in the Americas. Archaeological site of great historical importance.",
                    es: "Patrimonio Mundial de la UNESCO. Principal puerto de entrada de africanos esclavizados en las Américas. Sitio arqueológico de gran importancia histórica.",
                    fr: "Site du patrimoine mondial de l'UNESCO. Principal port d'entrée des Africains réduits en esclavage dans les Amériques. Site archéologique de grande importance historique.",
                    zh: "联合国教科文组织世界遗产。美洲被奴役非洲人的主要入境港。具有重要历史意义的考古遗址。"
                ),
                endereco: "Av. Barão de Tefé - Saúde, Rio de Janeiro",telefone: nil, website: nil,
                coordenadas: CLLocationCoordinate2D(latitude: -22.8972, longitude: -43.1877),
                avaliacao: 4.4
            ),
            
            // ESPORTE
            PontoTuristico(
                id: "54",
                nome: LocalizedText(
                    pt: "Parque Olímpico",
                    en: "Olympic Park",
                    es: "Parque Olímpico",
                    fr: "Parc Olympique",
                    zh: "奥林匹克公园"
                ),
                categoria: .esporte,
                texto: LocalizedText(
                    pt: "Legado dos Jogos Olímpicos Rio 2016. Arenas esportivas, área de lazer e eventos. Inclui o Museu Olímpico e instalações para prática esportiva.",
                    en: "Legacy of Rio 2016 Olympic Games. Sports arenas, leisure area and events. Includes the Olympic Museum and sports facilities.",
                    es: "Legado de los Juegos Olímpicos Río 2016. Arenas deportivas, área de ocio y eventos. Incluye el Museo Olímpico e instalaciones deportivas.",
                    fr: "Héritage des Jeux Olympiques de Rio 2016. Arènes sportives, zone de loisirs et événements. Comprend le Musée Olympique et des installations sportives.",
                    zh: "2016年里约奥运会的遗产。体育场馆、休闲区和活动场所。包括奥林匹克博物馆和体育设施。"
                ),
                endereco: "Av. Embaixador Abelardo Bueno, 3401 - Barra da Tijuca, Rio de Janeiro",telefone: nil, website: nil,
                coordenadas: CLLocationCoordinate2D(latitude: -22.9784, longitude: -43.3907),
                avaliacao: 4.2
            ),
            
            // ARTE
            PontoTuristico(
                id: "55",
                nome: LocalizedText(
                    pt: "Centro Cultural Municipal Parque das Ruínas",
                    en: "Ruins Park Cultural Center",
                    es: "Centro Cultural Parque de las Ruinas",
                    fr: "Centre Culturel Parc des Ruines",
                    zh: "废墟公园文化中心"
                ),
                categoria: .arte,
                texto: LocalizedText(
                    pt: "Palacete em ruínas transformado em espaço cultural. Arquitetura integrada à natureza. Programação de música, teatro e artes visuais com vista panorâmica.",
                    en: "Ruined mansion transformed into cultural space. Architecture integrated with nature. Music, theater and visual arts programming with panoramic views.",
                    es: "Palacete en ruinas transformado en espacio cultural. Arquitectura integrada a la naturaleza. Programación de música, teatro y artes visuales con vista panorámica.",
                    fr: "Petit palais en ruines transformé en espace culturel. Architecture intégrée à la nature. Programmation musicale, théâtrale et arts visuels avec vue panoramique.",
                    zh: "废墟豪宅改造成的文化空间。与自然融为一体的建筑。音乐、戏剧和视觉艺术活动，享有全景。"
                ),
                endereco: "R. Murtinho Nobre, 169 - Santa Teresa, Rio de Janeiro",telefone: "(21) 2215-0621",website: nil,
                coordenadas: CLLocationCoordinate2D(latitude: -22.9170, longitude: -43.1817),
                avaliacao: 4.5
            ),
            
            // MIRANTES
            PontoTuristico(
                id: "56",
                nome: LocalizedText(
                    pt: "Morro da Urca",
                    en: "Urca Hill",
                    es: "Morro da Urca",
                    fr: "Colline d'Urca",
                    zh: "乌尔卡山"
                ),
                categoria: .mirante,
                texto: LocalizedText(
                    pt: "Primeira parada do bondinho, a 220m de altura. Vista para a Baía de Guanabara, praias e Cristo Redentor. Trilha da Praia Vermelha para os aventureiros.",
                    en: "First cable car stop, at 220m height. View of Guanabara Bay, beaches and Christ the Redeemer. Trail from Red Beach for adventurers.",
                    es: "Primera parada del teleférico, a 220m de altura. Vista de la Bahía de Guanabara, playas y Cristo Redentor. Sendero desde Playa Roja para aventureros.",
                    fr: "Premier arrêt du téléphérique, à 220m de hauteur. Vue sur la baie de Guanabara, les plages et le Christ Rédempteur. Sentier depuis la Plage Rouge pour les aventuriers.",
                    zh: "缆车第一站，海拔220米。瓜纳巴拉湾、海滩和救世基督像的景色。从红海滩出发的冒险者小径。"
                ),
                endereco: "Av. Pasteur, 520 - Urca, Rio de Janeiro",
                telefone: "(21) 2546-8400",
                website: "https://bondinho.com.br",
                coordenadas: CLLocationCoordinate2D(latitude: -22.9517, longitude: -43.1631),
                avaliacao: 4.6
            ),
            
            PontoTuristico(
                id: "57",
                nome: LocalizedText(
                    pt: "Pico da Tijuca",
                    en: "Tijuca Peak",
                    es: "Pico de Tijuca",
                    fr: "Pic de Tijuca",
                    zh: "蒂茹卡峰"
                ),
                categoria: .mirante,
                texto: LocalizedText(
                    pt: "Ponto mais alto da cidade com 1.021m. Trilha moderada de 2 horas através da floresta. Vista de 360° incluindo toda a cidade e região metropolitana.",
                    en: "City's highest point at 1,021m. Moderate 2-hour trail through the forest. 360° view including the entire city and metropolitan region.",
                    es: "Punto más alto de la ciudad con 1.021m. Sendero moderado de 2 horas a través del bosque. Vista de 360° incluyendo toda la ciudad y región metropolitana.",
                    fr: "Point culminant de la ville à 1 021m. Sentier modéré de 2 heures à travers la forêt. Vue à 360° incluant toute la ville et la région métropolitaine.",
                    zh: "城市最高点，海拔1021米。穿过森林的2小时中等难度步道。360度全景，包括整个城市和大都市区。"
                ),
                endereco: "Parque Nacional da Tijuca - Alto da Boa Vista, Rio de Janeiro", telefone: nil, website: nil,
                coordenadas: CLLocationCoordinate2D(latitude: -22.9431, longitude: -43.2856),
                avaliacao: 4.7
            ),
            
            // MAIS PONTOS DIVERSOS
            PontoTuristico(
                id: "58",
                nome: LocalizedText(
                    pt: "Ilha de Paquetá",
                    en: "Paquetá Island",
                    es: "Isla de Paquetá",
                    fr: "Île de Paquetá",
                    zh: "帕克塔岛"
                ),
                categoria: .cultura,
                texto: LocalizedText(
                    pt: "Ilha histórica na Baía de Guanabara sem carros. Passeio de bicicleta, praias tranquilas e arquitetura colonial. Acesso por barcas da Praça XV.",
                    en: "Historic island in Guanabara Bay without cars. Bike rides, quiet beaches and colonial architecture. Access by ferry from Praça XV.",
                    es: "Isla histórica en la Bahía de Guanabara sin coches. Paseos en bicicleta, playas tranquilas y arquitectura colonial. Acceso por ferry desde Praça XV.",
                    fr: "Île historique dans la baie de Guanabara sans voitures. Balades à vélo, plages tranquilles et architecture coloniale. Accès par ferry depuis Praça XV.",
                    zh: "瓜纳巴拉湾的历史岛屿，没有汽车。自行车骑行、宁静的海滩和殖民建筑。从十五广场乘渡轮前往。"
                ),
                endereco: "Ilha de Paquetá - Baía de Guanabara, Rio de Janeiro", telefone: nil, website: nil,
                coordenadas: CLLocationCoordinate2D(latitude: -22.7628, longitude: -43.1063),
                avaliacao: 4.4
            ),
            
            PontoTuristico(
                id: "59",
                nome: LocalizedText(
                    pt: "Floresta da Tijuca - Cachoeira dos Primatas",
                    en: "Tijuca Forest - Primates Waterfall",
                    es: "Bosque de Tijuca - Cascada de los Primates",
                    fr: "Forêt de Tijuca - Cascade des Primates",
                    zh: "蒂茹卡森林 - 灵长类瀑布"
                ),
                categoria: .parque,
                texto: LocalizedText(
                    pt: "Cachoeira de fácil acesso dentro da floresta urbana. Trilha de 30 minutos, ideal para famílias. Piscina natural e área para piquenique.",
                    en: "Easily accessible waterfall within the urban forest. 30-minute trail, ideal for families. Natural pool and picnic area.",
                    es: "Cascada de fácil acceso dentro del bosque urbano. Sendero de 30 minutos, ideal para familias. Piscina natural y área de picnic.",
                    fr: "Cascade facilement accessible dans la forêt urbaine. Sentier de 30 minutes, idéal pour les familles. Piscine naturelle et aire de pique-nique.",
                    zh: "城市森林中易于到达的瀑布。30分钟的步道，非常适合家庭。天然泳池和野餐区。"
                ),
                endereco: "Estrada da Cascatinha, 850 - Alto da Boa Vista, Rio de Janeiro", telefone: nil, website: nil,
                coordenadas: CLLocationCoordinate2D(latitude: -22.9461, longitude: -43.2972),
                avaliacao: 4.5
            ),
            
            PontoTuristico(
                id: "60",
                nome: LocalizedText(
                    pt: "Mureta da Urca",
                    en: "Urca Wall",
                    es: "Muro de Urca",
                    fr: "Mur d'Urca",
                    zh: "乌尔卡墙"
                ),
                categoria: .mirante,
                texto: LocalizedText(
                    pt: "Point tradicional para apreciar o pôr do sol. Vista para a entrada da Baía de Guanabara. Bares e restaurantes com mesas ao ar livre sobre as pedras.",
                    en: "Traditional spot to watch the sunset. View of Guanabara Bay entrance. Bars and restaurants with outdoor tables on the rocks.",
                    es: "Punto tradicional para apreciar la puesta de sol. Vista de la entrada de la Bahía de Guanabara. Bares y restaurantes con mesas al aire libre sobre las piedras.",
                    fr: "Lieu traditionnel pour admirer le coucher de soleil. Vue sur l'entrée de la baie de Guanabara. Bars et restaurants avec tables en plein air sur les rochers.",
                    zh: "欣赏日落的传统地点。瓜纳巴拉湾入口的景色。岩石上设有户外餐桌的酒吧和餐厅。"
                ),
                endereco: "Av. João Luís Alves - Urca, Rio de Janeiro", telefone: nil, website: nil,                coordenadas: CLLocationCoordinate2D(latitude: -22.9444, longitude: -43.1631),
                avaliacao: 4.7
            ),
            
            PontoTuristico(
                id: "3",
                nome: LocalizedText(
                    pt: "Theatro Municipal",
                    en: "Municipal Theater",
                    es: "Teatro Municipal",
                    fr: "Théâtre Municipal",
                    zh: "市立剧院"
                ),
                categoria: .patrimonio,
                texto: LocalizedText(
                    pt: "Inaugurado em 1909, é um dos mais importantes teatros do Brasil e um dos mais belos exemplares da arquitetura eclética do país. Inspirado na Ópera de Paris.",
                    en: "Opened in 1909, it is one of Brazil's most important theaters and one of the most beautiful examples of eclectic architecture in the country. Inspired by the Paris Opera.",
                    es: "Inaugurado en 1909, es uno de los teatros más importantes de Brasil y uno de los más bellos ejemplares de la arquitectura ecléctica del país. Inspirado en la Ópera de París.",
                    fr: "Inauguré en 1909, c'est l'un des théâtres les plus importants du Brésil et l'un des plus beaux exemples d'architecture éclectique du pays. Inspiré de l'Opéra de Paris.",
                    zh: "建于1909年，是巴西最重要的剧院之一，也是该国折衷主义建筑最美丽的典范之一。灵感来自巴黎歌剧院。"
                ),
                endereco: "Praça Floriano, S/N - Centro, Rio de Janeiro",
                telefone: "(21) 2332-9191",
                website: "https://theatromunicipal.rj.gov.br",
                coordenadas: CLLocationCoordinate2D(latitude: -22.9090, longitude: -43.1765),
                avaliacao: 4.7
            ),
            
            PontoTuristico(
                id: "4",
                nome: LocalizedText(
                    pt: "Real Gabinete Português de Leitura",
                    en: "Royal Portuguese Reading Room",
                    es: "Real Gabinete Portugués de Lectura",
                    fr: "Cabinet Royal Portugais de Lecture",
                    zh: "皇家葡萄牙语阅览室"
                ),
                categoria: .patrimonio,
                texto: LocalizedText(
                    pt: "Considerada uma das mais belas bibliotecas do mundo, abriga a maior coleção de literatura portuguesa fora de Portugal, com mais de 350 mil volumes.",
                    en: "Considered one of the most beautiful libraries in the world, it houses the largest collection of Portuguese literature outside Portugal, with over 350,000 volumes.",
                    es: "Considerada una de las bibliotecas más bellas del mundo, alberga la mayor colección de literatura portuguesa fuera de Portugal, con más de 350 mil volúmenes.",
                    fr: "Considérée comme l'une des plus belles bibliothèques du monde, elle abrite la plus grande collection de littérature portugaise hors du Portugal, avec plus de 350 000 volumes.",
                    zh: "被认为是世界上最美丽的图书馆之一，收藏着葡萄牙以外最大的葡萄牙文学作品集，拥有超过35万册藏书。"
                ),
                endereco: "R. Luís de Camões, 30 - Centro, Rio de Janeiro",
                telefone: "(21) 2221-3138",
                website: "https://realgabinete.com.br",
                coordenadas: CLLocationCoordinate2D(latitude: -22.9035, longitude: -43.1809),
                avaliacao: 4.8
            ),
            
            PontoTuristico(
                id: "28",
                nome: LocalizedText(
                    pt: "Catedral Metropolitana",
                    en: "Metropolitan Cathedral",
                    es: "Catedral Metropolitana",
                    fr: "Cathédrale Métropolitaine",
                    zh: "大都会大教堂"
                ),
                categoria: .patrimonio,
                texto: LocalizedText(
                    pt: "Arquitetura moderna em forma cônica com 75m de altura. Vitrais coloridos de 64m criam ambiente místico. Capacidade para 20 mil pessoas.",
                    en: "Modern conical architecture 75m high. 64m colored stained glass windows create a mystical atmosphere. Capacity for 20,000 people.",
                    es: "Arquitectura moderna en forma cónica con 75m de altura. Vitrales coloridos de 64m crean ambiente místico. Capacidad para 20 mil personas.",
                    fr: "Architecture moderne conique de 75m de haut. Les vitraux colorés de 64m créent une atmosphère mystique. Capacité de 20 000 personnes.",
                    zh: "75米高的现代圆锥形建筑。64米高的彩色玻璃窗营造出神秘的氛围。可容纳2万人。"
                ),
                endereco: "Av. República do Chile, 245 - Centro, Rio de Janeiro",
                telefone: "(21) 2240-2669",website: nil,
                coordenadas: CLLocationCoordinate2D(latitude: -22.9104, longitude: -43.1802),
                avaliacao: 4.4
            ),
            
            PontoTuristico(
                id: "41",
                nome: LocalizedText(
                    pt: "Forte de Copacabana",
                    en: "Copacabana Fort",
                    es: "Fuerte de Copacabana",
                    fr: "Fort de Copacabana",
                    zh: "科帕卡巴纳堡垒"
                ),
                categoria: .patrimonio,
                texto: LocalizedText(
                    pt: "Fortificação militar de 1914 na ponta da praia. Museu Histórico do Exército, canhões Krupp e vista panorâmica. Confeitaria Colombo com café da manhã especial.",
                    en: "1914 military fortification at the beach tip. Army Historical Museum, Krupp cannons and panoramic view. Colombo Confectionery with special breakfast.",
                    es: "Fortificación militar de 1914 en la punta de la playa. Museo Histórico del Ejército, cañones Krupp y vista panorámica. Confitería Colombo con desayuno especial.",
                    fr: "Fortification militaire de 1914 à la pointe de la plage. Musée historique de l'armée, canons Krupp et vue panoramique. Confiserie Colombo avec petit déjeuner spécial.",
                    zh: "1914年建造的军事要塞，位于海滩尽头。陆军历史博物馆、克虏伯大炮和全景观。科伦坡糖果店提供特别早餐。"
                ),
                endereco: "Praça Cel. Eugênio Franco, 1 - Copacabana, Rio de Janeiro",
                telefone: "(21) 2521-1032",website: nil,
                coordenadas: CLLocationCoordinate2D(latitude: -22.9866, longitude: -43.1877),
                avaliacao: 4.4
            ),
            
            PontoTuristico(
                id: "44",
                nome: LocalizedText(
                    pt: "Ilha Fiscal",
                    en: "Fiscal Island",
                    es: "Isla Fiscal",
                    fr: "Île Fiscale",
                    zh: "财政岛"
                ),
                categoria: .patrimonio,
                texto: LocalizedText(
                    pt: "Palácio neogótico de 1889 na Baía de Guanabara. Último baile do Império antes da Proclamação da República. Acesso por escuna da Marinha.",
                    en: "1889 neo-Gothic palace in Guanabara Bay. Last Empire ball before the Proclamation of the Republic. Access by Navy schooner.",
                    es: "Palacio neogótico de 1889 en la Bahía de Guanabara. Último baile del Imperio antes de la Proclamación de la República. Acceso por goleta de la Marina.",
                    fr: "Palais néo-gothique de 1889 dans la baie de Guanabara. Dernier bal de l'Empire avant la Proclamation de la République. Accès par goélette de la Marine.",
                    zh: "1889年建造的新哥特式宫殿，位于瓜纳巴拉湾。共和国宣布前帝国的最后一场舞会。乘坐海军帆船前往。"
                ),
                endereco: "Av. Alfred Agache, S/N - Centro, Rio de Janeiro",
                telefone: "(21) 2104-6992",website: nil,
                coordenadas: CLLocationCoordinate2D(latitude: -22.8967, longitude: -43.1667),
                avaliacao: 4.5
            ),
            
            // PRAIAS
            PontoTuristico(
                id: "5",
                nome: LocalizedText(
                    pt: "Praia de Copacabana",
                    en: "Copacabana Beach",
                    es: "Playa de Copacabana",
                    fr: "Plage de Copacabana",
                    zh: "科帕卡巴纳海滩"
                ),
                categoria: .praia,
                texto: LocalizedText(
                    pt: "Uma das praias mais famosas do mundo, com 4 km de extensão e o icônico calçadão de pedras portuguesas em ondas preto e branco. Palco do Réveillon mais famoso do Brasil.",
                    en: "One of the world's most famous beaches, 4 km long with the iconic Portuguese stone sidewalk in black and white waves. Stage of Brazil's most famous New Year's Eve celebration.",
                    es: "Una de las playas más famosas del mundo, con 4 km de extensión y el icónico paseo de piedras portuguesas en ondas blanco y negro. Escenario del Año Nuevo más famoso de Brasil.",
                    fr: "L'une des plages les plus célèbres du monde, longue de 4 km avec l'emblématique trottoir en pavés portugais aux vagues noires et blanches. Scène de la plus célèbre célébration du Nouvel An au Brésil.",
                    zh: "世界上最著名的海滩之一，长达4公里，拥有标志性的黑白波浪图案葡萄牙石人行道。巴西最著名的新年庆祝活动举办地。"
                ),
                endereco: "Av. Atlântica - Copacabana, Rio de Janeiro",telefone: nil, website: nil,
                coordenadas: CLLocationCoordinate2D(latitude: -22.9711, longitude: -43.1822),
                avaliacao: 4.5
            ),
            
            PontoTuristico(
                id: "6",
                nome: LocalizedText(
                    pt: "Praia de Ipanema",
                    en: "Ipanema Beach",
                    es: "Playa de Ipanema",
                    fr: "Plage d'Ipanema",
                    zh: "伊帕内玛海滩"
                ),
                categoria: .praia,
                texto: LocalizedText(
                    pt: "Imortalizada pela música 'Garota de Ipanema', é point da elite carioca. Dividida em postos, cada um com seu público específico: Posto 9 é famoso pela diversidade.",
                    en: "Immortalized by the song 'Girl from Ipanema', it's a hotspot for Rio's elite. Divided into posts, each with its specific crowd: Post 9 is famous for diversity.",
                    es: "Inmortalizada por la canción 'Chica de Ipanema', es punto de encuentro de la élite carioca. Dividida en puestos, cada uno con su público específico: Puesto 9 es famoso por la diversidad.",
                    fr: "Immortalisée par la chanson 'La Fille d'Ipanema', c'est le point de rencontre de l'élite de Rio. Divisée en postes, chacun avec son public spécifique: le Poste 9 est célèbre pour sa diversité.",
                    zh: "因歌曲《伊帕内玛女孩》而闻名，是里约精英的聚集地。分为不同的区域，每个区域都有特定的人群：9号哨所以多样性而闻名。"
                ),
                endereco: "Av. Vieira Souto - Ipanema, Rio de Janeiro",telefone: nil, website: nil,
                coordenadas: CLLocationCoordinate2D(latitude: -22.9839, longitude: -43.2045),
                avaliacao: 4.7
            ),
            
            PontoTuristico(
                id: "7",
                nome: LocalizedText(
                    pt: "Praia do Arpoador",
                    en: "Arpoador Beach",
                    es: "Playa del Arpoador",
                    fr: "Plage d'Arpoador",
                    zh: "阿尔波阿多海滩"
                ),
                categoria: .praia,
                texto: LocalizedText(
                    pt: "Pequena praia entre Ipanema e Copacabana, famosa pelo pôr do sol aplaudido diariamente. Point de surfistas e pescadores, com vista privilegiada para o Dois Irmãos.",
                    en: "Small beach between Ipanema and Copacabana, famous for the daily applauded sunset. Surfers and fishermen's spot, with privileged view of Dois Irmãos.",
                    es: "Pequeña playa entre Ipanema y Copacabana, famosa por la puesta de sol aplaudida diariamente. Punto de surfistas y pescadores, con vista privilegiada a los Dois Irmãos.",
                    fr: "Petite plage entre Ipanema et Copacabana, célèbre pour le coucher de soleil applaudi quotidiennement. Spot de surfeurs et pêcheurs, avec vue privilégiée sur les Dois Irmãos.",
                    zh: "位于伊帕内玛和科帕卡巴纳之间的小海滩，以每日受到掌声欢迎的日落而闻名。冲浪者和渔民的聚集地，可以欣赏到两兄弟山的美景。"
                ),
                endereco: "Entre Copacabana e Ipanema, Rio de Janeiro",telefone: nil, website: nil,
                coordenadas: CLLocationCoordinate2D(latitude: -22.9889, longitude: -43.1930),
                avaliacao: 4.8
            ),
            
            PontoTuristico(
                id: "8",
                nome: LocalizedText(
                    pt: "Praia da Barra da Tijuca",
                    en: "Barra da Tijuca Beach",
                    es: "Playa de Barra da Tijuca",
                    fr: "Plage de Barra da Tijuca",
                    zh: "巴拉达蒂茹卡海滩"
                ),
                categoria: .praia,
                texto: LocalizedText(
                    pt: "A maior praia do Rio com 18 km de extensão. Águas limpas e frias, ideal para esportes aquáticos. Conhecida pelos quiosques modernos e vida noturna agitada.",
                    en: "Rio's longest beach with 18 km of extension. Clean and cold waters, ideal for water sports. Known for modern kiosks and vibrant nightlife.",
                    es: "La playa más grande de Río con 18 km de extensión. Aguas limpias y frías, ideal para deportes acuáticos. Conocida por los quioscos modernos y vida nocturna agitada.",
                    fr: "La plus longue plage de Rio avec 18 km d'extension. Eaux propres et froides, idéales pour les sports nautiques. Connue pour ses kiosques modernes et sa vie nocturne animée.",
                    zh: "里约最长的海滩，延伸18公里。清澈寒冷的海水，非常适合水上运动。以现代化的售货亭和充满活力的夜生活而闻名。"
                ),
                endereco: "Av. do Pepê - Barra da Tijuca, Rio de Janeiro", telefone: nil, website: nil,
                coordenadas: CLLocationCoordinate2D(latitude: -23.0126, longitude: -43.3219),
                avaliacao: 4.4
            ),
            
            PontoTuristico(
                id: "29",
                nome: LocalizedText(
                    pt: "Prainha",
                    en: "Prainha Beach",
                    es: "Playa Prainha",
                    fr: "Plage Prainha",
                    zh: "小海滩"
                ),
                categoria: .praia,
                texto: LocalizedText(
                    pt: "Praia selvagem e preservada, cercada por morros e vegetação nativa. Águas cristalinas ideais para surf. Uma das praias mais bonitas e menos exploradas do Rio.",
                    en: "Wild and preserved beach, surrounded by hills and native vegetation. Crystal clear waters ideal for surfing. One of Rio's most beautiful and less explored beaches.",
                    es: "Playa salvaje y preservada, rodeada de cerros y vegetación nativa. Aguas cristalinas ideales para surf. Una de las playas más bonitas y menos exploradas de Río.",
                    fr: "Plage sauvage et préservée, entourée de collines et de végétation native. Eaux cristallines idéales pour le surf. L'une des plus belles plages les moins explorées de Rio.",
                    zh: "野生且保存完好的海滩，被山丘和原生植被环绕。水晶般清澈的海水非常适合冲浪。里约最美丽且较少被探索的海滩之一。"
                ),
                endereco: "Av. Estado da Guanabara - Recreio dos Bandeirantes, Rio de Janeiro", telefone: nil, website: nil,
                coordenadas: CLLocationCoordinate2D(latitude: -23.0407, longitude: -43.5047),
                avaliacao: 4.7
            ),
            
            PontoTuristico(
                id: "30",
                nome: LocalizedText(
                    pt: "Praia do Leblon",
                    en: "Leblon Beach",
                    es: "Playa de Leblon",
                    fr: "Plage de Leblon",
                    zh: "莱布隆海滩"
                ),
                categoria: .praia,
                texto: LocalizedText(
                    pt: "Continuação de Ipanema, separada pelo canal do Jardim de Alah. Praia mais exclusiva, frequentada por moradores do bairro nobre. Área kids e quadras esportivas.",
                    en: "Continuation of Ipanema, separated by the Jardim de Alah channel. More exclusive beach, frequented by residents of the upscale neighborhood. Kids area and sports courts.",
                    es: "Continuación de Ipanema, separada por el canal del Jardim de Alah. Playa más exclusiva, frecuentada por residentes del barrio noble. Área kids y canchas deportivas.",
                    fr: "Continuation d'Ipanema, séparée par le canal Jardim de Alah. Plage plus exclusive, fréquentée par les résidents du quartier huppé. Espace enfants et terrains de sport.",
                    zh: "伊帕内玛的延伸，由阿拉花园运河分隔。更加独特的海滩，高档社区居民常来此地。设有儿童区和运动场。"
                ),
                endereco: "Av. Delfim Moreira - Leblon, Rio de Janeiro", telefone: nil, website: nil,
                coordenadas: CLLocationCoordinate2D(latitude: -22.9867, longitude: -43.2242),
                avaliacao: 4.6
            ),
            
            // PARQUES
            PontoTuristico(
                id: "9",
                nome: LocalizedText(
                    pt: "Jardim Botânico",
                    en: "Botanical Garden",
                    es: "Jardín Botánico",
                    fr: "Jardin Botanique",
                    zh: "植物园"
                ),
                categoria: .parque,
                texto: LocalizedText(
                    pt: "Fundado em 1808 por D. João VI, possui mais de 6.500 espécies de plantas. Destaque para as palmeiras imperiais, vitórias-régias e o orquidário com 700 espécies.",
                    en: "Founded in 1808 by King João VI, it has over 6,500 plant species. Highlights include imperial palm trees, giant water lilies and the orchid garden with 700 species.",
                    es: "Fundado en 1808 por D. João VI, posee más de 6.500 especies de plantas. Destaque para las palmeras imperiales, victorias regias y el orquideario con 700 especies.",
                    fr: "Fondé en 1808 par D. João VI, il possède plus de 6 500 espèces de plantes. Points forts: les palmiers impériaux, les nénuphars géants et l'orchidarium avec 700 espèces.",
                    zh: "由若昂六世于1808年建立，拥有超过6500种植物。亮点包括帝王棕榈树、王莲和拥有700种兰花的兰花园。"
                ),
                endereco: "R. Jardim Botânico, 1008 - Jardim Botânico, Rio de Janeiro",
                telefone: "(21) 3874-1808",
                website: "https://jbrj.gov.br",
                coordenadas: CLLocationCoordinate2D(latitude: -22.9674, longitude: -43.2239),
                avaliacao: 4.6
            ),
            
            PontoTuristico(
                id: "10",
                nome: LocalizedText(
                    pt: "Parque Lage",
                    en: "Lage Park",
                    es: "Parque Lage",
                    fr: "Parc Lage",
                    zh: "拉赫公园"
                ),
                categoria: .parque,
                texto: LocalizedText(
                    pt: "Palacete do século XX aos pés do Corcovado, cercado por jardins românticos. Abriga a Escola de Artes Visuais e um café charmoso com vista para o Cristo.",
                    en: "20th century mansion at the foot of Corcovado, surrounded by romantic gardens. Houses the Visual Arts School and a charming café with views of Christ statue.",
                    es: "Palacete del siglo XX a los pies del Corcovado, rodeado por jardines románticos. Alberga la Escuela de Artes Visuales y un café encantador con vista al Cristo.",
                    fr: "Petit palais du XXe siècle au pied du Corcovado, entouré de jardins romantiques. Abrite l'École des Arts Visuels et un charmant café avec vue sur le Christ.",
                    zh: "20世纪的宫殿位于科尔科瓦多山脚下，被浪漫的花园环绕。设有视觉艺术学校和一家迷人的咖啡馆，可以欣赏到基督像的景色。"
                ),
                endereco: "R. Jardim Botânico, 414 - Jardim Botânico, Rio de Janeiro",
                telefone: "(21) 2334-4088", website: nil,
                coordenadas: CLLocationCoordinate2D(latitude: -22.9618, longitude: -43.2111),
                avaliacao: 4.5
            ),
            
            PontoTuristico(
                id: "11",
                nome: LocalizedText(
                    pt: "Parque Nacional da Tijuca",
                    en: "Tijuca National Park",
                    es: "Parque Nacional de Tijuca",
                    fr: "Parc National de Tijuca",
                    zh: "蒂茹卡国家公园"
                ),
                categoria: .parque,
                texto: LocalizedText(
                    pt: "Uma das maiores florestas urbanas do mundo, com trilhas, cachoeiras e mirantes. Inclui o Corcovado, a Pedra da Gávea e o Pico da Tijuca, ponto mais alto da cidade.",
                    en: "One of the world's largest urban forests, with trails, waterfalls and viewpoints. Includes Corcovado, Pedra da Gávea and Pico da Tijuca, the city's highest point.",
                    es: "Una de las mayores florestas urbanas del mundo, con senderos, cascadas y miradores. Incluye el Corcovado, la Pedra da Gávea y el Pico da Tijuca, punto más alto de la ciudad.",
                    fr: "L'une des plus grandes forêts urbaines du monde, avec des sentiers, des cascades et des points de vue. Comprend le Corcovado, Pedra da Gávea et Pico da Tijuca, le point culminant de la ville.",
                    zh: "世界上最大的城市森林之一，有步道、瀑布和观景点。包括科尔科瓦多山、加维亚岩石和蒂茹卡峰——城市的最高点。"
                ),
                endereco: "Estrada da Cascatinha, 850 - Alto da Boa Vista, Rio de Janeiro",
                telefone: "(21) 2492-2253",
                website: "https://parquenacionaldatijuca.rio",
                coordenadas: CLLocationCoordinate2D(latitude: -22.9494, longitude: -43.2839),
                avaliacao: 4.7
            ),
            
            PontoTuristico(
                id: "31",
                nome: LocalizedText(
                    pt: "Parque do Flamengo",
                    en: "Flamengo Park",
                    es: "Parque del Flamengo",
                    fr: "Parc du Flamengo",
                    zh: "弗拉门戈公园"
                ),
                categoria: .parque,
                texto: LocalizedText(
                    pt: "Maior área de lazer ao ar livre do Rio. Projeto paisagístico de Burle Marx com 1,2 milhão de m². Ciclovia, quadras esportivas, Marina da Glória e MAM.",
                    en: "Rio's largest outdoor leisure area. Landscaping project by Burle Marx with 1.2 million m². Bike path, sports courts, Marina da Glória and MAM.",
                    es: "Mayor área de ocio al aire libre de Río. Proyecto paisajístico de Burle Marx con 1,2 millones de m². Ciclovía, canchas deportivas, Marina da Glória y MAM.",
                    fr: "Plus grande zone de loisirs en plein air de Rio. Projet paysager de Burle Marx avec 1,2 million de m². Piste cyclable, terrains de sport, Marina da Glória et MAM.",
                    zh: "里约最大的户外休闲区。由布尔勒·马克思设计的景观项目，占地120万平方米。自行车道、运动场、格洛里亚码头和现代艺术博物馆。"
                ),
                endereco: "Av. Infante Dom Henrique - Flamengo, Rio de Janeiro", telefone: nil, website: nil,
                coordenadas: CLLocationCoordinate2D(latitude: -22.9230, longitude: -43.1729),
                avaliacao: 4.5
            ),
            
            PontoTuristico(
                id: "32",
                nome: LocalizedText(
                    pt: "Quinta da Boa Vista",
                    en: "Quinta da Boa Vista",
                    es: "Quinta da Boa Vista",
                    fr: "Quinta da Boa Vista",
                    zh: "博阿维斯塔庄园"
                ),
                categoria: .parque,
                texto: LocalizedText(
                    pt: "Antigo jardim imperial, foi residência da família real portuguesa. Abriga o Museu Nacional (em reconstrução) e o Zoológico do Rio. Lagos, grutas e amplas áreas verdes.",
                    en: "Former imperial garden, was residence of the Portuguese royal family. Houses the National Museum (under reconstruction) and Rio Zoo. Lakes, caves and wide green areas.",
                    es: "Antiguo jardín imperial, fue residencia de la familia real portuguesa. Alberga el Museo Nacional (en reconstrucción) y el Zoológico de Río. Lagos, grutas y amplias áreas verdes.",
                    fr: "Ancien jardin impérial, résidence de la famille royale portugaise. Abrite le Musée National (en reconstruction) et le Zoo de Rio. Lacs, grottes et vastes espaces verts.",
                    zh: "前帝国花园，曾是葡萄牙王室的住所。设有国家博物馆（重建中）和里约动物园。湖泊、洞穴和广阔的绿地。"
                ),
                endereco: "Av. Pedro II, S/N - São Cristóvão, Rio de Janeiro", telefone: nil, website: nil,
                coordenadas: CLLocationCoordinate2D(latitude: -22.9058, longitude: -43.2239),
                avaliacao: 4.2
            ),
            
            PontoTuristico(
                id: "40",
                nome: LocalizedText(
                    pt: "Lagoa Rodrigo de Freitas",
                    en: "Rodrigo de Freitas Lagoon",
                    es: "Laguna Rodrigo de Freitas",
                    fr: "Lagune Rodrigo de Freitas",
                    zh: "罗德里戈·德·弗雷塔斯湖"
                ),
                categoria: .parque,
                texto: LocalizedText(
                    pt: "Espelho d'água de 2,2 km² no coração da zona sul. Pista de 7,5 km para caminhada e ciclismo. Pedalinhos, gastronomia e vista para o Cristo e Corcovado.",
                    en: "2.2 km² water mirror in the heart of the south zone. 7.5 km track for walking and cycling. Paddle boats, gastronomy and views of Christ and Corcovado.",
                    es: "Espejo de agua de 2,2 km² en el corazón de la zona sur. Pista de 7,5 km para caminata y ciclismo. Botes a pedal, gastronomía y vista al Cristo y Corcovado.",
                    fr: "Miroir d'eau de 2,2 km² au cœur de la zone sud. Piste de 7,5 km pour la marche et le cyclisme. Pédalos, gastronomie et vue sur le Christ et le Corcovado.",
                    zh: "位于南区中心的2.2平方公里的水域。7.5公里的步行和自行车道。脚踏船、美食以及基督像和科尔科瓦多山的景色。"
                ),
                endereco: "Av. Borges de Medeiros - Lagoa, Rio de Janeiro", telefone: nil, website: nil,
                coordenadas: CLLocationCoordinate2D(latitude: -22.9714, longitude: -43.2055),
                avaliacao: 4.5
            ),
            
            // MUSEUS
            PontoTuristico(
                id: "12",
                nome: LocalizedText(
                    pt: "Museu do Amanhã",
                    en: "Museum of Tomorrow",
                    es: "Museo del Mañana",
                    fr: "Musée de Demain",
                    zh: "明日博物馆"
                ),
                categoria: .museu,
                texto: LocalizedText(
                    pt: "Museu de ciências projetado por Santiago Calatrava. Explora possibilidades de futuro sustentável através de exposições interativas sobre cosmos, terra, antropoceno e amanhã.",
                    en: "Science museum designed by Santiago Calatrava. Explores possibilities for a sustainable future through interactive exhibitions about cosmos, earth, anthropocene and tomorrow.",
                    es: "Museo de ciencias diseñado por Santiago Calatrava. Explora posibilidades de futuro sostenible a través de exposiciones interactivas sobre cosmos, tierra, antropoceno y mañana.",
                    fr: "Musée des sciences conçu par Santiago Calatrava. Explore les possibilités d'un avenir durable à travers des expositions interactives sur le cosmos, la terre, l'anthropocène et demain.",
                    zh: "由圣地亚哥·卡拉特拉瓦设计的科学博物馆。通过关于宇宙、地球、人类世和未来的互动展览，探索可持续未来的可能性。"
                ),
                endereco: "Praça Mauá, 1 - Centro, Rio de Janeiro",
                telefone: "(21) 3812-1800",
                website: "https://museudoamanha.org.br",
                coordenadas: CLLocationCoordinate2D(latitude: -22.8945, longitude: -43.1809),
                avaliacao: 4.5
            ),
            
            PontoTuristico(
                id: "13",
                nome: LocalizedText(
                    pt: "Museu de Arte do Rio (MAR)",
                    en: "Rio Art Museum (MAR)",
                    es: "Museo de Arte de Río (MAR)",
                    fr: "Musée d'Art de Rio (MAR)",
                    zh: "里约艺术博物馆"
                ),
                categoria: .museu,
                texto: LocalizedText(
                    pt: "Dedicado à arte e cultura visual do Rio. Ocupa dois prédios interligados: o Palacete Dom João VI e o edifício modernista. Vista panorâmica da Baía de Guanabara.",
                    en: "Dedicated to Rio's art and visual culture. Occupies two interconnected buildings: Dom João VI Palace and the modernist building. Panoramic view of Guanabara Bay.",
                    es: "Dedicado al arte y cultura visual de Río. Ocupa dos edificios interconectados: el Palacete Dom João VI y el edificio modernista. Vista panorámica de la Bahía de Guanabara.",
                    fr: "Dédié à l'art et à la culture visuelle de Rio. Occupe deux bâtiments interconnectés: le Palais Dom João VI et le bâtiment moderniste. Vue panoramique sur la baie de Guanabara.",
                    zh: "致力于里约的艺术和视觉文化。占据两座相互连接的建筑：若昂六世宫殿和现代主义建筑。瓜纳巴拉湾的全景。"
                ),
                endereco: "Praça Mauá, 5 - Centro, Rio de Janeiro",
                telefone: "(21) 3031-2741",
                website: "https://museudeartedorio.org.br",
                coordenadas: CLLocationCoordinate2D(latitude: -22.8966, longitude: -43.1807),
                avaliacao: 4.4
            ),
            
            PontoTuristico(
                id: "14",
                nome: LocalizedText(
                    pt: "Museu Nacional de Belas Artes",
                    en: "National Museum of Fine Arts",
                    es: "Museo Nacional de Bellas Artes",
                    fr: "Musée National des Beaux-Arts",
                    zh: "国家美术博物馆"
                ),
                categoria: .museu,
                texto: LocalizedText(
                    pt: "Principal museu de arte do Brasil, com acervo de 70 mil peças. Destaque para a coleção de arte brasileira do século XIX e obras de Portinari, Di Cavalcanti e Tarsila.",
                    en: "Brazil's main art museum, with a collection of 70,000 pieces. Highlights include the 19th century Brazilian art collection and works by Portinari, Di Cavalcanti and Tarsila.",
                    es: "Principal museo de arte de Brasil, con colección de 70 mil piezas. Destaque para la colección de arte brasileño del siglo XIX y obras de Portinari, Di Cavalcanti y Tarsila.",
                    fr: "Principal musée d'art du Brésil, avec une collection de 70 000 pièces. Points forts: la collection d'art brésilien du XIXe siècle et les œuvres de Portinari, Di Cavalcanti et Tarsila.",
                    zh: "巴西主要的艺术博物馆，收藏了7万件作品。亮点包括19世纪的巴西艺术收藏以及波蒂纳里、迪·卡瓦尔坎蒂和塔西拉的作品。"
                ),
                endereco: "Av. Rio Branco, 199 - Centro, Rio de Janeiro",
                telefone: "(21) 2240-0068",
                website: "https://mnba.gov.br",
                coordenadas: CLLocationCoordinate2D(latitude: -22.9094, longitude: -43.1751),
                avaliacao: 4.3
            ),
            
            PontoTuristico(
                id: "33",
                nome: LocalizedText(
                    pt: "Museu Histórico Nacional",
                    en: "National Historical Museum",
                    es: "Museo Histórico Nacional",
                    fr: "Musée Historique National",
                    zh: "国家历史博物馆"
                ),
                categoria: .museu,
                texto: LocalizedText(
                    pt: "Maior museu de história do Brasil, com 287 mil itens. Ocupa conjunto arquitetônico que inclui o Forte de Santiago. Exposições sobre a formação da nação brasileira.",
                    en: "Brazil's largest history museum, with 287,000 items. Occupies architectural complex including Santiago Fort. Exhibitions about the formation of the Brazilian nation.",
                    es: "Mayor museo de historia de Brasil, con 287 mil ítems. Ocupa conjunto arquitectónico que incluye el Fuerte de Santiago. Exposiciones sobre la formación de la nación brasileña.",
                    fr: "Plus grand musée d'histoire du Brésil, avec 287 000 articles. Occupe un complexe architectural comprenant le Fort de Santiago. Expositions sur la formation de la nation brésilienne.",
                    zh: "巴西最大的历史博物馆，拥有28.7万件物品。占据包括圣地亚哥堡垒在内的建筑群。关于巴西民族形成的展览。"
                ),
                endereco: "Praça Marechal Âncora, S/N - Centro, Rio de Janeiro",
                telefone: "(21) 3299-0324",
                website: "https://mhn.museus.gov.br",
                coordenadas: CLLocationCoordinate2D(latitude: -22.9052, longitude: -43.1694),
                avaliacao: 4.4
            ),
            
            // CULTURA
            PontoTuristico(
                id: "15",
                nome: LocalizedText(
                    pt: "Lapa e Arcos da Lapa",
                    en: "Lapa and Lapa Arches",
                    es: "Lapa y Arcos de Lapa",
                    fr: "Lapa et Arcs de Lapa",
                    zh: "拉帕区和拉帕拱门"
                ),
                categoria: .cultura,
                texto: LocalizedText(
                    pt: "Antigo aqueduto colonial, hoje símbolo da boemia carioca. A região é conhecida pela vida noturna, samba, bares históricos e a famosa Escadaria Selarón.",
                    en: "Former colonial aqueduct, now symbol of Rio's bohemian life. The region is known for nightlife, samba, historic bars and the famous Selarón Steps.",
                    es: "Antiguo acueducto colonial, hoy símbolo de la bohemia carioca. La región es conocida por la vida nocturna, samba, bares históricos y la famosa Escalera Selarón.",
                    fr: "Ancien aqueduc colonial, aujourd'hui symbole de la vie bohème de Rio. La région est connue pour sa vie nocturne, la samba, les bars historiques et le célèbre Escalier Selarón.",
                    zh: "前殖民地水渠，现在是里约波西米亚生活的象征。该地区以夜生活、桑巴舞、历史悠久的酒吧和著名的塞勒隆阶梯而闻名。"
                ),
                endereco: "Largo da Lapa - Centro, Rio de Janeiro", telefone: nil, website: nil,
                coordenadas: CLLocationCoordinate2D(latitude: -22.9134, longitude: -43.1803),
                avaliacao: 4.5
            ),
            
            PontoTuristico(
                id: "16",
                nome: LocalizedText(
                    pt: "Centro Cultural Banco do Brasil",
                    en: "Bank of Brazil Cultural Center",
                    es: "Centro Cultural Banco de Brasil",
                    fr: "Centre Culturel Banco do Brasil",
                    zh: "巴西银行文化中心"
                ),
                categoria: .cultura,
                texto: LocalizedText(
                    pt: "Um dos centros culturais mais visitados do mundo. Prédio histórico de 1906 que abriga exposições, teatro, cinema e música. Arquitetura neoclássica preservada.",
                    en: "One of the world's most visited cultural centers. Historic 1906 building housing exhibitions, theater, cinema and music. Preserved neoclassical architecture.",
                    es: "Uno de los centros culturales más visitados del mundo. Edificio histórico de 1906 que alberga exposiciones, teatro, cine y música. Arquitectura neoclásica preservada.",
                    fr: "L'un des centres culturels les plus visités au monde. Bâtiment historique de 1906 abritant expositions, théâtre, cinéma et musique. Architecture néoclassique préservée.",
                    zh: "世界上参观人数最多的文化中心之一。1906年的历史建筑，举办展览、戏剧、电影和音乐活动。保存完好的新古典主义建筑。"
                ),
                endereco: "R. Primeiro de Março, 66 - Centro, Rio de Janeiro",
                telefone: "(21) 3808-2020",
                website: "https://ccbb.com.br/rio-de-janeiro",
                coordenadas: CLLocationCoordinate2D(latitude: -22.9027, longitude: -43.1763),
                avaliacao: 4.6
            ),
            
            PontoTuristico(
                id: "17",
                nome: LocalizedText(
                    pt: "Feira de São Cristóvão",
                    en: "São Cristóvão Fair",
                    es: "Feria de São Cristóvão",
                    fr: "Foire de São Cristóvão",
                    zh: "圣克里斯托旺集市"
                ),
                categoria: .cultura,
                texto: LocalizedText(
                    pt: "Centro de tradições nordestinas no Rio. Mais de 700 barracas com artesanato, comidas típicas e shows de forró. Funciona como uma mini cidade nordestina.",
                    en: "Center of Northeastern traditions in Rio. Over 700 stalls with handicrafts, typical foods and forró shows. Works as a mini Northeastern city.",
                    es: "Centro de tradiciones nordestinas en Río. Más de 700 puestos con artesanía, comidas típicas y shows de forró. Funciona como una mini ciudad nordestina.",
                    fr: "Centre des traditions du Nord-Est à Rio. Plus de 700 stands avec artisanat, plats typiques et spectacles de forró. Fonctionne comme une mini-ville du Nord-Est.",
                    zh: "里约的东北传统中心。超过700个摊位，出售手工艺品、特色食品并举办福鸥舞表演。就像一个迷你的东北城市。"
                ),
                endereco: "Campo de São Cristóvão, S/N - São Cristóvão, Rio de Janeiro",
                telefone: "(21) 2580-5335",
                website: "https://feiradesaocristovao.org.br",
                coordenadas: CLLocationCoordinate2D(latitude: -22.8965, longitude: -43.2227),
                avaliacao: 4.4
            ),
            
            PontoTuristico(
                id: "34",
                nome: LocalizedText(
                    pt: "Confeitaria Colombo",
                    en: "Colombo Confectionery",
                    es: "Confitería Colombo",
                    fr: "Confiserie Colombo",
                    zh: "科伦坡糖果店"
                ),
                categoria: .cultura,
                texto: LocalizedText(
                    pt: "Fundada em 1894, é patrimônio cultural e artístico. Espelhos belgas, cristais e mobiliário art nouveau. Serviu a família imperial e grandes personalidades.",
                    en: "Founded in 1894, it's cultural and artistic heritage. Belgian mirrors, crystals and art nouveau furniture. Served the imperial family and great personalities.",
                    es: "Fundada en 1894, es patrimonio cultural y artístico. Espejos belgas, cristales y mobiliario art nouveau. Sirvió a la familia imperial y grandes personalidades.",
                    fr: "Fondée en 1894, c'est un patrimoine culturel et artistique. Miroirs belges, cristaux et mobilier art nouveau. A servi la famille impériale et de grandes personnalités.",
                    zh: "创立于1894年，是文化和艺术遗产。比利时镜子、水晶和新艺术风格家具。曾为帝国家族和名人提供服务。"
                ),
                endereco: "R. Gonçalves Dias, 32 - Centro, Rio de Janeiro",
                telefone: "(21) 2505-1500",
                website: "https://confeitariacolombo.com.br",
                coordenadas: CLLocationCoordinate2D(latitude: -22.9054, longitude: -43.1779),
                avaliacao: 4.5
            ),
            
            PontoTuristico(
                id: "35",
                nome: LocalizedText(
                    pt: "Casa França-Brasil",
                    en: "France-Brazil House",
                    es: "Casa Francia-Brasil",
                    fr: "Maison France-Brésil",
                    zh: "法国-巴西之家"
                ),
                categoria: .cultura,
                texto: LocalizedText(
                    pt: "Primeira construção neoclássica do Brasil (1820). Projetada por Grandjean de Montigny, hoje é centro cultural com exposições de arte contemporânea.",
                    en: "Brazil's first neoclassical construction (1820). Designed by Grandjean de Montigny, today it's a cultural center with contemporary art exhibitions.",
                    es: "Primera construcción neoclásica de Brasil (1820). Diseñada por Grandjean de Montigny, hoy es centro cultural con exposiciones de arte contemporáneo.",
                    fr: "Première construction néoclassique du Brésil (1820). Conçue par Grandjean de Montigny, c'est aujourd'hui un centre culturel avec des expositions d'art contemporain.",
                    zh: "巴西第一座新古典主义建筑（1820年）。由格兰让·德·蒙蒂尼设计，现在是举办当代艺术展览的文化中心。"
                ),
                endereco: "R. Visconde de Itaboraí, 78 - Centro, Rio de Janeiro",
                telefone: "(21) 2253-5366", website: nil,
                coordenadas: CLLocationCoordinate2D(latitude: -22.9022, longitude: -43.1757),
                avaliacao: 4.3
            ),
            
            PontoTuristico(
                id: "42",
                nome: LocalizedText(
                    pt: "AquaRio",
                    en: "AquaRio",
                    es: "AquaRio",
                    fr: "AquaRio",
                    zh: "里约水族馆"
                ),
                categoria: .cultura,
                texto: LocalizedText(
                    pt: "Maior aquário marinho da América do Sul. 28 tanques, 5 milhões de litros de água e 8 mil animais de 350 espécies. Túnel oceânico e tanque de tubarões.",
                    en: "South America's largest marine aquarium. 28 tanks, 5 million liters of water and 8,000 animals from 350 species. Ocean tunnel and shark tank.",
                    es: "Mayor acuario marino de América del Sur. 28 tanques, 5 millones de litros de agua y 8 mil animales de 350 especies. Túnel oceánico y tanque de tiburones.",
                    fr: "Plus grand aquarium marin d'Amérique du Sud. 28 bassins, 5 millions de litres d'eau et 8 000 animaux de 350 espèces. Tunnel océanique et bassin de requins.",
                    zh: "南美洲最大的海洋水族馆。28个水箱，500万升水，来自350个物种的8000只动物。海洋隧道和鲨鱼池。"
                ),
                endereco: "Praça Muhammad Ali - Gamboa, Rio de Janeiro",
                telefone: "(21) 3900-0100",
                website: "https://www.aquariomarinhodorio.com.br",
                coordenadas: CLLocationCoordinate2D(latitude: -22.8920, longitude: -43.1912),
                avaliacao: 4.6
            ),
            
            PontoTuristico(
                id: "43",
                nome: LocalizedText(
                    pt: "Boulevard Olímpico",
                    en: "Olympic Boulevard",
                    es: "Bulevar Olímpico",
                    fr: "Boulevard Olympique",
                    zh: "奥林匹克大道"
                ),
                categoria: .cultura,
                texto: LocalizedText(
                    pt: "Revitalização da zona portuária para as Olimpíadas 2016. Murais de grafite, museus, restaurantes e espaços culturais. Roda gigante Rio Star de 88m de altura.",
                    en: "Port area revitalization for 2016 Olympics. Graffiti murals, museums, restaurants and cultural spaces. 88m high Rio Star Ferris wheel.",
                    es: "Revitalización de la zona portuaria para las Olimpiadas 2016. Murales de grafiti, museos, restaurantes y espacios culturales. Rueda gigante Rio Star de 88m de altura.",
                    fr: "Revitalisation de la zone portuaire pour les JO 2016. Fresques de graffitis, musées, restaurants et espaces culturels. Grande roue Rio Star de 88m de hauteur.",
                    zh: "为2016年奥运会重新规划的港口区。涂鸦壁画、博物馆、餐厅和文化空间。88米高的里约之星摩天轮。"
                ),
                endereco: "Av. Rodrigues Alves - Centro, Rio de Janeiro", telefone: nil, website: nil,
                coordenadas: CLLocationCoordinate2D(latitude: -22.8933, longitude: -43.1853),
                avaliacao: 4.3
            ),
            
            PontoTuristico(
                id: "45",
                nome: LocalizedText(
                    pt: "Santa Teresa",
                    en: "Santa Teresa",
                    es: "Santa Teresa",
                    fr: "Santa Teresa",
                    zh: "圣特雷莎"
                ),
                categoria: .cultura,
                texto: LocalizedText(
                    pt: "Bairro boêmio nas montanhas com arquitetura colonial preservada. Ateliês de artistas, bares culturais, restaurantes e o famoso Bonde de Santa Teresa.",
                    en: "Bohemian neighborhood in the mountains with preserved colonial architecture. Artist studios, cultural bars, restaurants and the famous Santa Teresa Tram.",
                    es: "Barrio bohemio en las montañas con arquitectura colonial preservada. Talleres de artistas, bares culturales, restaurantes y el famoso Tranvía de Santa Teresa.",
                    fr: "Quartier bohème dans les montagnes avec une architecture coloniale préservée. Ateliers d'artistes, bars culturels, restaurants et le célèbre tramway de Santa Teresa.",
                    zh: "山中的波西米亚社区，保留着殖民地建筑。艺术家工作室、文化酒吧、餐厅和著名的圣特雷莎电车。"
                ),
                endereco: "Bairro de Santa Teresa - Rio de Janeiro", telefone: nil, website: nil,
                coordenadas: CLLocationCoordinate2D(latitude: -22.9178, longitude: -43.1858),
                avaliacao: 4.4
            )] // Os dados originais devem ser mantidos aqui
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

// MARK: - PontoTuristico com suporte a múltiplos idiomas


