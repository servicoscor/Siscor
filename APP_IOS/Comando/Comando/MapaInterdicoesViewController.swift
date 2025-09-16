//
//  MapaInterdicoesViewController.swift
//  Comando
//
//  Created by Candido Bugarin on 05/12/18.
//  Copyright © 2018 Candido Bugarin. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class MapaInterdicoesViewController: UIViewController ,MKMapViewDelegate {
    
    @IBOutlet weak var maps: MKMapView!
    let locManager = CLLocationManager()
    @IBOutlet weak var interdicoes_but: UIButton!
    
    let dispatchQueue = DispatchQueue(label: "Dispatch Queue", attributes: [], target: nil)
    
    var fav3: Array<Interdicoes> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        maps.userTrackingMode = MKUserTrackingMode.followWithHeading
        maps.showsUserLocation = true
        maps.delegate = self
        
        interdicoes_but.layer.cornerRadius = 5
        interdicoes_but.layer.borderColor = UIColor(red:0.00, green:0.51, blue:0.69, alpha:1.0).cgColor
        interdicoes_but.layer.borderWidth = 1
        
        
        self.title = "Interdições"
        
        let launchedBefore = UserDefaults.standard.bool(forKey: "launchedBefore")
        
        if launchedBefore == false {
            locManager.requestWhenInUseAuthorization()
        } else {
            if CLLocationManager.locationServicesEnabled() {
                switch(CLLocationManager.authorizationStatus()) {
                case .notDetermined, .restricted, .denied:
                    let alert = UIAlertController(title: "Localização", message: "Seus serviços de localização não foram autorizados. Eles são fundamentais para a visualização das informações. Permita a localização para poder ver o conteúdo.", preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    
                case .authorizedAlways, .authorizedWhenInUse:
                    locManager.desiredAccuracy = kCLLocationAccuracyBest
                    locManager.startUpdatingLocation()
                
                    
                }
            } else {
                let alert = UIAlertController(title: "Localização", message: "Estamos enfretando problemas com sua localização, estamos tentando restabelecer a conexão.", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                
            }
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
        
        
        var x = 0
        while x != self.fav3.count {
            let point = StoreAnnotation(coordinate:  CLLocationCoordinate2D(latitude: CLLocationDegrees(self.fav3[x].lat) , longitude: CLLocationDegrees(self.fav3[x].lon)))
            point.title = self.fav3[x].nome
            point.subtitle = String(self.fav3[x].status)
            self.maps.addAnnotation(point)
            x += 1
            
        }
        
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
        
        
        if let annotationView = annotationView {
            // Configure your annotation view here
            annotationView.canShowCallout = false
            annotationView.image = UIImage(named: "alert_icon.png")
        }
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let alert = UIAlertController(title: view.annotation?.title ?? nil, message: view.annotation?.subtitle ?? nil, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func interdicoes_act(_ sender: UIButton) {
        let vc = InterdicoesViewController(nibName:"InterdicoesViewController", bundle:nil)
        self.navigationController!.pushViewController(vc, animated: true)
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        //Return an `MKPolylineRenderer` for the `MKPolyline` in the `MKMapViewDelegate`s method
        if let polyline = overlay as? MKPolyline {
            let testlineRenderer = MKPolylineRenderer(polyline: polyline)
            testlineRenderer.strokeColor = .red
            testlineRenderer.lineWidth = 2.0
            return testlineRenderer
        }
        fatalError("Something wrong...")
        //return MKOverlayRenderer()
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

