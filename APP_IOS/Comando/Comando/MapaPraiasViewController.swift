//
//  MapaPraiasViewController.swift
//  Comando
//
//  Created by Candido Bugarin on 06/12/18.
//  Copyright © 2018 Candido Bugarin. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class MapaPraiasViewController: UIViewController,MKMapViewDelegate{

    @IBOutlet weak var maps: MKMapView!
    let locManager = CLLocationManager()
    
    @IBOutlet weak var realidadeaumentada: UIButton!
    let dispatchQueue = DispatchQueue(label: "Dispatch Queue", attributes: [], target: nil)
    
    var fav3: Array<Praias> = []
    
    var places = [Place]()
    
    var arViewController: ARViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        realidadeaumentada.layer.cornerRadius = 5
        realidadeaumentada.layer.borderColor = UIColor(red:0.00, green:0.51, blue:0.69, alpha:1.0).cgColor
        realidadeaumentada.layer.borderWidth = 1
        
        maps.userTrackingMode = MKUserTrackingMode.followWithHeading
        maps.showsUserLocation = true
        maps.delegate = self
        
        self.fav3 = ColetaDados_Praias.getdata()
        
        self.title = "Mapa - Praias"
        
        let launchedBefore = UserDefaults.standard.bool(forKey: "launchedBefore")
        
        if launchedBefore == false {
            locManager.requestWhenInUseAuthorization()
        } else {
            if CLLocationManager.locationServicesEnabled() {
                switch(CLLocationManager.authorizationStatus()) {
                case .notDetermined, .restricted, .denied:
                    let alert = UIAlertController(title: "Localização", message: "Seus serviços de localização não foram autorizados. Eles são fundamentais para a visualização das informações. Permita a localização para poder ver o conteúdo.", preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "Ok!", style: UIAlertAction.Style.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                case .authorizedAlways, .authorizedWhenInUse:
                    locManager.desiredAccuracy = kCLLocationAccuracyBest
                    locManager.startUpdatingLocation()
                }
            } else {
                let alert = UIAlertController(title: "Localização", message: "Estamos enfretando problemas com sua localização, estamos tentando restabelecer a conexão.", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Ok!", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
        
        let latitude:CLLocationDegrees = -22.9241421//insert latitutde
        let longitude:CLLocationDegrees = -43.4405087 //insert longitude
        let latDelta:CLLocationDegrees = 1
        let lonDelta:CLLocationDegrees = 1
        let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        let location = CLLocationCoordinate2DMake(latitude, longitude)
        let region = MKCoordinateRegion(center: location, span: span)
        maps.setRegion(region, animated: false)
        
        
        var x = 0
        while x != self.fav3.count {
            let point = StoreAnnotation(coordinate:  CLLocationCoordinate2D(latitude: CLLocationDegrees(self.fav3[x].lat) , longitude: CLLocationDegrees(self.fav3[x].lon)))
            point.title = self.fav3[x].nome
            point.subtitle = String(self.fav3[x].status)
            self.maps.addAnnotation(point)
            let location = CLLocation(latitude: (Double(self.fav3[x].lat)), longitude: (Double(self.fav3[x].lon)))
            let place = Place(location: location, name: self.fav3[x].nome+" - "+self.fav3[x].status+"", desc: self.fav3[x].status)
            self.places.append(place!)
            x += 1
        }
    
    }
    
    func showInfoView(forPlace place: Place) {
        
        let alert = UIAlertController(title:place.placeName, message: place.desc, preferredStyle: UIAlertController.Style.alert)
        self.present(alert, animated: true, completion: nil)
        
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { action in
            print("Click of default button")
        }))
        
        arViewController.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func activear(_ sender: UIButton) {
        arViewController = ARViewController()
        arViewController.dataSource = self as ARDataSource
        arViewController.presenter.distanceOffsetMode = .automatic
        arViewController.presenter.distanceOffsetMultiplier = 0.1   // Pixels per meter
        //arViewController.presenter.distanceOffsetMinThreshold = 0 // Doesn't raise annotations that are nearer than this
        arViewController.presenter.maxDistance = 0               // Don't show annotations if they are farther than this
        arViewController.presenter.maxVisibleAnnotations = 100      // Max number of annotations on the screen
        arViewController.presenter.verticalStackingEnabled = true
        arViewController.trackingManager.userDistanceFilter = 15
        arViewController.trackingManager.reloadDistanceFilter = 50
        arViewController.uiOptions.closeButtonEnabled = true
        arViewController.uiOptions.debugLabel = false
        arViewController.uiOptions.debugMap = false
        arViewController.uiOptions.simulatorDebugging = Platform.isSimulator
        arViewController.uiOptions.setUserLocationToCenterOfAnnotations =  Platform.isSimulator
        arViewController.interfaceOrientationMask = .all
        arViewController.setAnnotations(places)
        self.present(arViewController, animated: true, completion: nil)
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
            annotationView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        
        let button = UIButton(type: .detailDisclosure)
        button.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        button.setTitle("", for: .normal)
        button.setTitleColor(UIColor(red:0.00, green:0.00, blue:256.00, alpha:1.0), for: .normal)
        
        annotationView?.rightCalloutAccessoryView = button
        
        if let annotationView = annotationView {
            // Configure your annotation view here
            annotationView.canShowCallout = true
            if (annotationView.annotation?.subtitle ?? nil)!.contains("Própria") {
                annotationView.image = UIImage(named: "verde.png")
            } else {
                 annotationView.image = UIImage(named: "vermelha.png")
            }
        }
        
        return annotationView
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

extension MapaPraiasViewController: ARDataSource {
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

extension MapaPraiasViewController: AnnotationViewDelegate {
    func didTouch(annotationView: AnnotationView) {
        if let annotation = annotationView.annotation as? Place {
            self.showInfoView(forPlace: annotation)
        }
    }
}

