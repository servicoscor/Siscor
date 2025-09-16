//
//  MobilidadeViewController.swift
//  Comando
//
//  Created by Candido Bugarin on 17/07/19.
//  Copyright © 2019 Candido Bugarin. All rights reserved.
//

import UIKit

class MobilidadeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource,UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    

    @IBOutlet weak var viewcollect: UIView!
    
    @IBOutlet weak var brt: UILabel!
    @IBOutlet weak var vlt: UILabel!
    @IBOutlet weak var metro: UILabel!
    @IBOutlet weak var trem: UILabel!
    @IBOutlet weak var barcas: UILabel!
    @IBOutlet weak var aero: UILabel!
    
    @IBOutlet weak var titulo: UILabel!
    var fav2: Array<TTT> = []
    var fav3: Array<Modal> = []
    
    var activityIndicatorAlert: UIAlertController?

    @IBOutlet weak var table: UITableView!
    
    var lingua = ""

    let dispatchQueue = DispatchQueue(label: "Dispatch Queue", attributes: [], target: nil)
    
    @IBOutlet weak var collectionView2: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
       
        
        
        viewcollect.layer.cornerRadius = 5
        
        let xib = UINib(nibName: "NoTableViewCell", bundle: nil)
        self.table.register(xib,forCellReuseIdentifier:"cell")
        self.table.dataSource = self
        self.table.delegate = self
        self.table.backgroundColor = UIColor.clear

        // Do any additional setup after loading the view.
        
        
       
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
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.fav3.count
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.table.dequeueReusableCell(withIdentifier: "cell")! as! NoTableViewCell
        cell.tema.text = self.fav3[indexPath.row].nome
        
        if lingua.contains("pt") {
            cell.titulo.text = "Acesse o site"
        } else if lingua.contains("es") {
            cell.titulo.text = "Accede al sitio web"
        } else {
            cell.titulo.text = "Access the website"
        }
        
         
        
       
            cell.linha.applyGradient(colours: [UIColor(red: 0.07, green: 0.45, blue: 0.87, alpha: 1.00),UIColor(red: 0.07, green: 0.45, blue: 0.87, alpha: 1.00)], radius: 6, sentido: "Vertical")
            
        
        
        if self.fav3[indexPath.row].nome.contains("Metro") {
                   cell.imagem.image = UIImage(named: "metro.png")
               } else if self.fav3[indexPath.row].nome.contains("Trem") {
                   cell.imagem.image = UIImage(named: "trem.png")
               } else if self.fav3[indexPath.row].nome.contains("Aeroporto") {
                   cell.imagem.image = UIImage(named: "aeroporto.png")
               } else if self.fav3[indexPath.row].nome.contains("Barcas") {
                   cell.imagem.image = UIImage(named: "barcas.png")
               } else if self.fav3[indexPath.row].nome.contains("BRT") {
                   cell.imagem.image = UIImage(named: "brt.png")
               } else if self.fav3[indexPath.row].nome.contains("VLT") {
                   cell.imagem.image = UIImage(named: "vlt.png")
               }
        
        return cell
    }
    
    func tableView(_ didSelectRowAttableView:UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if lingua.contains("pt") {
            if self.fav3[indexPath.row].nome.contains("Metro") == true {
                let url = URL(string: "https://www.metrorio.com.br")!
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    //If you want handle the completion block than
                    UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
                         print("Open url : \(success)")
                    })
                }
            } else if self.fav3[indexPath.row].nome.contains("Trem") == true {
                let url = URL(string: "https://www.supervia.com.br")!
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    //If you want handle the completion block than
                    UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
                         print("Open url : \(success)")
                    })
                }
            } else if self.fav3[indexPath.row].nome.contains("Barcas") == true {
                let url = URL(string: "https://barcas.grupoccr.com.br")!
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    //If you want handle the completion block than
                    UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
                         print("Open url : \(success)")
                    })
                }
            } else if self.fav3[indexPath.row].nome.contains("Aeroporto do Galeão") == true {
                let url = URL(string: "https://www.riogaleao.com/passageiros")!
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    //If you want handle the completion block than
                    UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
                         print("Open url : \(success)")
                    })
                }
            } else if self.fav3[indexPath.row].nome.contains("Aeroporto Santos Dumont") == true {
                let url = URL(string: "https://www4.infraero.gov.br")!
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    //If you want handle the completion block than
                    UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
                         print("Open url : \(success)")
                    })
                }
            }
        } else if lingua.contains("es") {
            if self.fav3[indexPath.row].nome.contains("Metro") == true {
                let url = URL(string: "https://www.metrorio.com.br")!
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    //If you want handle the completion block than
                    UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
                         print("Open url : \(success)")
                    })
                }
            } else if self.fav3[indexPath.row].nome.contains("Trem") == true {
                let url = URL(string: "https://www.supervia.com.br")!
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    //If you want handle the completion block than
                    UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
                         print("Open url : \(success)")
                    })
                }
            } else if self.fav3[indexPath.row].nome.contains("Barcas") == true {
                let url = URL(string: "https://barcas.grupoccr.com.br")!
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    //If you want handle the completion block than
                    UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
                         print("Open url : \(success)")
                    })
                }
            } else if self.fav3[indexPath.row].nome.contains("Aeroporto do Galeão") == true {
                let url = URL(string: "https://www.riogaleao.com/passageiros")!
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    //If you want handle the completion block than
                    UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
                         print("Open url : \(success)")
                    })
                }
            } else if self.fav3[indexPath.row].nome.contains("Aeroporto Santos Dumont") == true {
                let url = URL(string: "https://www4.infraero.gov.br")!
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    //If you want handle the completion block than
                    UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
                         print("Open url : \(success)")
                    })
                }
            }
        } else {
            if self.fav3[indexPath.row].nome.contains("Metro") == true {
                let url = URL(string: "https://www.metrorio.com.br")!
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    //If you want handle the completion block than
                    UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
                         print("Open url : \(success)")
                    })
                }
            } else if self.fav3[indexPath.row].nome.contains("Trem") == true {
                let url = URL(string: "https://www.supervia.com.br")!
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    //If you want handle the completion block than
                    UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
                         print("Open url : \(success)")
                    })
                }
            } else if self.fav3[indexPath.row].nome.contains("Barcas") == true {
                let url = URL(string: "https://barcas.grupoccr.com.br")!
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    //If you want handle the completion block than
                    UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
                         print("Open url : \(success)")
                    })
                }
            } else if self.fav3[indexPath.row].nome.contains("Aeroporto do Galeão") == true {
                let url = URL(string: "https://www.riogaleao.com/passageiros")!
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    //If you want handle the completion block than
                    UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
                         print("Open url : \(success)")
                    })
                }
            } else if self.fav3[indexPath.row].nome.contains("Aeroporto Santos Dumont") == true {
                let url = URL(string: "https://www4.infraero.gov.br")!
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    //If you want handle the completion block than
                    UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
                         print("Open url : \(success)")
                    })
                }
            }
        }
        
       

            
        table.deselectRow(at: indexPath, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.fav3.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.collectionView2.frame.width-16, height: 350)
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AlertasCollectionViewCell", for: indexPath) as! AlertasCollectionViewCell
        
        if self.fav3[indexPath.row].status.contains("Normal") {
            cell.titulo.layer.backgroundColor = UIColor(red:0.16, green:0.65, blue:0.27, alpha:1.0).cgColor
        } else if self.fav3[indexPath.row].status.contains("Em atenção") {
            cell.titulo.layer.backgroundColor = UIColor(red:1.00, green:0.76, blue:0.03, alpha:1.0).cgColor
        } else if self.fav3[indexPath.row].status.contains("Fechado") {
            cell.titulo.layer.backgroundColor = UIColor(red:0.86, green:0.21, blue:0.27, alpha:1.0).cgColor
            
        }
        cell.titulo.text = " "+self.fav3[indexPath.row].nome + " - "+self.fav3[indexPath.row].status
        cell.titulo.textColor = UIColor.white
        cell.titulo.layer.cornerRadius = 5
        
        cell.texto.text = self.fav3[indexPath.row].mensagem
        
        return cell
        
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
            title = "Modais intermunicipais"
            self.titulo.text = "Modais intermunicipais"
        } else if lingua.contains("es") {
            title = "Transporte interurbano"
            self.titulo.text = "Transporte interurbano"
        } else {
            title = "Intercity transport"
            self.titulo.text = "Intercity transport"
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
                
                self.fav3 = ColetaDados_Modal.getdata()
                
                if self.lingua.contains("pt") {
                    self.fav3 = ColetaDados_Modal.getdata()
                } else if self.lingua.contains("es") {
                    self.fav3 = ColetaDados_Modal_ES.getdata()
                } else {
                    self.fav3 = ColetaDados_Modal_EN.getdata()
                }
                            
                
                self.table.reloadData()
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
