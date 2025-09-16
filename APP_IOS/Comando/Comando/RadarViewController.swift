//
//  RadarViewController.swift
//  Comando
//
//  Created by Candido Bugarin on 25/02/19.
//  Copyright © 2019 Candido Bugarin. All rights reserved.
//

import UIKit
import WebKit

class RadarViewController: UIViewController, WKNavigationDelegate  {

    
    @IBOutlet weak var webView: WKWebView!
    
    var caminho = "https://aplicativo.cocr.com.br/chat"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 15, *) {
            
            let logoContainer = UIView(frame: CGRect(x: 0, y: 0, width: 270, height: 30))
            
            let myimage = UIImage(named: "logo_cor.png")?.withRenderingMode(.alwaysOriginal)


            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
           
            if self.traitCollection.userInterfaceStyle == .dark {
                appearance.backgroundColor = UIColor(red: 0.02, green: 0.01, blue: 0.33, alpha: 1.00)
            } else {
                appearance.backgroundColor = UIColor(red: 0.02, green: 0.01, blue: 0.33, alpha: 1.00)
            }
            
            
            appearance.shadowColor = .none
            
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationItem.titleView = logoContainer
            
            navigationController?.navigationBar.scrollEdgeAppearance = navigationController?.navigationBar.standardAppearance
            
        }
        
        title = "Cora"
        
        super.viewDidLoad()
        if let url = URL(string: caminho) {
            let request = URLRequest(url: url)
            webView.load(request)
        }

        // Do any additional setup after loading the view.
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
