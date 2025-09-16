//
//  MapaTemperaturaViewController.swift
//  Comando
//
//  Created by Candido Bugarin on 31/01/19.
//  Copyright © 2019 Candido Bugarin. All rights reserved.
//

import UIKit
import MapKit

class MapaTemperaturaViewController: UIViewController ,MKMapViewDelegate {
    
    @IBOutlet weak var temp_but: UIButton!
    @IBOutlet weak var maps: MKMapView!
    var fav3: Array<EstacaoMete> = []
    
    var nome: Array<String> = []
    var temperatura: Array<Double> = []
    var umidade: Array<Double> = []
    var vel: Array<Double> = []
    var fonte: Array<String> = []
    
    let locManager = CLLocationManager()
    
    let dispatchQueue = DispatchQueue(label: "Dispatch Queue", attributes: [], target: nil)
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
            
            navigationController?.navigationItem.titleView = logoContainer
            
            navigationController?.navigationBar.scrollEdgeAppearance = navigationController?.navigationBar.standardAppearance
            
            let rightBarButton = UIBarButtonItem(image: myimage, style: UIBarButtonItem.Style.plain, target: self, action: "")
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
            
            // Do any additional setup after loading the view.
        }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let posicao = (nome.indexes(of: (view.annotation?.title ?? nil)!))
        
        if lingua.contains("pt") {
            var st = ""
            if vel[posicao[0]] != 999 && temperatura[posicao[0]] != 999 && vel[posicao[0]] != 0 {
                let pc1 = (10*(vel[posicao[0]]).squareRoot())+(10.45 - (vel[posicao[0]]))
                let pc2 = (((temperatura[posicao[0]])-33)/22)
                st = String(format: "%.0f",33+(pc1*pc2))+"ºC"
            } else {
                st = "Sem infos."
            }
            
            let fonte_e = fonte[posicao[0]]
            
            var vento = ""
            var vel_v = String(format: "%.0f",vel[posicao[0]]*3.6)+" Km/H"
            if vel[posicao[0]] > 0 && vel[posicao[0]] <= 5.1 {
                vento = "Fraco"
            } else if vel[posicao[0]] > 5.1 && vel[posicao[0]] <= 14.4 {
                vento = "Moderado"
            } else if vel[posicao[0]] > 14.4 && vel[posicao[0]] <= 21.0 {
                vento = "Forte"
            } else if vel[posicao[0]] > 21.0 {
                vento = "Muito Forte"
            } else {
                vel_v = "Sem infos."
                vento = "Sem infos."
            }
            let alert = UIAlertController(title: nome[posicao[0]], message: "Temperatura: "+String(format: "%.0f",temperatura[posicao[0]])+" ºC\nUmidade: "+String(format: "%.0f",umidade[posicao[0]])+" %\nSensação térmica: "+st+" \nVento:  "+vento+"\nVelocidade: "+vel_v+" \nFonte: "+fonte_e+" \n", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
           
        } else if lingua.contains("es") {
            var st = ""
            if vel[posicao[0]] != 999 && temperatura[posicao[0]] != 999 && vel[posicao[0]] != 0 {
                let pc1 = (10*(vel[posicao[0]]).squareRoot())+(10.45 - (vel[posicao[0]]))
                let pc2 = (((temperatura[posicao[0]])-33)/22)
                st = String(format: "%.0f",33+(pc1*pc2))+"ºC"
            } else {
                st = "Sin información"
            }
            
            let fonte_e = fonte[posicao[0]]
            
            var vento = ""
            var vel_v = String(format: "%.0f",vel[posicao[0]]*3.6)+" Km/H"
            if vel[posicao[0]] > 0 && vel[posicao[0]] <= 5.1 {
                vento = "suave"
            } else if vel[posicao[0]] > 5.1 && vel[posicao[0]] <= 14.4 {
                vento = "Moderado"
            } else if vel[posicao[0]] > 14.4 && vel[posicao[0]] <= 21.0 {
                vento = "fuerte"
            } else if vel[posicao[0]] > 21.0 {
                vento = "muy fuerte"
            } else {
                vel_v = "Sin información"
                vento = "Sin información"
            }
            let alert = UIAlertController(title: nome[posicao[0]], message: "Temperatura: "+String(format: "%.0f",temperatura[posicao[0]])+" ºC\nHumedad del aire: "+String(format: "%.0f",umidade[posicao[0]])+" %\nSensación térmica: "+st+" \nViento:  "+vento+"\nVelocidad del viento: "+vel_v+" \nOrigen: "+fonte_e+" \n", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)

        } else {
            var st = ""
            if vel[posicao[0]] != 999 && temperatura[posicao[0]] != 999 && vel[posicao[0]] != 0 {
                let pc1 = (10*(vel[posicao[0]]).squareRoot())+(10.45 - (vel[posicao[0]]))
                let pc2 = (((temperatura[posicao[0]])-33)/22)
                st = String(format: "%.0f",33+(pc1*pc2))+"ºC"
            } else {
                st = "no information"
            }
            
            let fonte_e = fonte[posicao[0]]
            
            var vento = ""
            var vel_v = String(format: "%.0f",vel[posicao[0]]*3.6)+" Km/H"
            if vel[posicao[0]] > 0 && vel[posicao[0]] <= 5.1 {
                vento = "breeze"
            } else if vel[posicao[0]] > 5.1 && vel[posicao[0]] <= 14.4 {
                vento = "Moderate"
            } else if vel[posicao[0]] > 14.4 && vel[posicao[0]] <= 21.0 {
                vento = "strong"
            } else if vel[posicao[0]] > 21.0 {
                vento = "Very strong"
            } else {
                vel_v = "no information"
                vento = "no information"
            }
            let alert = UIAlertController(title: nome[posicao[0]], message: "Temperature: "+String(format: "%.0f",temperatura[posicao[0]])+" ºC\nAir humidity: "+String(format: "%.0f",umidade[posicao[0]])+" %\nThermal sensation: "+st+" \nWind:  "+vento+"\nWind speed: "+vel_v+" \nSource: "+fonte_e+" \n", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)

        }
        
        
       
        }
    
    @IBAction func temp_act(_ sender: UIButton) {
        let vc = MeteoTableViewController(nibName:"MeteoTableViewController", bundle:nil)
        self.navigationController!.pushViewController(vc, animated: true)
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
            self.title = "Estações meteorológicas"
    
        } else if lingua.contains("es") {
            self.title = "Estaciones meteorológicas"
            self.temp_but.setTitle("lista de estaciones meteorológicas", for: UIControl.State.normal)
        } else {
            self.title = "Weather stations"
            self.temp_but.setTitle("list of weather stations", for: UIControl.State.normal)
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
                
                
                self.fav3 = EstacaoMet.getEsta()
                
                var x = 0
                while x != self.fav3.count {
                    self.nome.append(self.fav3[x].nome.replacingOccurrences(of: "Rio de Janeiro - ", with: "").replacingOccurrences(of: "-A602", with: "").replacingOccurrences(of: "-A621", with: "").replacingOccurrences(of: "-A652", with: ""))
                    self.temperatura.append(Double(self.fav3[x].tem_med))
                    self.umidade.append(Double(self.fav3[x].umd_med))
                    self.vel.append(Double(self.fav3[x].vel_med))
                    
                    self.fonte.append(String(self.fav3[x].fonte))
                    
                    let point = StoreAnnotation(coordinate:  CLLocationCoordinate2D(latitude: CLLocationDegrees(self.fav3[x].lat) , longitude: CLLocationDegrees(self.fav3[x].lon)))
                    point.title = self.fav3[x].nome.replacingOccurrences(of: "Rio de Janeiro - ", with: "").replacingOccurrences(of: "-A602", with: "").replacingOccurrences(of: "-A621", with: "").replacingOccurrences(of: "-A652", with: "")
                    point.subtitle = "Temperatura: "+String(format: "%.0f",self.fav3[x].tem_med)+" ºC"
                    self.maps.addAnnotation(point)
                    x += 1
                    
                
            }
                self.maps.reloadInputViews()
                
                self.temp_but.applyGradient(colours: [UIColor(red: 0.22, green: 0.51, blue: 0.75, alpha: 1.00), UIColor(red: 0.31, green: 0.62, blue: 0.87, alpha: 1.00)], radius: 6, sentido: "Horizontal")
                
                self.removeAllOverlays()
        }
        
    }
    
}
}

extension Array where Element: Equatable {
    func indexes(of element: Element) -> [Int] {
        return self.enumerated().filter({ element == $0.element }).map({ $0.offset })
    }
}
