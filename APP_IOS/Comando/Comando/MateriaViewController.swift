//
//  MateriaViewController.swift
//  ClipRJ
//
//  Created by Candido Bugarin on 28/09/19.
//  Copyright © 2019 Candido Bugarin. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class MateriaViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var fonte: UILabel!
    @IBOutlet weak var temalabel: UILabel!
    @IBOutlet weak var imagem: UIImageView!
    @IBOutlet weak var view_fora: UIView!
    @IBOutlet weak var texto: UITextView!
    @IBOutlet weak var titulolabel: UILabel!
    
    @IBOutlet weak var share: UIButton!
    @IBOutlet weak var fav: UIButton!
    
    @IBOutlet weak var mapView: MKMapView!
    
    var texto_input = ""
    var fonte_t = ""
    var data = ""
    var titulo = ""
    var poli = ""
    var points = [CLLocationCoordinate2D]()

    
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

        self.titulolabel.text = titulo
        title = fonte_t
        
        self.texto.text = texto_input.replacingOccurrences(of: "pulalinha", with: "\n").replacingOccurrences(of: "pontovirgula", with: ";")

        view_fora.layer.cornerRadius = 5
        view_fora.layer.masksToBounds = false
        
        view_fora.layer.shadowColor = UIColor.gray.cgColor
        view_fora.layer.shadowOpacity = 0.5
        view_fora.layer.shadowOffset = CGSize.zero
        view_fora.layer.shadowRadius = 3
        
        let defaults = UserDefaults.standard
         
        let array = defaults.object(forKey:"SavedArray") as? [String] ?? [String]()
        
         self.texto.isSelectable = true
         self.texto.dataDetectorTypes = .link
        
        mapView.delegate = self as! MKMapViewDelegate
        mapView.layer.cornerRadius = 5


        let latitude:CLLocationDegrees = -22.9241421//insert latitutde
        let longitude:CLLocationDegrees = -43.4405087 //insert longitud
        let location = CLLocationCoordinate2DMake(latitude, longitude)
        
        let viewRegion = MKCoordinateRegion(center: location, latitudinalMeters: 45000, longitudinalMeters: 45000)
        
        mapView.setRegion(viewRegion, animated: false)
        
        let myStrings = poli.components(separatedBy: "],")
        let characters = Array(myStrings)
        var x = 0
        while x != (characters.count) {
            let lat = Double(characters[x].split(separator: ",")[1].replacingOccurrences(of: "[",with: "").replacingOccurrences(of: "]",with: "").replacingOccurrences(of: " ",with: "")) ?? 0.0
            let lon = Double(characters[x].split(separator: ",")[0].replacingOccurrences(of: "[",with: "").replacingOccurrences(of: "]",with: "").replacingOccurrences(of: " ",with: "")) ?? 0.0
            points.append(CLLocationCoordinate2DMake(lat, lon))
            
            let point = StoreAnnotation(coordinate:  CLLocationCoordinate2D(latitude: lat , longitude: lon))
            self.mapView.addAnnotation(point)
            
            x += 1
            }
        
        let polygon = MKPolyline(coordinates: points, count: points.count)
        print(polygon)
        mapView.addOverlay(polygon)
                
        
        // Do any additional setup after loading the view.
    }
    

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
       if overlay is MKPolyline {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.fillColor = UIColor.black.withAlphaComponent(0.9)
              renderer.strokeColor = UIColor.blue
        renderer.lineWidth = 2.5
              return renderer
        }
        
        return MKOverlayRenderer()
    }
    
    
    @IBAction func share_act(_ sender: UIButton) {
    
    let myWebsite = NSURL(string:"https://apps.apple.com/br/app/cor-rio/id1478320199")
    let shareAll = [myWebsite]
    let activityViewController = UIActivityViewController(activityItems: shareAll, applicationActivities: nil)
    activityViewController.popoverPresentationController?.sourceView = self.view
    self.present(activityViewController, animated: true, completion: nil)
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
