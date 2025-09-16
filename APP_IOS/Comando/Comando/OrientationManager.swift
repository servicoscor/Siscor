import UIKit
import SwiftUI
import Combine

// MARK: - Orientation Manager
class OrientationManager: ObservableObject {
    static let shared = OrientationManager()
    
    @Published var currentOrientation: UIInterfaceOrientationMask = .portrait
    @Published var isLandscapeMode: Bool = false
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Define a orientação permitida para o app
    func setOrientation(_ orientation: UIInterfaceOrientationMask, animated: Bool = true) {
        currentOrientation = orientation
        
        // Atualiza o flag de landscape
        isLandscapeMode = (orientation == .landscape || orientation == .landscapeLeft || orientation == .landscapeRight)
        
        // Notifica o AppDelegate sobre a mudança
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.orientation = orientation
        }
        
        // Força a atualização da orientação
        updateDeviceOrientation(to: orientation, animated: animated)
    }
    
    /// Permite apenas retrato
    func lockToPortrait() {
        setOrientation(.portrait)
    }
    
    /// Permite apenas paisagem
    func lockToLandscape() {
        setOrientation(.landscape)
    }
    
    /// Permite todas as orientações
    func unlockOrientation() {
        setOrientation(.all)
    }
    
    /// Reseta para orientação padrão (retrato)
    func resetToDefault() {
        setOrientation(.portrait)
    }
    
    // MARK: - Private Methods
    
    private func updateDeviceOrientation(to orientation: UIInterfaceOrientationMask, animated: Bool) {
        // iOS 16+
        if #available(iOS 16.0, *) {
            guard let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first else { return }
            
            // Usa apenas a versão sem completion handler
            windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: orientation))
            
            // Força a rotação do dispositivo se necessário
            if animated {
                UIViewController.attemptRotationToDeviceOrientation()
            }
        } else {
            // iOS 15 e anteriores
            UIDevice.current.setValue(interfaceOrientation(for: orientation).rawValue, forKey: "orientation")
            UIViewController.attemptRotationToDeviceOrientation()
        }
    }
    
    private func interfaceOrientation(for mask: UIInterfaceOrientationMask) -> UIInterfaceOrientation {
        switch mask {
        case .portrait:
            return .portrait
        case .landscapeLeft:
            return .landscapeLeft
        case .landscapeRight:
            return .landscapeRight
        case .landscape:
            return .landscapeRight
        default:
            return .portrait
        }
    }
}

// MARK: - View Modifier para SwiftUI
struct OrientationModifier: ViewModifier {
    let orientation: UIInterfaceOrientationMask
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                OrientationManager.shared.setOrientation(orientation)
            }
            .onDisappear {
                OrientationManager.shared.resetToDefault()
            }
    }
}

extension View {
    /// Força uma orientação específica para esta view
    func forceOrientation(_ orientation: UIInterfaceOrientationMask) -> some View {
        self.modifier(OrientationModifier(orientation: orientation))
    }
    
    /// Apresenta a view em modo paisagem
    func presentInLandscape() -> some View {
        self.forceOrientation(.landscape)
    }
    
    /// Apresenta a view em modo retrato
    func presentInPortrait() -> some View {
        self.forceOrientation(.portrait)
    }
}

// MARK: - Helpers para Debugging
extension OrientationManager {
    func printCurrentOrientation() {
        var orientationString = ""
        
        switch currentOrientation {
        case .portrait:
            orientationString = "Portrait"
        case .landscape:
            orientationString = "Landscape"
        case .landscapeLeft:
            orientationString = "Landscape Left"
        case .landscapeRight:
            orientationString = "Landscape Right"
        case .all:
            orientationString = "All"
        default:
            orientationString = "Unknown"
        }
        
        print("🔄 Orientação atual: \(orientationString)")
    }
}
