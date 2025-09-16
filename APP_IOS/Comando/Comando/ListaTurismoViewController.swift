//
//  ListaTurismoViewController.swift
//  Comando
//
//  Created by Candido Bugarin on 26/01/24.
//  Copyright © 2024 Candido Bugarin. All rights reserved.
//

import UIKit

import UIKit
import MapKit
import WeatherKit
//import EventKit

class ListaTurismoViewController: UIViewController,UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var titulo: UILabel!
    
    var lingua = ""
    
    @IBOutlet weak var collectionView2: UICollectionView!

    
    var fav2: Array<PontosTur> = []
    
    let dispatchQueue = DispatchQueue(label: "Dispatch Queue", attributes: [], target: nil)
    let locManager = CLLocationManager()
    
    
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
        
        
        collectionView2.delegate = self
        
        collectionView2.register(UINib.init(nibName: "AlertasCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "AlertasCollectionViewCell")
        
        if let flowLayout = collectionView2.collectionViewLayout as? UICollectionViewFlowLayout {flowLayout.estimatedItemSize = CGSize(width: 1,height: 1)}
        
        collectionView2.dataSource = self

        
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



        // Do any additional setup after loading the view.
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.fav2.count
    }
    
    @objc func tap(_ sender: UITapGestureRecognizer) {

     let location = sender.location(in: self.collectionView2)
        let indexPath = self.collectionView2.indexPathForItem(at: location)
        
        if let index = indexPath {
            
            var mensagem_popup = ""
            
            if lingua.contains("pt") {
                mensagem_popup = "Endereço: "+self.fav2[indexPath!.row].end
            
            } else if lingua.contains("es") {
                
                mensagem_popup = "DIRECCIÓN: "+self.fav2[indexPath!.row].end

            } else {
                
                mensagem_popup = "Address: "+self.fav2[indexPath!.row].end
            }
            
            let alertController = UIAlertController(title: self.fav2[indexPath!.row].nome, message: mensagem_popup, preferredStyle:.alert)
        
           

            alertController.addAction(UIAlertAction(title: "OK", style: .default)
                      { action -> Void in
                        // Put your code here
                      })
        
            alertController.addAction(UIAlertAction(title: "Ver mais", style: .default)
                      { action -> Void in
                let vc = PerfilPontoViewController(nibName:"PerfilPontoViewController", bundle:nil)
                vc.titulo = self.fav2[indexPath!.row].nome
                vc.texto = "Endereço: "+self.fav2[indexPath!.row].end+"\nDescrição: "+self.fav2[indexPath!.row].texto
                self.navigationController!.pushViewController(vc, animated: true)
                      })
            
            
           
            self.present(alertController, animated: true, completion: nil)
            
         
        
        }
    }
    
    func dateFor(timeStamp: String) -> NSDate
    {
        let formater = DateFormatter()
        formater.dateFormat = "dd-MM-yyyy HH:mm"
        return formater.date(from: timeStamp)! as NSDate
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AlertasCollectionViewCell", for: indexPath) as! AlertasCollectionViewCell
        
        if lingua.contains("pt") {
            cell.texto.text = "🏛️ "+self.fav2[indexPath.row].nome+"\n\nEndereço: "+self.fav2[indexPath.row].end
        } else if lingua.contains("es") {
            cell.texto.text = "🏛️ "+self.fav2[indexPath.row].nome+"\n\nDIRECCIÓN: "+self.fav2[indexPath.row].end
        } else {
            cell.texto.text = "🏛️ "+self.fav2[indexPath.row].nome+"\n\nAddress: "+self.fav2[indexPath.row].end
        }
        
   
        cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tap(_:))))
        
        return cell
        
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
            title = "Lista de pontos turisticos"
           
        } else if lingua.contains("es") {
            title = "Lista de puntos"
            self.titulo.text = "Lista de puntos turisticos"
        } else {
            title = "List of attractions"
            self.titulo.text = "List of attractions"
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
                
                
                self.fav2 = ColetaDados_Turismo.getdata()
                

                self.collectionView2.reloadData()
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
