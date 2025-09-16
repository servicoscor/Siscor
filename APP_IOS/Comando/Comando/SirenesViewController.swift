//
//  SirenesViewController.swift
//  Comando
//
//  Created by Candido Bugarin on 15/02/19.
//  Copyright © 2019 Candido Bugarin. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class SirenesViewController: UIViewController, MKMapViewDelegate {
    
 
    
    
    let dispatchQueue = DispatchQueue(label: "Dispatch Queue", attributes: [], target: nil)
    var lingua = ""
    
    var places = [Place]()
    
    var distancia = [Double]()
    
    @IBOutlet weak var titulo: UILabel!
    @IBOutlet weak var meteoro: UIView!
    @IBOutlet weak var ligar: UIButton!
    @IBOutlet weak var pontos: UIButton!
    @IBOutlet weak var sirenes_ativas: UILabel!
    @IBOutlet weak var mapa_but: UIButton!
    @IBOutlet weak var maps: MKMapView!
    
    var arViewController: ARViewController!

    @IBOutlet weak var apoiobt: UIButton!
    
    let locManager = CLLocationManager()
    
    var fav2: Array<Sirene> = []
    var fav3: Array<PA> = []

    var mob = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        
     
        if #available(iOS 15, *) {
            
            let logoContainer = UIView(frame: CGRect(x: 0, y: 0, width: 270, height: 30))
            
            let myimage = UIImage(named: "logo_cor.png")?.withRenderingMode(.alwaysOriginal)

            let attributes = [NSAttributedString.Key.font: UIFont(name: "Raleway-Bold", size: 18)!, NSAttributedString.Key.foregroundColor: UIColor.white]

            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
           
            if self.traitCollection.userInterfaceStyle == .dark {
                appearance.backgroundColor = UIColor(red: 0.00, green: 0.00, blue: 0.00, alpha: 1.00)
            } else {
                appearance.backgroundColor = UIColor(red: 0.30, green: 0.50, blue: 0.73, alpha: 1.00)
            }
            
            
            appearance.shadowColor = .none
            appearance.titleTextAttributes = attributes
            
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationItem.titleView = logoContainer
            
            navigationController?.navigationBar.scrollEdgeAppearance = navigationController?.navigationBar.standardAppearance
            
            let rightBarButton = UIBarButtonItem(image: myimage, style: UIBarButtonItem.Style.plain, target: self, action: "")
            self.navigationItem.rightBarButtonItem = rightBarButton
            
            
        }
        
      
        

        
        
        maps.layer.cornerRadius = 5
        
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

        // Do any additional setup after loading the view.
    }
    
    @IBAction func apoio_act(_ sender: UIButton) {
        let vc = MapaSireneViewController(nibName:"MapaSireneViewController", bundle:nil)
        self.navigationController!.pushViewController(vc, animated: true)
    }
    @IBAction func ligar_act(_ sender: Any) {
        if self.lingua.contains("pt") {
            let uiAlert = UIAlertController(title: "Ligar para Defesa Civil", message: "", preferredStyle: UIAlertController.Style.alert)
            uiAlert.addAction(UIAlertAction(title: "Cancelar", style: .default, handler: { action in
                print("Click of default button")
            }))
            uiAlert.addAction(UIAlertAction(title: "Ligar", style: .default, handler: { action in
                let url: NSURL = URL(string: "TEL://199")! as NSURL
                UIApplication.shared.open(url as URL, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
            }))
            self.present(uiAlert, animated: true, completion: nil)
        }
        else if self.lingua.contains("es") {
            let uiAlert = UIAlertController(title: "Llame a Defensa Civil", message: "", preferredStyle: UIAlertController.Style.alert)
            uiAlert.addAction(UIAlertAction(title: "Cancelar", style: .default, handler: { action in
                print("Click of default button")
            }))
            uiAlert.addAction(UIAlertAction(title: "Llamar", style: .default, handler: { action in
                let url: NSURL = URL(string: "TEL://199")! as NSURL
                UIApplication.shared.open(url as URL, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
            }))
            self.present(uiAlert, animated: true, completion: nil)

        } else {
            let uiAlert = UIAlertController(title: "Call Civil Defense", message: "", preferredStyle: UIAlertController.Style.alert)
            uiAlert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { action in
                print("Click of default button")
            }))
            uiAlert.addAction(UIAlertAction(title: "Call", style: .default, handler: { action in
                let url: NSURL = URL(string: "TEL://199")! as NSURL
                UIApplication.shared.open(url as URL, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
            }))
            self.present(uiAlert, animated: true, completion: nil)
        }
        
      
    }
    
    @IBAction func mapa_act(_ sender: UIButton) {
        let vc = ListaSirenesViewController(nibName:"ListaSirenesViewController", bundle:nil)
        vc.fav = self.fav2
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
            
            if ((annotationView.annotation?.subtitle)!)!.contains("m") {
                annotationView.image =  #imageLiteral(resourceName: "wht-blank.png")
            } else {
                annotationView.image = #imageLiteral(resourceName: "red-stars.png")
            }
        }
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        if control == view.rightCalloutAccessoryView {
            
            let uiAlert = UIAlertController(title: (view.annotation?.title)!, message: (view.annotation?.subtitle)!, preferredStyle: UIAlertController.Style.alert)
            
            uiAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { action in
                print("Click of default button")
            }))
            
            self.present(uiAlert, animated: true, completion: nil)
            
            
        }
    }
    
    func showInfoView(forPlace place: Place) {
        let uiAlert = UIAlertController(title: place.placeName, message: place.desc, preferredStyle: UIAlertController.Style.alert)
        uiAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { action in
            print("Click of default button")
        }))
        arViewController.present(uiAlert, animated: true, completion: nil)
    }

    
    @IBAction func ar_open(_ sender: Any) {
        arViewController = ARViewController()
        arViewController.dataSource = self as ARDataSource
        arViewController.presenter.distanceOffsetMode = .automatic
        arViewController.presenter.distanceOffsetMultiplier = 0.1   // Pixels per meter
        arViewController.presenter.distanceOffsetMinThreshold = 0 // Doesn't raise annotations that are nearer than this
        //arViewController.presenter.maxDistance = 300000              // Don't show annotations if they are farther than this
        arViewController.presenter.maxVisibleAnnotations = 100      // Max number of annotations on the screen
        arViewController.presenter.verticalStackingEnabled = true
        arViewController.trackingManager.userDistanceFilter = 15
        arViewController.trackingManager.reloadDistanceFilter = 10
        arViewController.uiOptions.closeButtonEnabled = true
        arViewController.uiOptions.debugLabel = false
        arViewController.uiOptions.debugMap = false
        arViewController.uiOptions.simulatorDebugging = Platform.isSimulator
        arViewController.uiOptions.setUserLocationToCenterOfAnnotations =  Platform.isSimulator
        arViewController.interfaceOrientationMask = .all
        arViewController.setAnnotations(places)
        self.present(arViewController, animated: true, completion: nil)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Hide the navigation bar on the this view controller
        
        (UIApplication.shared.delegate as? AppDelegate)?.orientation = .portrait
                            
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))

        UIApplication.navigationTopViewController()?.setNeedsUpdateOfSupportedInterfaceOrientations()
        
        if ((UserDefaults.standard.string(forKey: "lingua_usu")) != nil) {
            lingua = UserDefaults.standard.string(forKey: "lingua_usu")!
        } else {
            lingua = UserDefaults.standard.stringArray(forKey: "AppleLanguages")![0]
        }
        
        
        
        if lingua.contains("pt") {
            title = "Sirenes"
        } else if lingua.contains("es") {
            title = "Sirenas"
        } else {
            title = "Sirens"
        }
        
        if lingua.contains("pt") {
            self.sirenes_ativas.text = "Carregando..."
        } else if lingua.contains("es") {
            self.sirenes_ativas.text = "Cargando..."
        } else {
            self.sirenes_ativas.text = "Loading..."
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
                
                self.places.removeAll()
                
                self.fav3 = ColetaDados_PA.getdata()
                
                var x = 0
                while x != self.fav3.count {
                    
                    if CLLocationManager.locationServicesEnabled() {
                        switch(CLLocationManager.authorizationStatus()) {
                        case .notDetermined, .restricted, .denied: 
                            
                        break
                        case .authorizedAlways, .authorizedWhenInUse:
                            
                            let distanceInMeters = CLLocation(latitude: self.fav3[x].lat, longitude: self.fav3[x].lon).distance(from: CLLocation(latitude: (self.locManager.location?.coordinate.latitude)!, longitude: (self.locManager.location?.coordinate.longitude)!))
                            
                            self.distancia.append(distanceInMeters)
                            
                           
                        break
                        }
                    } else {
                        
                    }
                        
                    
                    
                    
                    
                    x += 1
                    
                }
                
            
                let location = CLLocation(latitude: (Double(self.fav3[self.distancia.index(of: self.distancia.min()!)!].lat)), longitude: (Double(self.fav3[self.distancia.index(of: self.distancia.min()!)!].lon)))
                let place = Place(location: location, name: self.fav3[self.distancia.index(of: self.distancia.min()!)!].nome, desc: "Ponto de apoio mais próximo")
                self.places.append(place!)
                
                
                self.fav2 = ColetaDados_Sirene.getdata()
                
                let allAnnotations = self.maps.annotations
                self.maps.removeAnnotations(allAnnotations)
                
                x = 0
                while x != self.fav2.count {
                    let point = StoreAnnotation(coordinate:  CLLocationCoordinate2D(latitude: CLLocationDegrees(self.fav2[x].lat) , longitude: CLLocationDegrees(self.fav2[x].lon)))
                    point.title = self.fav2[x].nome
                    
                 
                    if self.lingua.contains("pt") {
                        if self.fav2[x].status.contains("m") {
                            point.subtitle = "Sirene Mobilizada"
                        } else  {
                            point.subtitle =  "Sirene Desmobilizada"
                        }
                    } else if self.lingua.contains("es") {
                        if self.fav2[x].status.contains("m") {
                            point.subtitle = "Sirena Movilizados"
                        } else  {
                            point.subtitle =  "Sirena desmovilizada"
                        }
                    } else {   
                        if self.fav2[x].status.contains("m") {
                        point.subtitle = "Mobilized Siren"
                    } else  {
                        point.subtitle =  "Demobilized Siren"
                    }
                    }
                    
                 
                    self.maps.addAnnotation(point)
                    x += 1
                    // Do any additional setup after loading the view.
                }
                
                self.maps.reloadInputViews()
                
                if CLLocationManager.locationServicesEnabled() {
                    switch(CLLocationManager.authorizationStatus()) {
                    case .notDetermined, .restricted, .denied:
                        
                        let alert = UIAlertController(title: "Localização", message: "Seus serviços de localização não foram autorizados. Eles são fundamentais para a visualização das informações. Permita a localização para poder ver o conteúdo.", preferredStyle: UIAlertController.Style.alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                        
                        var x = 0
                        while x != self.fav2.count {
                            if self.fav2[x].status.contains("m") {

                        
                                 self.mob += 1
                            }
                            x += 1
                        }
                        
                        if  self.mob != 0  {
                            self.meteoro.applyGradient(colours: [UIColor(red: 0.93, green: 0.75, blue: 0.22, alpha: 1.00),UIColor(red: 1.00, green: 0.91, blue: 0.65, alpha: 1.00)], radius: 12, sentido: "Vertical")

                            if self.lingua.contains("pt") {
                                self.sirenes_ativas.text = "Sirenes acionadas no momento"
                            } else if self.lingua.contains("es") {
                                self.sirenes_ativas.text = "Sirenas activadas al momento"
                            } else {
                                self.sirenes_ativas.text = "Sirens activated at the moment"
                            }
                            
                        } else {
                            self.meteoro.applyGradient(colours: [UIColor(red: 0.25, green: 0.44, blue: 0.29, alpha: 1.00), UIColor(red: 0.25, green: 0.60, blue: 0.32, alpha: 1.00)], radius: 12, sentido: "Vertical")


                            if self.lingua.contains("pt") {
                                self.sirenes_ativas.text = "Sem sirenes acionadas no momento"
                            } else if self.lingua.contains("es") {
                                self.sirenes_ativas.text = "No hay sirenas activadas en este momento."
                            } else {
                                self.sirenes_ativas.text = "No sirens activated at the moment"
                            }
                        }
                        
                        
                    case .authorizedAlways, .authorizedWhenInUse:
                        self.locManager.startUpdatingLocation()
                        var x = 0
                        var perto = 0
                        while x != self.fav2.count {
                            if self.fav2[x].status.contains("m") {

                                let distanceInMeters = CLLocation(latitude: self.fav2[x].lat, longitude: self.fav2[x].lon).distance(from: CLLocation(latitude: (self.locManager.location?.coordinate.latitude)!, longitude: (self.locManager.location?.coordinate.longitude)!))
                                if distanceInMeters > 2000 {
                                    perto += 1
                                }
                                self.mob += 1
                            }
                            x += 1
                        }
                        
                        
                        
                        if  self.mob != 0 && perto == 0 {
                           
                            
                            self.meteoro.applyGradient(colours: [UIColor(red: 0.93, green: 0.75, blue: 0.22, alpha: 1.00),UIColor(red: 1.00, green: 0.91, blue: 0.65, alpha: 1.00)], radius: 12, sentido: "Vertical")
                            
                            if self.lingua.contains("pt") {
                                self.sirenes_ativas.text = "Sirenes acionadas no momento"
                            } else if self.lingua.contains("es") {
                                self.sirenes_ativas.text = "Sirenas activadas al momento"
                            } else {
                                self.sirenes_ativas.text = "Sirens activated at the moment"
                            }
                        } else if  self.mob != 0 && perto != 0 {
                            
                            
                            self.meteoro.applyGradient(colours: [UIColor(red: 0.66, green: 0.07, blue: 0.19, alpha: 1.00),UIColor(red: 0.87, green: 0.13, blue: 0.13, alpha: 1.00)], radius: 12, sentido: "Vertical")
                            
                             self.sirenes_ativas.text = "Sirenes acionadas nas próximidades"
                            
                            if self.lingua.contains("pt") {
                                self.sirenes_ativas.text = "Sirenes acionadas nas próximidades"
                            } else if self.lingua.contains("es") {
                                self.sirenes_ativas.text = "Sirenas activadas cerca"
                            } else {
                                self.sirenes_ativas.text = "Sirens activated nearby"
                            }
                            
                        } else {
                            
                            self.meteoro.applyGradient(colours: [UIColor(red: 0.25, green: 0.44, blue: 0.29, alpha: 1.00), UIColor(red: 0.25, green: 0.60, blue: 0.32, alpha: 1.00)], radius: 12, sentido: "Vertical")
                            

                            if self.lingua.contains("pt") {
                                self.sirenes_ativas.text = "Sem sirenes acionadas no momento"
                            } else if self.lingua.contains("es") {
                                self.sirenes_ativas.text = "No hay sirenas activadas en este momento."
                            } else {
                                self.sirenes_ativas.text = "No sirens activated at the moment"
                            }
                        }
                    }
                        
                } else {
                    let alert = UIAlertController(title: "Localização", message: "Estamos enfretando problemas com sua localização, estamos tentando restabelecer a conexão.", preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    
                    var x = 0
                    while x != self.fav2.count {
                        if self.fav2[x].status.contains("m") {
                    
                            
                             self.mob += 1
                        }
                        x += 1
                    }
                    
                    if  self.mob != 0  {
                        self.meteoro.applyGradient(colours: [UIColor(red: 0.93, green: 0.75, blue: 0.22, alpha: 1.00),UIColor(red: 1.00, green: 0.91, blue: 0.65, alpha: 1.00)], radius: 12, sentido: "Vertical")
                        
                        if self.lingua.contains("pt") {
                            self.sirenes_ativas.text = "Sirenes acionadas no momento"
                        } else if self.lingua.contains("es") {
                            self.sirenes_ativas.text = "Sirenas activadas al momento"
                        } else {
                            self.sirenes_ativas.text = "Sirens activated at the moment"
                        }


                        
                    } else {
                        self.meteoro.applyGradient(colours: [UIColor(red: 0.25, green: 0.44, blue: 0.29, alpha: 1.00), UIColor(red: 0.25, green: 0.60, blue: 0.32, alpha: 1.00)], radius: 12, sentido: "Vertical")
                        
                        if self.lingua.contains("pt") {
                            self.sirenes_ativas.text = "Sem sirenes acionadas no momento"
                        } else if self.lingua.contains("es") {
                            self.sirenes_ativas.text = "No hay sirenas activadas en este momento."
                        } else {
                            self.sirenes_ativas.text = "No sirens activated at the moment"
                        }
                        
                    
                        
                    }
                }
                self.pontos.applyGradient(colours: [UIColor(red: 0.22, green: 0.51, blue: 0.75, alpha: 1.00), UIColor(red: 0.31, green: 0.62, blue: 0.87, alpha: 1.00)], radius: 6, sentido: "Horizontal")
                self.mapa_but.applyGradient(colours: [UIColor(red: 0.22, green: 0.51, blue: 0.75, alpha: 1.00), UIColor(red: 0.31, green: 0.62, blue: 0.87, alpha: 1.00)], radius: 6, sentido: "Horizontal")
                self.ligar.applyGradient(colours: [UIColor(red: 0.22, green: 0.51, blue: 0.75, alpha: 1.00), UIColor(red: 0.31, green: 0.62, blue: 0.87, alpha: 1.00)], radius: 6, sentido: "Horizontal")
                self.apoiobt.applyGradient(colours: [UIColor(red: 0.22, green: 0.51, blue: 0.75, alpha: 1.00), UIColor(red: 0.31, green: 0.62, blue: 0.87, alpha: 1.00)], radius: 6, sentido: "Horizontal")
                
                if self.lingua.contains("pt") {
                    
                } else if self.lingua.contains("es") {
                    self.ligar.setTitle("llamar a defensa civil", for: UIControl.State.normal)
                    self.pontos.setTitle("Puntos de apoyo", for: UIControl.State.normal)
                    self.mapa_but.setTitle("Lista de sirenas", for: UIControl.State.normal)
                    self.titulo.text = "Sirenas en tiempo real"
                    self.apoiobt.setTitle("punto de apoyo más cercano", for: UIControl.State.normal)

                } else {
                    self.ligar.setTitle("Call civil defense", for: UIControl.State.normal)
                    self.pontos.setTitle("Support points", for: UIControl.State.normal)
                    self.mapa_but.setTitle("List of Sirens", for: UIControl.State.normal)
                    self.titulo.text = "Real-time sirens"
                    
                    self.apoiobt.setTitle("nearest support point", for: UIControl.State.normal)
                }
                
            self.removeAllOverlays()
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

}

fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}

extension SirenesViewController: ARDataSource {
    func ar(_ arViewController: ARViewController, viewForAnnotation: ARAnnotation) -> ARAnnotationView {
        let annotationView = AnnotationView()
        annotationView.annotation = viewForAnnotation
        annotationView.backgroundColor = UIColor(red:0.00, green:0.00, blue:0.00, alpha:0.5)
        annotationView.layer.cornerRadius = 10
        annotationView.delegate = self
        annotationView.frame = CGRect(x: 0, y: 0, width: 210, height: 70)
        return annotationView
    }
}

extension SirenesViewController: AnnotationViewDelegate {
    func didTouch(annotationView: AnnotationView) {
        if let annotation = annotationView.annotation as? Place {
            self.showInfoView(forPlace: annotation)
        }
    }
}

