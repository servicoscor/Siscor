//
//  HidratacaoViewController.swift
//  Comando
//
//  Created by Candido Bugarin on 26/11/23.
//  Copyright © 2023 Candido Bugarin. All rights reserved.
//

import UIKit
import MapKit

class HidratacaoViewController: UIViewController , MKMapViewDelegate {
    
    @IBOutlet weak var viewrecomendacoes: UIView!
    @IBOutlet weak var maps: MKMapView!
    let locManager = CLLocationManager()

    let dispatchQueue = DispatchQueue(label: "Dispatch Queue", attributes: [], target: nil)
    
    @IBOutlet weak var calorbt: UILabel!
    @IBOutlet weak var viewcalor: UIView!
    var fav3: Array<PA> = []
    var fav4: Array<PA> = []
    var fav12: Array<NC> = []
    var fav13: Array<Recomenda> = []
    
    var lingua = ""
    
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
            
            let rightBarButton = UIBarButtonItem(image: myimage, style: UIBarButtonItem.Style.plain, target: self, action: #selector(ButtonTapped))
            self.navigationItem.rightBarButtonItem = rightBarButton
            
            
        }
        
        
     
        
        
        maps.userTrackingMode = MKUserTrackingMode.followWithHeading
        maps.showsUserLocation = true
        maps.delegate = self
        
        
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
        
        
        if let userLocation = locManager.location?.coordinate {
            let viewRegion = MKCoordinateRegion(center: userLocation, latitudinalMeters: 10000, longitudinalMeters: 10000)
            maps.setRegion(viewRegion, animated: false)
        } else {
            let latitude:CLLocationDegrees = -22.9241421//insert latitutde
            let longitude:CLLocationDegrees = -43.4405087 //insert longitud
            let location = CLLocationCoordinate2DMake(latitude, longitude)
            
            let viewRegion = MKCoordinateRegion(center: location, latitudinalMeters: 10000, longitudinalMeters: 10000)
            maps.setRegion(viewRegion, animated: false)
        }
        
        let tap8 = UITapGestureRecognizer(target: self, action: #selector(self.handleTap3(_:)))
        viewrecomendacoes.addGestureRecognizer(tap8)
        viewrecomendacoes.isUserInteractionEnabled = true
        
        
        
    }
    
    @objc func ButtonTapped() {
    print("Button Tapped")
   }
    
    @objc func handleTap3(_ sender: UITapGestureRecognizer) {
        let vc = TextViewController(nibName:"TextViewController", bundle:nil)
        vc.texto_input = self.fav13[0].nome
        vc.titulo = "Recomendações"
        vc.fonte_t = "COR.Rio Informa"
        self.navigationController!.pushViewController(vc, animated: true)
    }
  
    
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // Don't want to show a custom image if the annotation is the user's location.
        guard !(annotation is MKUserLocation) else {
            return nil
        }
        
        // Better to make this class property
        
