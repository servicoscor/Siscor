import UIKit
import CoreLocation
import UserNotifications
import Firebase
import FirebaseInstanceID
import FirebaseMessaging

class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {

    var window: UIWindow?
    // Esta variável agora é usada para permitir a mudança de orientação.
    var orientation: UIInterfaceOrientationMask {
        get { OrientationManager.shared.currentOrientation }
        set { OrientationManager.shared.setOrientation(newValue) }
    }
    
    var lingua = ""
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Seu código existente aqui...
        if let savedLanguage = UserDefaults.standard.string(forKey: "lingua_usu") {
            lingua = savedLanguage
        } else if let languages = UserDefaults.standard.stringArray(forKey: "AppleLanguages"), let firstLanguage = languages.first {
            lingua = firstLanguage
        }
        
        setupFirebase()
        setupNotifications(application)
        configureAppearance()
        
        return true
    }
    
    // MARK: - Setup Methods
    
    private func setupFirebase() {
        FirebaseApp.configure()
        
        // Debug para verificar se está funcionando
        if let fcmToken = Messaging.messaging().fcmToken {
            print("✅ Token FCM atual: \(fcmToken)")
            sendTokenToServer(fcmToken)
        } else {
            print("⚠️ Token FCM ainda não disponível")
        }
        
        // TESTE: Force o envio do token após um delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if let fcmToken = Messaging.messaging().fcmToken {
                print("🧪 TESTE: Forçando envio do token: \(fcmToken)")
                self.sendTokenToServer(fcmToken)
            } else {
                print("⚠️ TESTE: Token ainda não disponível após 2 segundos")
            }
        }
        
        Messaging.messaging().delegate = self
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    private func setupNotifications(_ application: UIApplication) {
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(options: authOptions, completionHandler: {_, _ in })
        } else {
            let settings: UIUserNotificationSettings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        application.registerForRemoteNotifications()
    }
    
    private func configureAppearance() {
        UINavigationBar.appearance().barTintColor = UIColor(red: 0.16, green: 0.41, blue: 0.56, alpha: 1.0)
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        UINavigationBar.appearance().tintColor = UIColor.white
        if #available(iOS 15, *) {
            let navigationBarAppearance = UINavigationBarAppearance()
            navigationBarAppearance.configureWithOpaqueBackground()
            navigationBarAppearance.backgroundColor = UIColor(red: 0.16, green: 0.41, blue: 0.56, alpha: 1.0)
            navigationBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            UINavigationBar.appearance().standardAppearance = navigationBarAppearance
            UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
        }
    }
    
    // MARK: - Send Token to Server (IMPLEMENTAÇÃO COMPLETA)
    private func sendTokenToServer(_ token: String) {
        print("📱 Enviando token FCM para servidor: \(token)")
        
        // URL correta do endpoint
        guard let url = URL(string: "https://aplicativo.cocr.com.br/insert_id") else {
            print("❌ URL inválida")
            return
        }
        
        // Prepare a requisição POST
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Corpo da requisição conforme esperado pelo servidor
        let body: [String: Any] = [
            "idtelefone": token,  // O servidor espera "idtelefone" com o token FCM
            "sistema": "iOS"      // O servidor espera "sistema" com o tipo de plataforma
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            print("📤 Enviando dados: \(body)")
        } catch {
            print("❌ Erro ao serializar dados: \(error)")
            return
        }
        
        // Envie a requisição
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Erro ao enviar token: \(error)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("✅ Token enviado. Status: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 200 {
                    // Salve localmente que o token foi enviado com sucesso
                    UserDefaults.standard.set(token, forKey: "fcm_token_sent")
                    UserDefaults.standard.set(Date(), forKey: "fcm_token_sent_date")
                    
                    if let data = data, let responseString = String(data: data, encoding: .utf8) {
                        print("📄 Resposta do servidor: \(responseString)")
                    }
                } else {
                    print("⚠️ Servidor retornou status: \(httpResponse.statusCode)")
                    if let data = data, let responseString = String(data: data, encoding: .utf8) {
                        print("📄 Resposta de erro: \(responseString)")
                    }
                }
            }
        }.resume()
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
    
    // MARK: - UIApplicationDelegate
    
    func applicationWillResignActive(_ application: UIApplication) {}
    
    func applicationDidEnterBackground(_ application: UIApplication) {}
    
    func applicationWillEnterForeground(_ application: UIApplication) {}
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        // NOVO: Notifica que o app ficou ativo para recarregar dados
        NotificationCenter.default.post(name: NSNotification.Name("AppDidBecomeActive"), object: nil)
    }
    
    func applicationWillTerminate(_ application: UIApplication) {}
    
    // MARK: - Interface Orientation
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        // A lógica do OrientationManager define a orientação desejada.
        // Se a orientação desejada for paisagem, permita paisagem.
        // Se for retrato, permita retrato.
        return self.orientation
    }
    
    // MARK: - Remote Notifications
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }
    
    // MARK: - MessagingDelegate (ATUALIZADO)
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else {
            print("⚠️ Token FCM é nil")
            return
        }
        
        print("🔥 Firebase FCM Token recebido: \(fcmToken)")
        
        // Verifique se o token mudou
        let savedToken = UserDefaults.standard.string(forKey: "fcm_token_sent")
        
        if savedToken != fcmToken {
            print("🔄 Token mudou, enviando para servidor...")
            sendTokenToServer(fcmToken)
        } else {
            print("✅ Token já foi enviado anteriormente")
        }
    }
}

// MARK: - iOS 13+ Scene Support

@available(iOS 13.0, *)
extension AppDelegate {
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {}
}
