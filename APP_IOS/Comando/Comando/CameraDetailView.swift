import SwiftUI
import WebKit
import UIKit

// MARK: - Tela de Detalhes da Câmera (Força retrato e aspect-fit)
struct CameraDetailView: View {
    let camera: Camera
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var favoritesManager: FavoritesManager
    @EnvironmentObject private var localizationManager: LocalizationManager
    @StateObject private var orientationManager = OrientationManager.shared
    
    @State private var isLoading: Bool = true
    @State private var error: Error? = nil
    
    private var streamURL: URL? {
        guard let apiId = camera.apiId else { return nil }
        return URL(string: "https://aplicativo.cocr.com.br/camera/\(apiId)")
    }
    
    private var isCurrentlyFavorite: Bool {
        favoritesManager.isFavorite(camera.id)
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Barra superior
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.body.weight(.bold))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(8)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel(localizationManager.string(for: "close"))
                    
                    Spacer()
                    
                    Text(camera.nome ?? localizationManager.string(for: "camera"))
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Button(action: {
                        favoritesManager.toggleFavorite(camera.id)
                    }) {
                        Image(systemName: isCurrentlyFavorite ? "star.fill" : "star")
                            .font(.title2)
                            .foregroundColor(isCurrentlyFavorite ? .yellow : .white)
                            .padding(10)
                            .background(.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel(isCurrentlyFavorite ?
                        localizationManager.string(for: "remove_from_favorites") :
                        localizationManager.string(for: "add_to_favorites"))
                }
                .padding()
                
                // Conteúdo principal
                ZStack {
                    if let url = streamURL {
                        WebView(
                            url: url,
                            isScrollEnabled: false,
                            coverMode: false,
                            fitMode: true,                 // ✅ aspect-fit (sem cortes)
                            rotate90: true,                // ✅ rotacionar 90°
                            isLoading: $isLoading,
                            error: $error
                        )
                        .background(Color.black)
                        .ignoresSafeArea()
                    } else {
                        Text(localizationManager.string(for: "invalid_camera_id"))
                            .foregroundColor(.gray)
                    }
                    
                    if isLoading {
                        ProgressView()
                            .scaleEffect(1.5)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                    
                    if let error = error {
                        VStack {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 40))
                                .foregroundColor(.yellow)
                            
                            Text(localizationManager.string(for: "error_loading"))
                                .foregroundColor(.white)
                            
                            Text(localizedErrorDescription(for: error))
                                .font(.caption)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding()
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(12)
                    }
                }
            }
        }
        .statusBar(hidden: true)
        .onAppear {
            // 1) Trava orientação em retrato
            orientationManager.lockToPortrait()
            orientationManager.printCurrentOrientation()
            
            // 2) Força rotação na cena correta
            forcePortraitOnCurrentWindowScene()
        }
        .onDisappear {
            // Retorna ao padrão do app (retrato, no seu caso)
            orientationManager.resetToDefault()
        }
    }
    
    private func forcePortraitOnCurrentWindowScene() {
        // Tenta obter a windowScene da janela atual
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { scene in
                // Procura a cena com janela key
                return scene.windows.contains(where: { $0.isKeyWindow })
            }) ?? UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first
        else {
            UIViewController.attemptRotationToDeviceOrientation()
            return
        }
        
        if #available(iOS 16.0, *) {
            windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
            UIViewController.attemptRotationToDeviceOrientation()
        } else {
            UIViewController.attemptRotationToDeviceOrientation()
        }
    }
    
    private func localizedErrorDescription(for error: Error) -> String {
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet:
                return localizationManager.string(for: "error_no_internet")
            case NSURLErrorTimedOut:
                return localizationManager.string(for: "error_timeout")
            case NSURLErrorCannotFindHost, NSURLErrorCannotConnectToHost:
                return localizationManager.string(for: "error_server_unavailable")
            default:
                return localizationManager.string(for: "error_network_generic")
            }
        }
        return error.localizedDescription
    }
}
