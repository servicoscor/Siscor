//
//  ReportarViewController.swift
//  Comando
//
//  Created by Candido Bugarin on 01/05/19.
//  Copyright © 2019 Candido Bugarin. All rights reserved.
//

import UIKit
import CoreLocation
import Firebase
import FirebaseInstanceID
import FirebaseMessaging

class ReportarViewController: UIViewController, CLLocationManagerDelegate,MessagingDelegate {

    let colors = ["Queda de Árvore","Bolsão d'Água","Chuva Forte","Buracos na via","Problemas em semáforos","Iluminação pública","Acidentes","Obstrução na via"]

    let colors_se = ["1","2","3","4","5","6","7","8"]
    
    
    let locationManager = CLLocationManager() // create Location Manager object
    var latitude : Double?
    var longitude : Double?
    
    var device_uuid: String = ""
    var selectedValue: String = ""
    
    @IBOutlet weak var arvore_but: UIButton!
    @IBOutlet weak var alagamento_but: UIButton!
    @IBOutlet weak var acidente_but: UIButton!
    @IBOutlet weak var eventos_but: UIButton!
    @IBOutlet weak var desli_but: UIButton!
    @IBOutlet weak var obs_but: UIButton!
    
    
    var currentLocation: CLLocation!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Reportar Ocorrência"
        
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
        
        arvore_but.layer.cornerRadius = 5
        arvore_but.layer.borderColor = UIColor(red:0.00, green:0.51, blue:0.69, alpha:1.0).cgColor
        arvore_but.layer.borderWidth = 1
        
        alagamento_but.layer.cornerRadius = 5
        alagamento_but.layer.borderColor = UIColor(red:0.00, green:0.51, blue:0.69, alpha:1.0).cgColor
        alagamento_but.layer.borderWidth = 1
        
        acidente_but.layer.cornerRadius = 5
        acidente_but.layer.borderColor = UIColor(red:0.00, green:0.51, blue:0.69, alpha:1.0).cgColor
        acidente_but.layer.borderWidth = 1
        
        eventos_but.layer.cornerRadius = 5
        eventos_but.layer.borderColor = UIColor(red:0.00, green:0.51, blue:0.69, alpha:1.0).cgColor
        eventos_but.layer.borderWidth = 1
        
        desli_but.layer.cornerRadius = 5
        desli_but.layer.borderColor = UIColor(red:0.00, green:0.51, blue:0.69, alpha:1.0).cgColor
        desli_but.layer.borderWidth = 1
        
        obs_but.layer.cornerRadius = 5
        obs_but.layer.borderColor = UIColor(red:0.00, green:0.51, blue:0.69, alpha:1.0).cgColor
        obs_but.layer.borderWidth = 1
        
        self.locationManager.requestAlwaysAuthorization()
        
        // For use in foreground
        // You will need to update your .plist file to request the authorization
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
        
        device_uuid = UIDevice.current.identifierForVendor!.uuidString
        
        // Do any additional setup after loading the view.
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        // set the value of lat and long
        latitude = location.latitude
        longitude = location.longitude
        
    }
    
    
    @IBAction func evenbut(_ sender: UIButton) {
        
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        let result = formatter.string(from: date)
        
        
        let json: [String: Any] = ["idtelefone": Messaging.messaging().fcmToken!, "lat": latitude,"lon":longitude,"data":result,"ocorrencia":"Evento"]
        
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        
        // create post request
        let url = URL(string: "http://aplicativo.cocr.com.br:8015/inserir_ocorrencia")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // insert json data to the request
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                return
            }
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            if let responseJSON = responseJSON as? [String: Any] {
                print(responseJSON)
            }
        }
        
        task.resume()
        
        
        let alert = UIAlertController(title: "Reportar", message: "Informação enviada com sucesso.\nObrigado pela sua contribuição.\nEncaminharemos aos órgãos responsáveis", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func acidenbut(_ sender: UIButton) {
        
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        let result = formatter.string(from: date)
        
        
        let json: [String: Any] = ["idtelefone": Messaging.messaging().fcmToken!, "lat": latitude,"lon":longitude,"data":result,"ocorrencia":"Acidente"]
        
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        
        // create post request
        let url = URL(string: "http://aplicativo.cocr.com.br/inserir_ocorrencia")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // insert json data to the request
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                return
            }
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            if let responseJSON = responseJSON as? [String: Any] {
                print(responseJSON)
            }
        }
        
        task.resume()
        
        
        let alert = UIAlertController(title: "Reportar", message: "Informação enviada com sucesso.\nObrigado pela sua contribuição.\nEncaminharemos aos órgãos responsáveis", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func quedabut(_ sender: UIButton) {
        
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        let result = formatter.string(from: date)
        
        
        let json: [String: Any] = ["idtelefone": Messaging.messaging().fcmToken!, "lat": latitude,"lon":longitude,"data":result,"ocorrencia":"Queda de Árvore"]
        
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        
        // create post request
        let url = URL(string: "http://aplicativo.cocr.com.br/inserir_ocorrencia")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // insert json data to the request
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                return
            }
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            if let responseJSON = responseJSON as? [String: Any] {
                print(responseJSON)
            }
        }
        
        task.resume()
        
        
        let alert = UIAlertController(title: "Reportar", message: "Informação enviada com sucesso.\nObrigado pela sua contribuição.\nEncaminharemos aos órgãos responsáveis", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func alabut(_ sender: UIButton) {
        
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        let result = formatter.string(from: date)
        
        
        let json: [String: Any] = ["idtelefone": Messaging.messaging().fcmToken!, "lat": latitude,"lon":longitude,"data":result,"ocorrencia":"Alagamento"]
        
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        
        // create post request
        let url = URL(string: "http://aplicativo.cocr.com.br/inserir_ocorrencia")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // insert json data to the request
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                return
            }
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            if let responseJSON = responseJSON as? [String: Any] {
                print(responseJSON)
            }
        }
        
        task.resume()
        
        
        let alert = UIAlertController(title: "Reportar", message: "Informação enviada com sucesso.\nObrigado pela sua contribuição.\nEncaminharemos aos órgãos responsáveis", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func deslibut(_ sender: UIButton) {
        
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        let result = formatter.string(from: date)
        
        
        let json: [String: Any] = ["idtelefone": Messaging.messaging().fcmToken!, "lat": latitude,"lon":longitude,"data":result,"ocorrencia":"Deslizamento"]
        
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        
        // create post request
        let url = URL(string: "http://aplicativo.cocr.com.br/inserir_ocorrencia")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // insert json data to the request
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                return
            }
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            if let responseJSON = responseJSON as? [String: Any] {
                print(responseJSON)
            }
        }
        
        task.resume()
        
        
        let alert = UIAlertController(title: "Reportar", message: "Informação enviada com sucesso.\nObrigado pela sua contribuição.\nEncaminharemos aos órgãos responsáveis", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func transbut(_ sender: UIButton) {
        
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        let result = formatter.string(from: date)
        
        
        let json: [String: Any] = ["idtelefone": Messaging.messaging().fcmToken!, "lat": latitude,"lon":longitude,"data":result,"ocorrencia":"Fogo em Vegetação"]
        
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        
        // create post request
        let url = URL(string: "http://aplicativo.cocr.com.br/inserir_ocorrencia")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // insert json data to the request
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                return
            }
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            if let responseJSON = responseJSON as? [String: Any] {
                print(responseJSON)
            }
        }
        
        task.resume()
        
        
        let alert = UIAlertController(title: "Reportar", message: "Informação enviada com sucesso.\nObrigado pela sua contribuição.\nEncaminharemos aos órgãos responsáveis", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
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
