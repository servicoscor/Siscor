//
//  VideoViewController.swift
//  Comando
//
//  Created by Candido Bugarin on 08/08/19.
//  Copyright © 2019 Candido Bugarin. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import Firebase
import FirebaseInstanceID
import FirebaseMessaging
import CoreLocation
import MapKit

class VideoViewController: UIViewController,MessagingDelegate {
    
    @IBOutlet weak var imageVI: UIImageView!
    
    @IBOutlet weak var butao: UIButton!
    var window: UIWindow?
    
    let locManager = CLLocationManager()
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        
        
        imageVI.loadGif(name: "gifrio")
        butao.layer.cornerRadius = 5
        butao.layer.borderColor = UIColor(red:0.00, green:0.51, blue:0.69, alpha:1.0).cgColor
        butao.layer.borderWidth = 1
        
        if CLLocationManager.locationServicesEnabled() {
            switch(CLLocationManager.authorizationStatus()) {
            case .restricted, .denied:
                let alert = UIAlertController(title: "Localização", message: "Seus serviços de localização não foram autorizados. Eles são fundamentais para a visualização das informações. Permita a localização para poder ver o conteúdo.", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                
                
                
            case .authorizedAlways, .authorizedWhenInUse:
                
                locManager.desiredAccuracy = kCLLocationAccuracyBest
                locManager.startUpdatingLocation()
                
            case .notDetermined:
                
                self.locManager.requestWhenInUseAuthorization()
            }
            
        } else {
            
            self.locManager.requestWhenInUseAuthorization()
            
        }
    }
    
    @IBAction func act_butao(_ sender: UIButton) {
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window!.backgroundColor = UIColor.white
        
        UINavigationBar.appearance().barTintColor = UIColor(red:0.00, green:0.34, blue:0.75, alpha:1.0)
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor(red:1.00, green:1.00, blue:1.00, alpha:1.0)]
        
        UINavigationBar.appearance().tintColor = UIColor(red:1.00, green:1.00, blue:1.00, alpha:1.0)
        
        let Home = HomeViewController(nibName: "HomeViewController", bundle: nil)
        let Transito = TransitoAtualViewController(nibName: "TransitoAtualViewController", bundle: nil)
        let Tempo = TempoViewController(nibName: "TempoViewController", bundle: nil)
        let Sirenes = SirenesViewController(nibName: "SirenesViewController", bundle: nil)
        let Radar = MobilidadeViewController(nibName: "MobilidadeViewController", bundle: nil)
        
        let nav1 = UINavigationController()
        let nav2 = UINavigationController()
        let nav3 = UINavigationController()
        let nav4 = UINavigationController()
        let nav5 = UINavigationController()
        
        nav1.pushViewController(Home, animated: false)
        nav2.pushViewController(Transito, animated: false)
        nav3.pushViewController(Tempo, animated: false)
        nav4.pushViewController(Sirenes, animated: false)
        nav5.pushViewController(Radar, animated: false)
        
        let tabBarController = UITabBarController()
        
        tabBarController.viewControllers = [nav1,nav2,nav5,nav3,nav4]
        
        nav1.tabBarItem.title = "Início"
        nav1.tabBarItem.image = UIImage(named: "home.png")
        
        nav5.tabBarItem.title = "Mobilidade"
        nav5.tabBarItem.image = UIImage(named: "skytrain.png")
        
        nav2.tabBarItem.title = "Trânsito"
        nav2.tabBarItem.image = UIImage(named: "drive.png")
        
        nav4.tabBarItem.title = "Sirene"
        nav4.tabBarItem.image = UIImage(named: "siren.png")
        
        nav3.tabBarItem.title = "Tempo"
        nav3.tabBarItem.image = UIImage(named: "sun.png")
        

        
        UITabBar.appearance().barTintColor = UIColor(red:0.00, green:0.34, blue:0.75, alpha:1.0)
        UITabBar.appearance().tintColor = UIColor(red:1.00, green:1.00, blue:1.00, alpha:1.0)
        
        self.window!.rootViewController = tabBarController
        self.window!.makeKeyAndVisible()
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Hide the navigation bar on the this view controller
        self.tabBarController?.tabBar.isHidden = true
        self.tabBarController?.navigationItem.hidesBackButton = true
        self.navigationController?.navigationBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Show the navigation bar on other view controllers
        self.tabBarController?.tabBar.isHidden = false
        self.navigationController?.navigationBar.isHidden = false
    }
    
}
