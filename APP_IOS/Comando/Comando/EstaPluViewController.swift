//
//  EstaPluViewController.swift
//  DCNI
//
//  Created by Candido Bugarin on 13/10/17.
//  Copyright © 2017 Candido Bugarin. All rights reserved.
//

import UIKit
import MapKit

class EstaPluViewController: UIViewController,MKMapViewDelegate {

    @IBOutlet weak var donte: UILabel!
    @IBOutlet weak var data: UILabel!
    @IBOutlet weak var inst: UILabel!
    @IBOutlet weak var hora1: UILabel!
    @IBOutlet weak var hora4: UILabel!
    @IBOutlet weak var hora24: UILabel!
    @IBOutlet weak var hora96: UILabel!
    @IBOutlet weak var hora30: UILabel!
    @IBOutlet weak var maps: MKMapView!
    
    let locManager = CLLocationManager()
    let dispatchQueue = DispatchQueue(label: "Dispatch Queue", attributes: [], target: nil)
    
    var fav3: Array<Estacao> = []
    
    var lingua = ""
    
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
        
        self.maps.layer.cornerRadius = 10
        self.maps.layer.borderWidth = 2.5
        self.maps.layer.borderColor =  UIColor(red:0.00, green:0.51, blue:0.69, alpha:1.0).cgColor
        
        self.inst.layer.cornerRadius = 10
        self.inst.layer.borderWidth = 2.5
        self.inst.layer.borderColor = UIColor(red:0.00, green:0.51, blue:0.69, alpha:1.0).cgColor
        
        self.hora1.layer.cornerRadius = 10
        self.hora1.layer.borderColor = UIColor(red:0.00, green:0.51, blue:0.69, alpha:1.0).cgColor
        self.hora1.layer.borderWidth = 2.5
        
        self.hora4.layer.cornerRadius = 10
        self.hora4.layer.borderColor = UIColor(red:0.00, green:0.51, blue:0.69, alpha:1.0).cgColor
        self.hora4.layer.borderWidth = 2.5
        
        self.hora24.layer.cornerRadius = 10
        self.hora24.layer.borderColor = UIColor(red:0.00, green:0.51, blue:0.69, alpha:1.0).cgColor
        self.hora24.layer.borderWidth = 2.5
        
        self.hora96.layer.cornerRadius = 10
        self.hora96.layer.borderColor = UIColor(red:0.00, green:0.51, blue:0.69, alpha:1.0).cgColor
        self.hora96.layer.borderWidth = 2.5
        
        self.hora30.layer.cornerRadius = 10
        self.hora30.layer.borderColor = UIColor(red:0.00, green:0.51, blue:0.69, alpha:1.0).cgColor
        self.hora30.layer.borderWidth = 2.5
        
        self.data.layer.cornerRadius = 10
        self.data.layer.borderColor = UIColor(red:0.00, green:0.51, blue:0.69, alpha:1.0).cgColor
        self.data.layer.borderWidth = 2.5
        
        self.donte.layer.cornerRadius = 10
        self.donte.layer.borderColor = UIColor(red:0.00, green:0.51, blue:0.69, alpha:1.0).cgColor
        self.donte.layer.borderWidth = 2.5
        
        locManager.requestWhenInUseAuthorization()
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
        
        let point = StoreAnnotation(coordinate:  CLLocationCoordinate2D(latitude: CLLocationDegrees(self.fav3[0].lat) , longitude: CLLocationDegrees(self.fav3[0].lon)))
        point.title = self.fav3[0].nome
        
        
        if lingua.contains("pt") {
            if self.fav3[0].situ.contains("atual") {
                point.subtitle = "Chuva na última hora: " + String(self.fav3[0].chuva_1)
            } else if self.fav3[0].situ.contains("atraso") {
                point.subtitle = "Sem informações"
            }
           
        } else if lingua.contains("es") {
            if self.fav3[0].situ.contains("atual") {
                point.subtitle = "Lluvia en la última hora: " + String(self.fav3[0].chuva_1)
            } else if self.fav3[0].situ.contains("atraso") {
                point.subtitle = "Sin información"
            }
        } else {
            if self.fav3[0].situ.contains("atual") {
                point.subtitle = "Rain in the last hour: " + String(self.fav3[0].chuva_1)
            } else if self.fav3[0].situ.contains("atraso") {
                point.subtitle = "No information"
            }
        }
        
        
    
        
        self.maps.addAnnotation(point)
        self.maps.setRegion(MKCoordinateRegion.init(center: CLLocationCoordinate2D(latitude: (self.fav3[0].lat), longitude: (self.fav3[0].lon)), latitudinalMeters: 5000,longitudinalMeters: 5000), animated: false)
        
