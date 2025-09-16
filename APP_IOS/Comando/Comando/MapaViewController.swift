//
//  MapaViewController.swift
//  Comando
//
//  Created by Candido Bugarin on 04/12/18.
//  Copyright © 2018 Candido Bugarin. All rights reserved.
//

import UIKit
import MapKit

class MapaViewController: UIViewController,MKMapViewDelegate {
    
    @IBOutlet weak var plv_but: UIButton!
    @IBOutlet weak var maps: MKMapView!
    let locManager = CLLocationManager()
    
    let dispatchQueue = DispatchQueue(label: "Dispatch Queue", attributes: [], target: nil)

    var fav3: Array<Estacao> = []
    
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
            
            let rightBarButton = UIBarButtonItem(image: myimage, style: UIBarButtonItem.Style.plain, target: self, action: "")
            self.navigationItem.rightBarButtonItem = rightBarButton
            
            
        }
    
        maps.userTrackingMode = MKUserTrackingMode.followWithHeading
        maps.showsUserLocation = true
        maps.delegate = self
        
        plv_but.layer.cornerRadius = 5
        plv_but.layer.borderColor = UIColor(red:0.00, green:0.51, blue:0.69, alpha:1.0).cgColor
        plv_but.layer.borderWidth = 1
        
      
        
        
        
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
        
    }
    
    @IBAction func plv_act(_ sender: UIButton) {
        let vc = ChuvaTableViewController(nibName:"ChuvaTableViewController", bundle:nil)
        vc.fav3 = fav3
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
            annotationView.canShowCallout = false
            if lingua.contains("pt") {
                if ((annotationView.annotation?.subtitle)!)!.contains("Chuva na última hora: ") {
                    let valor_chuva = Double((((annotationView.annotation?.subtitle)!)!)!.replacingOccurrences(of: "Chuva na última hora: ", with: "", options: NSString.CompareOptions.literal, range:nil))
                    print(valor_chuva!)
                    if valor_chuva == 0.0 {
                        annotationView.image = #imageLiteral(resourceName: "wht-blank.png")
                    } else if valor_chuva! > 0.1 && valor_chuva! <= 5.0 {
                        annotationView.image = #imageLiteral(resourceName: "blu-blank.png")
                    } else if valor_chuva! > 5 && valor_chuva! <= 25 {
                        annotationView.image = #imageLiteral(resourceName: "ylw-blank.png")
                    } else if valor_chuva! > 25 && valor_chuva! <= 50 {
                        annotationView.image = #imageLiteral(resourceName: "orangeblank.png")
                    } else if valor_chuva! > 50 {
                        annotationView.image = #imageLiteral(resourceName: "red-stars.png")
                    }
                } else if ((annotationView.annotation?.subtitle)!)!.contains("Sem informações") {
                    annotationView.image = #imageLiteral(resourceName: "gra-blank.png")
                }
               
            } else if lingua.contains("es") {
                if ((annotationView.annotation?.subtitle)!)!.contains("Lluvia en la última hora: ") {
                    let valor_chuva = Double((((annotationView.annotation?.subtitle)!)!)!.replacingOccurrences(of: "Lluvia en la última hora: ", with: "", options: NSString.CompareOptions.literal, range:nil))
                    print(valor_chuva!)
                    if valor_chuva == 0.0 {
                        annotationView.image = #imageLiteral(resourceName: "wht-blank.png")
                    } else if valor_chuva! > 0.1 && valor_chuva! <= 5.0 {
                        annotationView.image = #imageLiteral(resourceName: "blu-blank.png")
                    } else if valor_chuva! > 5 && valor_chuva! <= 25 {
                        annotationView.image = #imageLiteral(resourceName: "ylw-blank.png")
                    } else if valor_chuva! > 25 && valor_chuva! <= 50 {
                        annotationView.image = #imageLiteral(resourceName: "orangeblank.png")
                    } else if valor_chuva! > 50 {
                        annotationView.image = #imageLiteral(resourceName: "red-stars.png")
                    }
                } else if ((annotationView.annotation?.subtitle)!)!.contains("Sin información") {
                    annotationView.image = #imageLiteral(resourceName: "gra-blank.png")
                }
            } else {
                if ((annotationView.annotation?.subtitle)!)!.contains("Rain in the last hour: ") {
                    let valor_chuva = Double((((annotationView.annotation?.subtitle)!)!)!.replacingOccurrences(of: "Rain in the last hour: ", with: "", options: NSString.CompareOptions.literal, range:nil))
                    if valor_chuva == 0.0 {
                        annotationView.image = #imageLiteral(resourceName: "verde")
                    } else if valor_chuva! > 0.1 && valor_chuva! <= 5.0 {
                        annotationView.image = #imageLiteral(resourceName: "azul")
                    } else if valor_chuva! > 5 && valor_chuva! <= 25 {
                        annotationView.image = #imageLiteral(resourceName: "amarelo")
                    } else if valor_chuva! > 25 && valor_chuva! <= 50 {
                        annotationView.image = #imageLiteral(resourceName: "vermelho")
                    } else if valor_chuva! > 50 {
                        annotationView.image = #imageLiteral(resourceName: "roxo")
                    }
                } else if ((annotationView.annotation?.subtitle)!)!.contains("No information") {
                    annotationView.image = #imageLiteral(resourceName: "azul")
                }
            }
            
            
        }
        
        return annotationView
    }
    
    
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        let id = (view.annotation?.subtitle)!
        if id != nil {
            var x = 0
            while x != self.fav3.count {
                if self.fav3[x].lat == (view.annotation?.coordinate.latitude)! && self.fav3[x].lon == (view.annotation?.coordinate.longitude)! {
                    let vc = EstaPluViewController(nibName:"EstaPluViewController", bundle:nil)
                    vc.fav3 = [self.fav3[x]]
                    self.navigationController!.pushViewController(vc, animated: true)
                }
                    
                x += 1
            }
           
            }
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
            title = "Estações pluviométricas"
           
        } else if lingua.contains("es") {
            title = "Estaciones pluviométricas"
            self.plv_but.setTitle("lista de estaciones pluviométricas", for: UIControl.State.normal)

        } else {
            title = "Rain gauges"
            self.plv_but.setTitle("list of rain gauges", for: UIControl.State.normal)

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
                
                self.fav3 = EstacaoSer.getEsta()
                
                var x = 0
                while x != self.fav3.count {
                    let point = StoreAnnotation(coordinate:  CLLocationCoordinate2D(latitude: CLLocationDegrees(self.fav3[x].lat) , longitude: CLLocationDegrees(self.fav3[x].lon)))
                    point.title = self.fav3[x].nome
                   
                    
                    if self.lingua.contains("pt") {
                        if self.fav3[0].situ.contains("atual") {
                            point.subtitle = "Chuva na última hora: " + String(self.fav3[x].chuva_1)
                        } else if self.fav3[0].situ.contains("atraso") {
                            point.subtitle = "Sem informações"
                        }
                       
                    } else if self.lingua.contains("es") {
                        if self.fav3[0].situ.contains("atual") {
                            point.subtitle = "Lluvia en la última hora: " + String(self.fav3[x].chuva_1)
                        } else if self.fav3[0].situ.contains("atraso") {
                            point.subtitle = "Sin información"
                        }
                    } else {
                        if self.fav3[0].situ.contains("atual") {
                            point.subtitle = "Rain in the last hour: " + String(self.fav3[x].chuva_1)
                        } else if self.fav3[0].situ.contains("atraso") {
                            point.subtitle = "No information"
                        }
                    }
                    
                    self.maps.addAnnotation(point)
                    x += 1
                    
                    
                    
                    
                    // Do any additional setup after loading the view.
                }
                
                self.maps.reloadInputViews()
                
                self.plv_but.applyGradient(colours: [UIColor(red: 0.22, green: 0.51, blue: 0.75, alpha: 1.00), UIColor(red: 0.31, green: 0.62, blue: 0.87, alpha: 1.00)], radius: 6, sentido: "Horizontal")

                
                self.removeAllOverlays()
            }
        }
    }
    

}


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */


