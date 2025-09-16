import UIKit

@available(iOS 13.0, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: windowScene)
        
        // Definir como controlador raiz
        window?.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Chamado quando a cena é liberada pelo sistema
        // Geralmente acontece quando o aplicativo é enviado para o background ou é encerrado
        // O sistema pode recriar a cena quando o aplicativo é reaberto
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Chamado quando a cena passa para um estado ativo
        // Use este método para reiniciar tarefas que foram pausadas quando a cena estava inativa
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Chamado quando a cena está prestes a passar para um estado inativo
        // Isso pode ocorrer temporariamente devido a interrupções do sistema (ligação telefônica, etc.)
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Chamado quando a cena passa do background para o primeiro plano
        // Use este método para desfazer alterações feitas ao entrar no background
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Chamado quando a cena entra em background
        // Use este método para salvar dados, liberar recursos compartilhados, etc.
    }
}