        self.title = self.fav3[0].nome
        
        if lingua.contains("pt") {
            self.data.text = "Atualizado as: \n" + self.fav3[0].data
            self.inst.text = String(self.fav3[0].chuva_i) + " mm \n Chuva Inst."
            self.hora1.text = String(self.fav3[0].chuva_1) + " mm \n Chuva em 1h"
            self.hora4.text = String(self.fav3[0].chuva_4) + " mm \n Chuva em 4h"
            self.hora24.text = String(self.fav3[0].chuva_24) + " mm \n Chuva em 24h"
            self.hora96.text = String(self.fav3[0].chuva_96) + " mm \n Chuva em 96h"
            self.hora30.text = String(self.fav3[0].chuva_30) + " mm \n Chuva 30D"
            self.donte.text = "Fonte: \n"+String(self.fav3[0].fonte)
           
        } else if lingua.contains("es") {
            self.data.text = "Actualizado el: \n" + self.fav3[0].data
            self.inst.text = String(self.fav3[0].chuva_i) + " mm \n Lluvia ahora"
            self.hora1.text = String(self.fav3[0].chuva_1) + " mm \n Lluvia en 1h"
            self.hora4.text = String(self.fav3[0].chuva_4) + " mm \n Lluvia en 4h"
            self.hora24.text = String(self.fav3[0].chuva_24) + " mm \n Lluvia en 24h"
            self.hora96.text = String(self.fav3[0].chuva_96) + " mm \n Lluvia en 96h"
            self.hora30.text = String(self.fav3[0].chuva_30) + " mm \n Lluvia en 30D"
            self.donte.text = "Origen: \n"+String(self.fav3[0].fonte)
        } else {
            self.data.text = "Updated the: \n" + self.fav3[0].data
            self.inst.text = String(self.fav3[0].chuva_i) + " mm \n Rain now."
            self.hora1.text = String(self.fav3[0].chuva_1) + " mm \n Rain in 1h"
            self.hora4.text = String(self.fav3[0].chuva_4) + " mm \n Rain in 4h"
            self.hora24.text = String(self.fav3[0].chuva_24) + " mm \n Rain in 24h"
            self.hora96.text = String(self.fav3[0].chuva_96) + " mm \n Rain in 96h"
            self.hora30.text = String(self.fav3[0].chuva_30) + " mm \n Rain in 30D"
            self.donte.text = "Source: \n"+String(self.fav3[0].fonte)
        }
        

        
    
        

        // Do any additional setup after loading the view.
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
            annotationView.canShowCallout = true
            if (annotationView.annotation?.subtitle)! == "Sirene" {
                annotationView.image = UIImage(named: "icones/sirene_nova.png")
            } else if (annotationView.annotation?.subtitle)! == "Pontos de Apoio" {
                annotationView.image = UIImage(named: "icones/house.png")
            } else if ((annotationView.annotation?.subtitle)!)!.contains("Chuva na última hora: ") {
                let valor_chuva = Double((((annotationView.annotation?.subtitle)!)!)!.replacingOccurrences(of: "Chuva na última hora: ", with: "", options: NSString.CompareOptions.literal, range:nil))
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
            } else if ((annotationView.annotation?.subtitle)!)!.contains("Sem informações") {
                annotationView.image = #imageLiteral(resourceName: "gra-blank.png")
            }
        }
        return annotationView
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
