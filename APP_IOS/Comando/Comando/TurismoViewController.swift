//
//  TurismoViewController.swift
//  Comando
//
//  Created by Candido Bugarin on 25/01/24.
//  Copyright © 2024 Candido Bugarin. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class TurismoViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var titulom: UILabel!
    @IBOutlet weak var maps: MKMapView!
    @IBOutlet weak var hidra: UIButton!
    @IBOutlet weak var eventos_prox: UIButton!
    
    var arViewController: ARViewController!
    let locManager = CLLocationManager()
    
    var fav: Array<PontosTur> = []
    
    
    let dispatchQueue = DispatchQueue(label: "Dispatch Queue", attributes: [], target: nil)
    var lingua = ""
    
    var places = [Place]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if ((UserDefaults.standard.string(forKey: "lingua_usu")) != nil) {
            lingua = UserDefaults.standard.string(forKey: "lingua_usu")!
        } else {
            lingua = UserDefaults.standard.stringArray(forKey: "AppleLanguages")![0]
        }
        
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Hide the navigation bar on the this view controller
        
        (UIApplication.shared.delegate as? AppDelegate)?.orientation = .portrait
                            
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))

        UIApplication.navigationTopViewController()?.setNeedsUpdateOfSupportedInterfaceOrientations()
        
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
        
        if lingua.contains("pt") {
            title = "Pontos Turísticos"
        } else if lingua.contains("es") {
            title = "Puntos turisticos"
            self.titulom.text = "Puntos turisticos"
        } else {
            title = "tourist attractions"
            self.titulom.text = "tourist attractions"
        }
        
        
        dispatchQueue.async {
            OperationQueue.main.addOperation() {
                
                self.fav = ColetaDados_Turismo.getdata()
                
                
                let allAnnotations = self.maps.annotations
                self.maps.removeAnnotations(allAnnotations)
                self.places.removeAll()
                
                var x = 0
                while x != self.fav.count {
                    let point = StoreAnnotation(coordinate:  CLLocationCoordinate2D(latitude: CLLocationDegrees(self.fav[x].lat) , longitude: CLLocationDegrees(self.fav[x].lon)))
                    point.title = self.fav[x].nome
                    point.subtitle = self.fav[x].end
                    
                    self.maps.addAnnotation(point)
                    
                    let location = CLLocation(latitude: CLLocationDegrees(self.fav[x].lat), longitude: CLLocationDegrees(self.fav[x].lon))
                   
                    let place = Place(location: location, name: self.fav[x].nome, desc: "Endereço: "+self.fav[x].end+"")
                    
                    self.places.append(place!)
                    
                    x += 1
                    // Do any additional setup after loading the view.
                }
                
                self.maps.reloadInputViews()
                
                if self.lingua.contains("pt") {
                  
                } else if self.lingua.contains("es") {
                    self.hidra.setTitle("Lista de puntos", for: UIControl.State.normal)
                    self.eventos_prox.setTitle("cerca de mi", for: UIControl.State.normal)
                } else {
                    self.hidra.setTitle("List of attractions", for: UIControl.State.normal)
                    self.eventos_prox.setTitle("near me", for: UIControl.State.normal)
                }
                
                

                
                self.hidra.applyGradient(colours: [UIColor(red: 0.22, green: 0.51, blue: 0.75, alpha: 1.00), UIColor(red: 0.31, green: 0.62, blue: 0.87, alpha: 1.00)], radius: 6, sentido: "Horizontal")
                self.eventos_prox.applyGradient(colours: [UIColor(red: 0.22, green: 0.51, blue: 0.75, alpha: 1.00), UIColor(red: 0.31, green: 0.62, blue: 0.87, alpha: 1.00)], radius: 6, sentido: "Horizontal")
              

                
                self.removeAllOverlays()
            }
            
        }
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
    
    @IBAction func lista_eventos(_ sender: Any) {
        let vc = ListaTurismoViewController(nibName:"ListaTurismoViewController", bundle:nil)
        self.navigationController!.pushViewController(vc, animated: true)
    }
    
    func showInfoView(forPlace place: Place) {
        let uiAlert = UIAlertController(title: place.placeName, message: place.desc, preferredStyle: UIAlertController.Style.alert)
        uiAlert.addAction(UIAlertAction(title: "Ver mais", style: .default, handler: { action in
            print("Click of default button")
        }))
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
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension TurismoViewController: ARDataSource {
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

extension TurismoViewController: AnnotationViewDelegate {
    func didTouch(annotationView: AnnotationView) {
        if let annotation = annotationView.annotation as? Place {
            self.showInfoView(forPlace: annotation)
        }
    }
}
