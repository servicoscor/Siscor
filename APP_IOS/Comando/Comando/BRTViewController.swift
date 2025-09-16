//
//  BRTViewController.swift
//  Comando
//
//  Created by Candido Bugarin on 03/05/21.
//  Copyright © 2021 Candido Bugarin. All rights reserved.
//

import UIKit
import CoreLocation
import SwiftOverlays
import MapKit
import Firebase
import FirebaseInstanceID
import FirebaseMessaging

class BRTViewController: UIViewController,UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var titulo: UILabel!
    
    @IBOutlet weak var viewcollect: UIView!
    
    
    var fav2: Array<TTT> = []
    var fav: Array<KM> = []
    var fav3: Array<Modal> = []
    
    var lingua = ""
    
    @IBOutlet weak var collectionView2: UICollectionView!

    
    let dispatchQueue = DispatchQueue(label: "Dispatch Queue", attributes: [], target: nil)
    var activityIndicatorAlert: UIAlertController?

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
        

        collectionView2.dataSource = self
        collectionView2.delegate = self
        
        
        collectionView2.register(UINib.init(nibName: "AlertasCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "AlertasCollectionViewCell")
    
        if let flowLayout = collectionView2.collectionViewLayout as? UICollectionViewFlowLayout {flowLayout.estimatedItemSize = CGSize(width: 1,height: 1)}
        
        // Do any additional setup after loading the view.
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.fav2.count
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AlertasCollectionViewCell", for: indexPath) as! AlertasCollectionViewCell
        cell.texto.text = self.fav2[indexPath.row].tt.replacingOccurrences(of: "pulalinha", with: "\n").replacingOccurrences(of: "pontovirgula", with: ";").replacingOccurrences(of: "jumpline", with: "\n")
        
        return cell
        
    }
    
    @IBAction func cameras2_act(_ sender: UIButton) {
        let vc = CamerasViewController(nibName:"CamerasViewController", bundle:nil)
        self.navigationController!.pushViewController(vc, animated: true)
    }
    

    @IBAction func interdicoes_act(_ sender: UIButton) {
        let vc = BRTViewController(nibName:"BRTViewController", bundle:nil)
        self.navigationController!.pushViewController(vc, animated: true)
    }
    
    @IBAction func cameras_act(_ sender: UIButton) {
        let vc = MobilidadeViewController(nibName:"MobilidadeViewController", bundle:nil)
        self.navigationController!.pushViewController(vc, animated: true)
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
            title = "BRT e VLT"
           
        } else if lingua.contains("es") {
            title = "BRT y VLT"
            self.titulo.text = "BRT y VLT"
        } else {
            title = "BRT and VLT"
            self.titulo.text = "BRT and VLT"
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
                
                if self.lingua.contains("pt") {
                    self.fav2 = ColetaDados_TTV.getdata()
                   
                } else if self.lingua.contains("es") {
                    self.fav2 = ColetaDados_TTV_ES.getdata()
                } else {
                    self.fav2 = ColetaDados_TTV_EN.getdata()
                }
                
                
                
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


