//
//  OcorrenciaPageViewController.swift
//  Comando
//
//  Created by Candido Bugarin on 13/08/19.
//  Copyright © 2019 Candido Bugarin. All rights reserved.
//

import UIKit
import MapKit

class OcorrenciaPageViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var maps: MKMapView!
    @IBOutlet weak var texto: UITextView!
    
    var lat = 0.0
    var lon = 0.0
    var acidente_texto = ""
    var tipo_texto = ""
    var end_texto = ""
    var id = ""
    var data = ""
    
    var fav6: Array<Fotos> = []
    
    let dispatchQueue = DispatchQueue(label: "Dispatch Queue", attributes: [], target: nil)
    var lingua = ""
    
    @IBOutlet weak var view_fora: UIView!
    
    @IBOutlet weak var foto_but: UIButton!
    
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
        
        view_fora.layer.cornerRadius = 5
        view_fora.layer.masksToBounds = false
        
        view_fora.layer.shadowColor = UIColor.gray.cgColor
        view_fora.layer.shadowOpacity = 0.5
        view_fora.layer.shadowOffset = CGSize.zero
        view_fora.layer.shadowRadius = 3

        
        maps.userTrackingMode = MKUserTrackingMode.followWithHeading
        maps.showsUserLocation = true
        maps.delegate = self
        
        
        if self.lingua.contains("pt") {
            self.title = "Incidente"
        } else if self.lingua.contains("es") {
            self.title = "Incidente"
        } else {
            self.title = "Incident"
            self.foto_but.setTitle("Photos", for: UIControl.State.normal)
        }
        
        
        self.texto.text = acidente_texto+"\n\n"+end_texto+"\n\n"+data
        

        let latitude:CLLocationDegrees = lat //insert latitutde
        let longitude:CLLocationDegrees = lon //insert longitud
        let location = CLLocationCoordinate2DMake(latitude, longitude)
        let viewRegion = MKCoordinateRegion(center: location, latitudinalMeters: 10000, longitudinalMeters: 10000)
        maps.setRegion(viewRegion, animated: false)
        
        let point = StoreAnnotation(coordinate:  CLLocationCoordinate2D(latitude: CLLocationDegrees(lat) , longitude: CLLocationDegrees(lon)))
        point.title = acidente_texto.replacingOccurrences(of: "Incidente", with: "")
        point.subtitle = tipo_texto
        self.maps.addAnnotation(point)
        
        self.maps.layer.cornerRadius = 10
        
        
        

        // Do any additional setup after loading the view.
    }


    @IBAction func fotos_act(_ sender: UIButton) {
        if self.fav6.count == 0 {
            let alert = UIAlertController(title: "Ops!", message: "Parece que não temos fotos para essa ocorrência.", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } else {
            let vc = FotoViewController(nibName:"FotoViewController", bundle:nil)
            vc.fav6 = self.fav6
            self.navigationController!.pushViewController(vc, animated: true)
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Hide the navigation bar on the this view controller
        
        

        
        
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
                            
                self.fav6 = ColetaDados_Fotos.getdata(id: self.id)
                self.removeAllOverlays()
                
                
                self.foto_but.applyGradient(colours: [UIColor(red: 0.22, green: 0.51, blue: 0.75, alpha: 1.00), UIColor(red: 0.31, green: 0.62, blue: 0.87, alpha: 1.00)], radius: 12, sentido: "Horizontal")
                
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
