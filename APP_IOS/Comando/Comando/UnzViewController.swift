//
//  UnzViewController.swift
//  Comando
//
//  Created by Candido Bugarin on 18/07/19.
//  Copyright © 2019 Candido Bugarin. All rights reserved.
//


import UIKit
import MapKit

class Polyline: MKPolyline {
    var color: UIColor?
}

class UnzViewController: UIViewController,MKMapViewDelegate {
    
    @IBOutlet weak var maps: MKMapView!
    let locManager = CLLocationManager()
    @IBOutlet weak var botao_rep: UIButton!
    
    let dispatchQueue = DispatchQueue(label: "Dispatch Queue", attributes: [], target: nil)
    
    var fav: Array<Interdicoes> = []
    
    override func viewDidLoad() {
    super.viewDidLoad()
        
        if #available(iOS 15, *) {
            
            let logoContainer = UIView(frame: CGRect(x: 0, y: 0, width: 270, height: 30))
            
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(red:0.00, green:0.34, blue:0.75, alpha:1.0)
            appearance.shadowColor = .none
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationItem.titleView = logoContainer
            navigationController?.navigationBar.scrollEdgeAppearance = navigationController?.navigationBar.standardAppearance
            
        
            
        }
        
        botao_rep.layer.cornerRadius = 5
        botao_rep.layer.borderColor = UIColor(red:0.00, green:0.51, blue:0.69, alpha:1.0).cgColor
        botao_rep.layer.borderWidth = 1
        
        maps.delegate = self
        maps.userTrackingMode = MKUserTrackingMode.followWithHeading
        maps.showsUserLocation = true
        maps.delegate = self
        
        title = "Pontos de retenção"
        
        let launchedBefore = UserDefaults.standard.bool(forKey: "launchedBefore")
        
        if launchedBefore == false {
            self.locManager.requestWhenInUseAuthorization()
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
    }

    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        if let polyline = overlay as? Polyline {
            
            let polylineRenderer = MKPolylineRenderer(overlay: polyline)
            polylineRenderer.strokeColor = polyline.color
            polylineRenderer.lineWidth = 5
            return polylineRenderer
        }
        
        return MKOverlayRenderer(overlay: overlay)
        
    }
    @IBAction func open_ret(_ sender: UIButton) {
        let vc = UnzListaViewController(nibName:"UnzListaViewController", bundle:nil)
        vc.fav = self.fav
        self.navigationController!.pushViewController(vc, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Hide the navigation bar on the this view controller
        
        let text = "Coletando informações"
        self.showWaitOverlayWithText(text)
        
        dispatchQueue.async {
            OperationQueue.main.addOperation() {
                self.fav = ColetaDados_Vias.getdata()
                
                var x = 0
                while x != self.fav.count {
                    
                    let dados = self.fav[x].poli.components(separatedBy: "pontovirgula")
                   
                    var points: Array<CLLocationCoordinate2D> = []
                    
                    var y = 0
                    while y != dados.count-1 {
                        let p = CLLocationCoordinate2DMake(Double(dados[y].components(separatedBy: ",")[0]) as! CLLocationDegrees,  Double(dados[y].components(separatedBy: ",")[1]) as! CLLocationDegrees)
                        points.append(p)
                        y += 1
                    }
                    
                    if self.fav[x].status.contains("Baixo") {
                        let plo = Polyline(coordinates: points, count: points.count)
                        plo.color = UIColor(red:0.16, green:0.65, blue:0.27, alpha:1.0)
                        self.maps?.addOverlay(plo)
                    } else if self.fav[x].status.contains("Médio") {
                        let plo = Polyline(coordinates: points, count: points.count)
                        plo.color = UIColor(red:1.00, green:0.76, blue:0.03, alpha:1.0)
                        self.maps?.addOverlay(plo)
                    } else if self.fav[x].status.contains("Alto") {
                        let plo = Polyline(coordinates: points, count: points.count)
                        plo.color = UIColor(red:0.95, green:0.24, blue:0.02, alpha:1.0)
                        self.maps?.addOverlay(plo)
                    }
                    
                    
                    
                    x += 1
                }
                

                self.removeAllOverlays()
                
                
            }
        }
    }


    
    
    
}
