//
//  ListaBlocosViewController.swift
//  Comando
//
//  Created by Candido Bugarin on 10/01/24.
//  Copyright © 2024 Candido Bugarin. All rights reserved.
//


import UIKit
import MapKit
import WeatherKit
//import EventKit

class ListaBlocosViewController: UIViewController,UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var titulo: UILabel!
    
    var lingua = ""
    
    @IBOutlet weak var collectionView2: UICollectionView!

    
    var fav2: Array<EventosCarnaval> = []
    
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
        
            let alertController = UIAlertController(title: self.fav2[indexPath!.row].nome, message: "Endereço: "+self.fav2[indexPath!.row].end+"\nInício: "+self.fav2[indexPath!.row].data_i+"\nFim: "+self.fav2[indexPath!.row].data_f+"\n\nFonte: RioTur", preferredStyle:.alert)

            alertController.addAction(UIAlertAction(title: "OK", style: .default)
                      { action -> Void in
                        // Put your code here
                      })
        
            alertController.addAction(UIAlertAction(title: "Salvar na agenda", style: .default)
                                      { [self] action -> Void in
                
                print(self.fav2[indexPath!.row].data_i,self.fav2[indexPath!.row].data_f)
                
                let expiryDate = self.fav2[indexPath!.row].data_i_c
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "dd-MM-yyyy HH:mm"
                print(dateFormatter.date(from: expiryDate))
                
                //addEventToCalendar(title: self.fav2[indexPath!.row].nome, description: "Endereço: "+self.fav2[indexPath!.row].end, startDate: dateFor(timeStamp: self.fav2[indexPath!.row].data_i_c) as Date, endDate: dateFor(timeStamp: self.fav2[indexPath!.row].data_f_c) as Date)

                      })
            
            alertController.addAction(UIAlertAction(title: "Compartilhar", style: .default)
                      { action -> Void in
                
                let message = "Eiiii! Vamos no "+self.fav2[indexPath!.row].nome+"? Começa às "+self.fav2[indexPath!.row].data_i+" e vai ser na "+self.fav2[indexPath!.row].end+".\n\nE se quiser saber tudo sobre o Carnaval e a cidade, baixa o app COR.Rio!\n\niOS:https://bit.ly/appcor_ios \nAndroid:https://bit.ly/appcor_android"
                
                       var queryCharSet = NSCharacterSet.urlQueryAllowed
                       
                       // if your text message contains special characters like **+ and &** then add this line
                       queryCharSet.remove(charactersIn: "+&")
                       
                       if let escapedString = message.addingPercentEncoding(withAllowedCharacters: queryCharSet) {
                           if let whatsappURL = URL(string: "https://wa.me/send?text=\(escapedString)") {
                               if UIApplication.shared.canOpenURL(whatsappURL) {
                                   UIApplication.shared.open(whatsappURL, options: [: ], completionHandler: nil)
                               } else {
                                   debugPrint("please install WhatsApp")
                               }
                           }
                       }
                
                
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
            cell.texto.text = "🎊 🎉 "+self.fav2[indexPath.row].nome+"\nEndereço: "+self.fav2[indexPath.row].end+"\nInício: "+self.fav2[indexPath.row].data_i+"\nFim: "+self.fav2[indexPath.row].data_f+"\n\nFonte: RioTur"
        } else if lingua.contains("es") {
            cell.texto.text = "🎊 🎉 "+self.fav2[indexPath.row].nome+"\nDIRECCIÓN: "+self.fav2[indexPath.row].end+"\nComenzar: "+self.fav2[indexPath.row].data_i+"\nFin: "+self.fav2[indexPath.row].data_f+"\n\nOrigen: RioTur"
        } else {
            cell.texto.text = "🎊 🎉 "+self.fav2[indexPath.row].nome+"\nAddress: "+self.fav2[indexPath.row].end+"\nStart: "+self.fav2[indexPath.row].data_i+"\nEnd: "+self.fav2[indexPath.row].data_f+"\n\nSource: RioTur"
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
            title = "Lista de eventos"
           
        } else if lingua.contains("es") {
            title = "Lista de eventos"
            self.titulo.text = "Lista de eventos"
        } else {
            title = "Event list"
            self.titulo.text = "Event list"
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
                
                
                self.fav2 = ColetaDados_Carnaval_Todos.getdata()
                

                self.collectionView2.reloadData()
                self.removeAllOverlays()
                }
            
            }
       
    }
    
    //func addEventToCalendar(title: String, description: String?, startDate: Date, endDate: Date, completion: ((_ success: Bool, _ error: NSError?) -> Void)? = nil) {
    //   let eventStore = EKEventStore()
    //    print(startDate,endDate)
    //    eventStore.requestAccess(to: .event, completion: { (granted, error) in
    //       if (granted) && (error == nil) {
    //            let event = EKEvent(eventStore: eventStore)
    //           event.title = title
    //          event.startDate = startDate
    //          event.endDate = endDate
    //          event.notes = description
    //           event.calendar = eventStore.defaultCalendarForNewEvents
    //          do {
                    //              try eventStore.save(event, span: .thisEvent)
    //           } catch let e as NSError {
    //               completion?(false, e)
    //               return
    //           }
    //           completion?(true, nil)
    //       } else {
    //          completion?(false, error as NSError?)
    //      }
    //   })
    //}


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}




