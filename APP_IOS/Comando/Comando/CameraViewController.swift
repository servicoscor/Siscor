//
//  RadarViewController.swift
//  Comando
//
//  Created by Candido Bugarin on 25/02/19.
//  Copyright © 2019 Candido Bugarin. All rights reserved.
//

import UIKit
import WebKit

class CameraViewController: UIViewController, WKNavigationDelegate  {

    
    @IBOutlet weak var webView: WKWebView!
    
    var camera = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 15, *) {
            
            let logoContainer = UIView(frame: CGRect(x: 0, y: 0, width: 270, height: 30))
            
            let myimage = UIImage(named: "logo_cor.png")?.withRenderingMode(.alwaysOriginal)

           
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
           
            if self.traitCollection.userInterfaceStyle == .dark {
                appearance.backgroundColor = UIColor(red: 0.00, green: 0.00, blue: 0.00, alpha: 1.00)
            } else {
                appearance.backgroundColor = UIColor(red: 0.30, green: 0.50, blue: 0.73, alpha: 1.00)
            }
            
            
            appearance.shadowColor = .none
            
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationItem.titleView = logoContainer
            
            navigationController?.navigationBar.scrollEdgeAppearance = navigationController?.navigationBar.standardAppearance
            
            let rightBarButton = UIBarButtonItem(image: myimage, style: UIBarButtonItem.Style.plain, target: self, action: "")
            self.navigationItem.rightBarButtonItem = rightBarButton
            
            
        }
        
        title = "Câmeras"
        
        super.viewDidLoad()
        if let url = URL(string: "https://aplicativo.cocr.com.br/camera/"+camera) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        
        (UIApplication.shared.delegate as? AppDelegate)?.orientation = .landscapeRight
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .landscapeRight))
        UIApplication.navigationTopViewController()?.setNeedsUpdateOfSupportedInterfaceOrientations()

        
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override var shouldAutorotate: Bool {
        return true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Hide the navigation bar on the this view controller
        self.tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
        
        (UIApplication.shared.delegate as? AppDelegate)?.orientation = .portrait
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
        UIApplication.navigationTopViewController()?.setNeedsUpdateOfSupportedInterfaceOrientations()

        
        // Show the navigation bar on other view controllers
        self.tabBarController?.tabBar.isHidden = true
        

    }

    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension UIApplication {
    class func navigationTopViewController() -> UIViewController? {
        let nav = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController
        return  nav?.topViewController
    }
}
