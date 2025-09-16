//
//  TransitoAtualViewController.swift
//  Comando
//
//  Created by Candido Bugarin on 25/01/19.
//  Copyright © 2019 Candido Bugarin. All rights reserved.
//

import UIKit

class TransitoAtualViewController: UIViewController,UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var cameras: UIButton!
    @IBOutlet weak var quilometro: UILabel!
    @IBOutlet weak var interdi: UIButton!
    
    @IBOutlet weak var titulo: UILabel!
    @IBOutlet weak var grafico: UIButton!
    @IBOutlet weak var viewcollect: UIView!
    
    var lingua = ""

    
    var fav2: Array<TTT> = []
    var fav: Array<KM> = []
    var fav3: Array<Modal> = []
    
    
    @IBOutlet weak var meteoro: UIView!
    
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
        
        grafico.layer.cornerRadius = 5

        collectionView2.dataSource = self
        collectionView2.delegate = self
        
        
        collectionView2.register(UINib.init(nibName: "AlertasCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "AlertasCollectionViewCell")
    
        if let flowLayout = collectionView2.collectionViewLayout as? UICollectionViewFlowLayout {flowLayout.estimatedItemSize = CGSize(width: 1,height: 1)}
        
        cameras.layer.cornerRadius = 5
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
            title = "Mobilidade Urbana"
           
        } else if lingua.contains("es") {
            title = "Transporte"
            self.titulo.text = "Actualizaciones de tráfico"
            self.cameras.setTitle("Cámaras de la ciudad", for: UIControl.State.normal)
            self.interdi.setTitle("BRT y VLT", for: UIControl.State.normal)
            self.grafico.setTitle("Transporte interurbano", for: UIControl.State.normal)

        } else {
            title = "City Mobility"
            self.titulo.text = "Traffic updates"
            self.cameras.setTitle("Street cameras", for: UIControl.State.normal)
            self.interdi.setTitle("BRT and VLT", for: UIControl.State.normal)
            self.grafico.setTitle("Intercity transport", for: UIControl.State.normal)

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
                    self.fav2 = ColetaDados_TTT.getdata()
                   
                } else if self.lingua.contains("es") {
                    self.fav2 = ColetaDados_TTT_ES.getdata()
                } else {
                    self.fav2 = ColetaDados_TTT_EN.getdata()
                }
                
                
                self.fav = ColetaDados_KM.getdata()
                               
                
                if self.lingua.contains("pt") {
                    if self.fav[0].tt == ("normal para o horário") {
                        self.meteoro.applyGradient(colours: [UIColor(red: 0.25, green: 0.44, blue: 0.29, alpha: 1.00), UIColor(red: 0.25, green: 0.60, blue: 0.32, alpha: 1.00)], radius: 12, sentido: "Vertical")

                            
                    } else if self.fav[0].tt == ("acima do normal para o horário") {
                        self.meteoro.applyGradient(colours: [UIColor(red: 0.88, green: 0.58, blue: 0.00, alpha: 1.00),UIColor(red: 1.00, green: 0.69, blue: 0.07, alpha: 1.00)], radius: 12, sentido: "Vertical")

                    } else if self.fav[0].tt == ("muito acima do normal para o horário") {
                        self.meteoro.applyGradient(colours: [UIColor(red: 0.66, green: 0.07, blue: 0.19, alpha: 1.00),UIColor(red: 0.87, green: 0.13, blue: 0.13, alpha: 1.00)], radius: 12, sentido: "Vertical")

                    }

                    self.quilometro.text = "Trânsito "+(self.fav[0].tt)
                   
                } else if self.lingua.contains("es") {
                    if self.fav[0].tt == ("normal para o horário") {
                        self.meteoro.applyGradient(colours: [UIColor(red: 0.25, green: 0.44, blue: 0.29, alpha: 1.00), UIColor(red: 0.25, green: 0.60, blue: 0.32, alpha: 1.00)], radius: 12, sentido: "Vertical")
                        self.quilometro.text = "Tráfico normal"

                            
                    } else if self.fav[0].tt == ("acima do normal para o horário") {
                        self.meteoro.applyGradient(colours: [UIColor(red: 0.88, green: 0.58, blue: 0.00, alpha: 1.00),UIColor(red: 1.00, green: 0.69, blue: 0.07, alpha: 1.00)], radius: 12, sentido: "Vertical")
                        self.quilometro.text = "tráfico por encima del normal"

                    } else if self.fav[0].tt == ("muito acima do normal para o horário") {
                        self.meteoro.applyGradient(colours: [UIColor(red: 0.66, green: 0.07, blue: 0.19, alpha: 1.00),UIColor(red: 0.87, green: 0.13, blue: 0.13, alpha: 1.00)], radius: 12, sentido: "Vertical")
                        self.quilometro.text = "tráfico mucho más alto de lo normal"

                    }

                    
                } else {
                    if self.fav[0].tt == ("normal para o horário") {
                        self.meteoro.applyGradient(colours: [UIColor(red: 0.25, green: 0.44, blue: 0.29, alpha: 1.00), UIColor(red: 0.25, green: 0.60, blue: 0.32, alpha: 1.00)], radius: 12, sentido: "Vertical")
                        self.quilometro.text = "Usual traffic for time"

                            
                    } else if self.fav[0].tt == ("acima do normal para o horário") {
                        self.meteoro.applyGradient(colours: [UIColor(red: 0.88, green: 0.58, blue: 0.00, alpha: 1.00),UIColor(red: 1.00, green: 0.69, blue: 0.07, alpha: 1.00)], radius: 12, sentido: "Vertical")
                        self.quilometro.text = "traffic higher than normal"

                    } else if self.fav[0].tt == ("muito acima do normal para o horário") {
                        self.meteoro.applyGradient(colours: [UIColor(red: 0.66, green: 0.07, blue: 0.19, alpha: 1.00),UIColor(red: 0.87, green: 0.13, blue: 0.13, alpha: 1.00)], radius: 12, sentido: "Vertical")
                        self.quilometro.text = "traffic much higher than normal"

                    }

                }
                
                
                self.cameras.applyGradient(colours: [UIColor(red: 0.22, green: 0.51, blue: 0.75, alpha: 1.00), UIColor(red: 0.31, green: 0.62, blue: 0.87, alpha: 1.00)], radius: 6, sentido: "Horizontal")
                self.interdi.applyGradient(colours: [UIColor(red: 0.22, green: 0.51, blue: 0.75, alpha: 1.00), UIColor(red: 0.31, green: 0.62, blue: 0.87, alpha: 1.00)], radius: 6, sentido: "Horizontal")
                self.grafico.applyGradient(colours: [UIColor(red: 0.22, green: 0.51, blue: 0.75, alpha: 1.00), UIColor(red: 0.31, green: 0.62, blue: 0.87, alpha: 1.00)], radius: 6, sentido: "Horizontal")

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

extension UIView {
    // Remove qualquer gradiente existente
    func removeExistingGradients() {
        self.layer.sublayers?.forEach { layer in
            if layer is CAGradientLayer {
                layer.removeFromSuperlayer()
            }
        }
    }

    // Função simplificada com valores padrão
    func applyGradient(colours: [UIColor], radius: CGFloat, sentido: String) -> CAGradientLayer {
        return self.applyGradient(colours: colours, radius: radius, sentido: sentido, locations: nil)
    }

    // Função principal com limpeza de gradientes existentes
    func applyGradient(colours: [UIColor], radius: CGFloat, sentido: String, locations: [NSNumber]?) -> CAGradientLayer {
        // Remover gradientes existentes para evitar sobreposições
        removeExistingGradients()
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.name = "gradientLayer" // Adicionar nome para fácil identificação
        
        // Configurar frame para cobrir toda a view
        gradientLayer.frame = self.bounds
        
        // Configurar cores
        gradientLayer.colors = colours.map { $0.cgColor }
        
        // Configurar direção do gradiente corretamente
        if sentido == "Vertical" {
            // Para gradiente horizontal, da esquerda para direita
            gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
            gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        } else if sentido == "Horizontal" {
            // Para gradiente vertical, de cima para baixo
            gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
            gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        }
        
        // Configurar arredondamento e localização
        gradientLayer.cornerRadius = radius
        gradientLayer.locations = locations
        
        // Adicionar à camada mais baixa
        self.layer.insertSublayer(gradientLayer, at: 0)
        
        return gradientLayer
    }
}


