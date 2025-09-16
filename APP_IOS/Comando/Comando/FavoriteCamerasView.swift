import SwiftUI
import MapKit
import CoreLocation

// MARK: - Tela Principal de Favoritos
struct FavoriteCamerasView: View {
    // MARK: Propriedades e Dependências
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var favoritesManager: FavoritesManager
    @EnvironmentObject private var localizationManager: LocalizationManager

    let allCameras: [Camera]
    var onCameraSelect: ((Camera) -> Void)?

    // MARK: Estado da View
    @State private var favoriteCameras: [Camera] = []
    @State private var selectedCamera: Camera?
    @State private var searchText = ""
    @State private var showRemoveConfirmation = false
    @State private var cameraToRemove: Camera?

    /// Filtra a lista de favoritos (que já está em estado) com base na busca. É muito mais rápido.
    var filteredCameras: [Camera] {
        if searchText.isEmpty {
            return favoriteCameras
        }
        return favoriteCameras.filter { camera in
            camera.nome?.localizedCaseInsensitiveContains(searchText) ?? false
        }
    }

    // MARK: Corpo da View
    var body: some View {
        ZStack {
            // Fundo gradiente
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.05, green: 0.1, blue: 0.2),
                    Color(red: 0.1, green: 0.2, blue: 0.3)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header (sem alterações de funcionalidade)
                headerView
                
                // Conteúdo Principal
                contentView
            }
        }
        // ✅✅✅ CORREÇÃO APLICADA AQUI ✅✅✅
        .fullScreenCover(item: $selectedCamera) { camera in
            // A chamada para CameraDetailView foi simplificada.
            CameraDetailView(camera: camera)
                .environmentObject(favoritesManager)
                .environmentObject(localizationManager)
        }
        .alert(localizationManager.string(for: "remove_from_favorites"), isPresented: $showRemoveConfirmation, actions: {
            Button(localizationManager.string(for: "cancel"), role: .cancel) { }
            Button(localizationManager.string(for: "remove"), role: .destructive) {
                if let camera = cameraToRemove {
                    favoritesManager.removeFavorite(camera.id)
                }
            }
        }, message: {
            Text(String(format: localizationManager.string(for: "remove_camera_from_favorites_message"),
                         cameraToRemove?.nome ?? localizationManager.string(for: "camera")))
        })
        .onAppear(perform: updateFavoriteCameras)
        .onReceive(favoritesManager.$favoriteCameraIds) { _ in
            updateFavoriteCameras()
        }
    }

    // MARK: Funções Auxiliares
    
    /// Atualiza a lista de estado `favoriteCameras` de forma eficiente.
    private func updateFavoriteCameras() {
        withAnimation(.easeInOut) {
            favoriteCameras = allCameras.filter { favoritesManager.isFavorite($0.id) }
        }
    }
    
    // MARK: Subviews
    
    /// View do cabeçalho, contendo título e barra de busca.
    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                .accessibilityLabel(localizationManager.string(for: "back"))
                
                Spacer()
                
                VStack(spacing: 4) {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text(localizationManager.string(for: "favorites"))
                            .font(.title2.bold())
                            .foregroundColor(.white)
                    }
                    
                    Text(String(format: localizationManager.string(for: "cameras_count"), favoriteCameras.count))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Espaço para manter o título centralizado corretamente
                Color.clear
                    .frame(width: 44, height: 44)
            }
            .padding(.horizontal)
            
            // Barra de busca
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField(localizationManager.string(for: "search_in_favorites"), text: $searchText)
                    .foregroundColor(.white)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(12)
            .background(Color.white.opacity(0.1))
            .cornerRadius(10)
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(
             LinearGradient(
                 gradient: Gradient(colors: [
                     Color(red: 0.1, green: 0.5, blue: 0.9).opacity(0.4),
                     Color(red: 0.3, green: 0.6, blue: 0.9).opacity(0.2)
                 ]),
                 startPoint: .top,
                 endPoint: .bottom
             )
         )
    }
    
    /// View do conteúdo, que mostra a lista ou as mensagens de estado vazio.
    @ViewBuilder
    private var contentView: some View {
        if favoriteCameras.isEmpty {
            EmptyFavoritesView()
        } else if filteredCameras.isEmpty {
            NoSearchResultsView()
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredCameras) { camera in
                        FavoriteCameraRow(
                            camera: camera,
                            onTap: {
                                selectedCamera = camera
                            },
                            onRemove: {
                                cameraToRemove = camera
                                showRemoveConfirmation = true
                            }
                        )
                    }
                }
                .padding()
            }
        }
    }
}

// MARK: - Célula da Lista de Favoritos (Row)
struct FavoriteCameraRow: View {
    let camera: Camera
    let onTap: () -> Void
    let onRemove: () -> Void
    
    @EnvironmentObject private var localizationManager: LocalizationManager
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "video.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(camera.nome ?? localizationManager.string(for: "camera_no_name"))
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                if let apiId = camera.apiId {
                    Text("ID: \(apiId)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Button(action: onRemove) {
                Image(systemName: "star.slash.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.yellow.opacity(0.8))
                    .padding(8)
            }
            .accessibilityLabel(localizationManager.string(for: "remove_from_favorites"))
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
                }
            }
            onTap()
        }
    }
}

// MARK: - View para Estado Vazio (Sem Favoritos)
struct EmptyFavoritesView: View {
    @EnvironmentObject private var localizationManager: LocalizationManager

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "star.slash")
                .font(.system(size: 80))
                .foregroundColor(.white.opacity(0.3))
            
            Text(localizationManager.string(for: "no_favorite_cameras"))
                .font(.title2)
                .foregroundColor(.white.opacity(0.7))
            
            Text(localizationManager.string(for: "tap_star_to_add_favorite"))
                .font(.body)
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }
}

// MARK: - View para Estado Vazio (Sem Resultados de Busca)
struct NoSearchResultsView: View {
    @EnvironmentObject private var localizationManager: LocalizationManager

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))
            
            Text(localizationManager.string(for: "no_results_found"))
                .font(.title3)
                .foregroundColor(.white.opacity(0.7))
            Spacer()
        }
    }
}