        var annotationView: MKAnnotationView?
        if let dequeuedAnnotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "Pin") {
            annotationView = dequeuedAnnotationView
            annotationView?.annotation = annotation
        }
        else {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "Pin")
        }
        
        if let annotationView = annotationView {
            // Configure your annotation view here
            annotationView.canShowCallout = true
            if ((annotationView.annotation?.title)!)!.contains("SMS") {
                annotationView.image = UIImage(named: "farmacia.png")
            }  else {
                    annotationView.image = UIImage(named: "neve.png")
                }

        }
        
        return annotationView
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Hide the navigation bar on the this view controller
        
        if ((UserDefaults.standard.string(forKey: "lingua_usu")) != nil) {
            lingua = UserDefaults.standard.string(forKey: "lingua_usu")!
        } else {
            lingua = UserDefaults.standard.stringArray(forKey: "AppleLanguages")![0]
        }
        
        if lingua.contains("pt") {
            self.title = "Pontos de resfriamento"
    
        } else if lingua.contains("es") {
            self.title = "Islas de enfriamiento"
        } else {
            self.title = "Cooling Islands"
        }
        
        if lingua.contains("pt") {
            let text = "Carregando"
            self.showWaitOverlayWithText(text)
        } else if lingua.contains("es") {
            let text = "Cargando"
            self.showWaitOverlayWithText(text)
        } else {
            let text = "Loading"
            self.showWaitOverlayWithText(text)
        }
        

        
        dispatchQueue.async {
            OperationQueue.main.addOperation() {
                
                self.fav12 = ColetaDados_NCSitu.getdata()
                
                self.fav13 = ColetaDados_Recomenda.getdata()
                
                self.calorbt.text = self.fav12[0].situ+""
                
                if self.fav12[0].situ.contains("calor 1")  {
                    self.calorbt.text = "Calor 1 (Saiba mais)"

                    self.viewcalor.applyGradient(colours: [UIColor(red: 0.09, green: 0.38, blue: 0.69, alpha: 1.00),  UIColor(red: 0.02, green: 0.25, blue: 0.59, alpha: 1.00)], radius: 12, sentido: "Horizontal")
                } else if self.fav12[0].situ.contains("calor 2")  {
                    self.calorbt.text = "Calor 2 (Saiba mais)"

                    self.viewcalor.applyGradient(colours: [UIColor(red: 0.02, green: 0.28, blue: 0.48, alpha: 1.00),  UIColor(red: 0.02, green: 0.20, blue: 0.40, alpha: 1.00)], radius: 12, sentido: "Horizontal")
                } else if self.fav12[0].situ.contains("calor 3")  {
                    self.calorbt.text = "Calor 3 (Saiba mais)"

                    self.viewcalor.applyGradient(colours: [UIColor(red: 0.00, green: 0.15, blue: 0.32, alpha: 1.00), UIColor(red: 0.00, green: 0.04, blue: 0.09, alpha: 1.00)], radius: 12, sentido: "Horizontal")
                } else if self.fav12[0].situ.contains("calor 4")  {
                    self.calorbt.text = "Calor 4 (Saiba mais)"

                    self.viewcalor.applyGradient(colours: [UIColor(red: 0.00, green: 0.11, blue: 0.21, alpha: 1.00),  UIColor(red: 0.00, green: 0.03, blue: 0.07, alpha: 1.00)], radius: 12, sentido: "Horizontal")
                } else if self.fav12[0].situ.contains("calor 5")  {
                    self.calorbt.text = "Calor 5 (Saiba mais)"

                    self.viewcalor.applyGradient(colours: [UIColor(red: 0.00, green: 0.07, blue: 0.13, alpha: 1.00),  UIColor(red: 0.00, green: 0.02, blue: 0.04, alpha: 1.00)], radius: 12, sentido: "Horizontal")
                }
            
                
                
                self.fav3 = ColetaDados_CF.getdata()
                
                var x = 0
                while x != self.fav3.count {
                    let point = StoreAnnotation(coordinate:  CLLocationCoordinate2D(latitude: CLLocationDegrees(self.fav3[x].lat) , longitude: CLLocationDegrees(self.fav3[x].lon)))
                    point.title = self.fav3[x].nome
                    point.subtitle =  self.fav3[x].endereco
                    self.maps.addAnnotation(point)
                    x += 1
                }

                self.fav4 = ColetaDados_FR.getdata()
                    
                x = 0
                while x != self.fav4.count {
                    let point = StoreAnnotation(coordinate:  CLLocationCoordinate2D(latitude: CLLocationDegrees(self.fav4[x].lat) , longitude: CLLocationDegrees(self.fav4[x].lon)))
                    point.title = self.fav4[x].nome
                    point.subtitle = self.fav4[x].endereco
                    self.maps.addAnnotation(point)
                    x += 1
                }
                        
                                    
                    // Do any additional setup after loading the view.
                
                
                self.maps.reloadInputViews()
                self.removeAllOverlays()
                self.viewrecomendacoes.applyGradient(colours: [UIColor(red: 0.16, green: 0.41, blue: 0.56, alpha: 1.00), UIColor(red: 0.26, green: 0.73, blue: 0.92, alpha: 1.00)], radius: 12, sentido: "Horizontal")

            }
            
            
            
        }
        
    }
    
    
}
