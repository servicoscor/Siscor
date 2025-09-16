//
//  TempoViewController.swift
//  Comando
//
//  Created by Candido Bugarin on 03/12/18.
//  Copyright © 2018 Candido Bugarin. All rights reserved.
//

import UIKit
import MapKit
import WeatherKit

class TempoViewController: UIViewController,UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    

    @IBOutlet weak var hidratacao: UIButton!
    @IBOutlet weak var condicao: UIImageView!
    @IBOutlet weak var meteoro: UIView!
    @IBOutlet weak var pluvio: UIButton!
    @IBOutlet weak var mapa: UIButton!
    @IBOutlet weak var radar: UIButton!
    
    @IBOutlet weak var viewcollect: UIView!
    
    @IBOutlet weak var collectionView2: UICollectionView!

    @IBOutlet weak var vento: UILabel!
    @IBOutlet weak var chuva: UILabel!
    @IBOutlet weak var temp: UILabel!
    
    @IBOutlet weak var titulo: UILabel!
    
    var lingua = ""
    
    let dispatchQueue = DispatchQueue(label: "Dispatch Queue", attributes: [], target: nil)
    let locManager = CLLocationManager()
    
    var fav: Array<EstacaoMete> = []
    var fav2: Array<Avisos> = []
    var fav3: Array<Prev> = []
    var fav4: Array<AlertaN> = []
    var fav5: Array<UV> = []
    var fav6: Array<Estacao> = []
    var fav7: Array<TTA> = []
    var fav8: Array<EstacaoMeteCeu> = []
    var fav11: Array<Tempo> = []
    
    var list_dis:[Double] = []
    var list_dis_chuva:[Double] = []
    var uv_fact = ""
    
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
        return self.fav7.count
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AlertasCollectionViewCell", for: indexPath) as! AlertasCollectionViewCell
        cell.texto.text = self.fav7[indexPath.row].tt.replacingOccurrences(of: "pulalinha", with: "\n").replacingOccurrences(of: "pontovirgula", with: ";").replacingOccurrences(of: "jumpline", with: "\n")
        
        return cell
        
    }
    
    @IBAction func hidra_open(_ sender: UIButton) {
        let vc = HidratacaoNViewController(nibName:"HidratacaoNViewController", bundle:nil)
        self.navigationController!.pushViewController(vc, animated: true)
    }
    

    @IBAction func mapa_open(_ sender: UIButton) {
        let vc = MapaTemperaturaViewController(nibName:"MapaTemperaturaViewController", bundle:nil)
        self.navigationController!.pushViewController(vc, animated: true)
    }
    
    @IBAction func pluvio_open(_ sender: UIButton) {
        let vc = MapaViewController(nibName:"MapaViewController", bundle:nil)
        self.navigationController!.pushViewController(vc, animated: true)
    }
    
    @IBAction func radar_open(_ sender: UIButton) {
        let vc = RadarViewController(nibName:"RadarViewController", bundle:nil)
        self.navigationController!.pushViewController(vc, animated: true)
    }
    
    
    func actualTime(sunrise: Date, sunset: Date) -> Bool {
        var status = true
        let date = Date()
        let previousMidnight = Calendar.current.startOfDay(for: date)
        if date >= previousMidnight && date < sunrise ||
            date > sunset {
            status = true
        }
        else {
            status = false
        }
        return status
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
            title = "Tempo"
           
        } else if lingua.contains("es") {
            title = "Clima"
            self.titulo.text = "Actualizaciones meteorológicas"
            self.radar.setTitle("Radar", for: UIControl.State.normal)
            self.mapa.setTitle("Meteorología", for: UIControl.State.normal)
            self.pluvio.setTitle("Pluviómetros", for: UIControl.State.normal)
            self.hidratacao.setTitle("Puntos de hidratación", for: UIControl.State.normal)

        } else {
            title = "Weather"
            self.titulo.text = "Weather updates"
            self.radar.setTitle("Radar", for: UIControl.State.normal)
            self.mapa.setTitle("Weather station", for: UIControl.State.normal)
            self.pluvio.setTitle("Pluviometer", for: UIControl.State.normal)
            self.hidratacao.setTitle("Hydration points", for: UIControl.State.normal)

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
                
                self.list_dis.removeAll()
                
                if self.lingua.contains("pt") {
                    self.fav7 = ColetaDados_TTA.getdata()
                } else if self.lingua.contains("es") {
                    self.fav7 = ColetaDados_TTA_ES.getdata()
                } else {
                    self.fav7 = ColetaDados_TTA_EN.getdata()
                }
                
                
                self.fav = EstacaoMet.getEsta()
                self.fav8 = EstacaoMetCeu.getEsta()
                self.fav6 = EstacaoSer.getEsta()
                self.fav11 = Porenascer.getEsta()
                
                var tempo_r = self.actualTime(sunrise: self.fav11[0].nascer, sunset: self.fav11[0].por)
                
                var ultimo_tempo = self.fav8[0].ceu
                
                var x = 0
                var chuva_med = 0.0
                var chuv = ""
                var est = 1
                while x != self.fav6.count {
                    if self.fav6[x].situ.contains("atraso") == false {
                        print(self.fav6[x].chuva_1)
                        if Double(self.fav6[x].chuva_1) > chuva_med {
                            chuva_med = Double(self.fav6[x].chuva_1)
                        }
                        est += 1
                        }
                    x += 1
                }
                 

                var vento = ""
                var vento_max = 1.0

                x = 0
                while x != self.fav.count {
                        if Double(self.fav[x].vel_med) > vento_max {
                            vento_max = Double(self.fav[x].vel_med)
                        }
                    x += 1
                }

                 if vento_max > -1 && vento_max <= 5.1 {
                     
                     if self.lingua.contains("pt") {
                         vento = "Vento fraco"
                     } else if self.lingua.contains("es") {
                         vento = "Viento suave"
                     } else {
                         vento = "Soft wind"
                     }
                      
                  } else if vento_max > 5.1 && vento_max <= 14.4 {
                      
                      if self.lingua.contains("pt") {
                          vento = "Vento moderado"
                      } else if self.lingua.contains("es") {
                          vento = "Viento moderado"
                      } else {
                          vento = "Moderate wind"
                      }
                     
                  } else if vento_max > 14.4 && vento_max <= 21.0 {
                      
                      if self.lingua.contains("pt") {
                          vento = "Vento forte"
                      } else if self.lingua.contains("es") {
                          vento = "Viento fuerte"
                      } else {
                          vento = "Strong wind"
                      }
                    
                  } else if vento_max > 21.0 {
                      
                      if self.lingua.contains("pt") {
                          vento = "Vento muito forte"
                      } else if self.lingua.contains("es") {
                          vento = "viento muy fuerte"
                      } else {
                          vento = "Very strong wind"
                      }
                      
                  }
                                  
                var tem_max = 1.0
                var tem_min = 100.0
                
                x = 0
                while x != self.fav.count {
                    if Double(self.fav[x].tem_med) > tem_max {
                        tem_max = Double(self.fav[x].tem_med)
                    }
                               
                    x += 1
                }
                
                x = 0
                while x != self.fav.count {
                    if Double(self.fav[x].tem_med) < tem_min {
                        tem_min = Double(self.fav[x].tem_med)
                    }
                               
                    x += 1
                }
                
                print(chuva_med)
                
                let date = Date()
                let tz = TimeZone.current
            
                
                if Int(chuva_med) >= 0 && Int(chuva_med) <= 1 {
                    
                    
                    if self.lingua.contains("pt") {
                        chuv = "Sem Chuva"
                    } else if self.lingua.contains("es") {
                        chuv = "Sin lluvia"
                    } else {
                        chuv = "No rain"
                    }
                    
                    print(ultimo_tempo)
                    
                    if ultimo_tempo == "0" {
                        if tempo_r == false {
                        self.condicao.image = UIImage(named: "sol.png")
                        self.meteoro.applyGradient(colours: [UIColor(red: 0.31, green: 0.62, blue: 0.87, alpha: 1.00),UIColor(red: 0.15, green: 0.85, blue: 0.96, alpha: 1.00)], radius: 12, sentido: "Vertical")
                        } else {
                            self.condicao.image = UIImage(named: "lua.png")
                            self.meteoro.applyGradient(colours: [UIColor(red: 0.03, green: 0.15, blue: 0.25, alpha: 1.00), UIColor(red: 0.26, green: 0.40, blue: 0.52, alpha: 1.00)], radius: 12, sentido: "Vertical")
                        }
                    } else if ultimo_tempo == "1" {
                        
                        if tempo_r == false {
                            self.condicao.image = UIImage(named: "nuvem_sol.png")
                            self.meteoro.applyGradient(colours: [UIColor(red: 0.26, green: 0.40, blue: 0.52, alpha: 1.00),UIColor(red: 0.22, green: 0.51, blue: 0.75, alpha: 1.00)], radius: 12, sentido: "Vertical")
                        } else {
                            self.condicao.image = UIImage(named: "nuvem_lua.png")
                            self.meteoro.applyGradient(colours: [UIColor(red: 0.00, green: 0.00, blue: 0.00, alpha: 1.00),UIColor(red: 0.17, green: 0.36, blue: 0.52, alpha: 1.00)], radius: 12, sentido: "Vertical")
                        }
                    } else if ultimo_tempo == "2" {
                        if tempo_r == false {

                            self.condicao.image = UIImage(named: "nuvem_sol.png")
                            self.meteoro.applyGradient(colours: [UIColor(red: 0.26, green: 0.40, blue: 0.52, alpha: 1.00),UIColor(red: 0.22, green: 0.51, blue: 0.75, alpha: 1.00)], radius: 12, sentido: "Vertical")

                        } else {
                            self.condicao.image = UIImage(named: "nuvem_lua.png")
                            self.meteoro.applyGradient(colours: [UIColor(red: 0.00, green: 0.00, blue: 0.00, alpha: 1.00),UIColor(red: 0.17, green: 0.36, blue: 0.52, alpha: 1.00)], radius: 12, sentido: "Vertical")
                        }
                    } else if ultimo_tempo == "3" {
                        
                        self.condicao.image = UIImage(named: "fechado.png")
                        self.meteoro.applyGradient(colours: [UIColor(red: 0.00, green: 0.00, blue: 0.00, alpha: 1.00),UIColor(red: 0.22, green: 0.51, blue: 0.75, alpha: 1.00)], radius: 12, sentido: "Vertical")
                    }
                    
                    
                } else if Int(chuva_med) > 1 && Int(chuva_med) <= 5 {
                    
                    
                    if self.lingua.contains("pt") {
                        chuv = "Chuva Fraca"
                    } else if self.lingua.contains("es") {
                        chuv = "Llovizna"
                    } else {
                        chuv = "Light rain"
                    }
                    
                    
                    self.condicao.image = UIImage(named: "gota_chuva.png")
                    self.meteoro.applyGradient(colours: [UIColor(red: 0.00, green: 0.00, blue: 0.00, alpha: 1.00),UIColor(red: 0.22, green: 0.51, blue: 0.75, alpha: 1.00)], radius: 12, sentido: "Vertical")

                    
                } else if Int(chuva_med) > 5 && Int(chuva_med) <= 25 {
                    
                    
                    if self.lingua.contains("pt") {
                        chuv = "Chuva Moderada"
                    } else if self.lingua.contains("es") {
                        chuv = "Lluvia moderada"
                    } else {
                        chuv = "Moderate Rain"
                    }
                    
                    
                    self.condicao.image = UIImage(named: "gota_chuva.png")
                    self.meteoro.applyGradient(colours: [UIColor(red: 0.00, green: 0.00, blue: 0.00, alpha: 1.00),UIColor(red: 0.22, green: 0.51, blue: 0.75, alpha: 1.00)], radius: 12, sentido: "Vertical")

                } else if Int(chuva_med) > 25 && Int(chuva_med) <= 50 {
                    
                    
                    if self.lingua.contains("pt") {
                        chuv = "Chuva Forte"
                    } else if self.lingua.contains("es") {
                        chuv = "Lluvia fuerte"
                    } else {
                        chuv = "Heavy rain"
                    }
                    
                    self.condicao.image = UIImage(named: "gota_chuva.png")
                    self.meteoro.applyGradient(colours: [UIColor(red: 0.00, green: 0.00, blue: 0.00, alpha: 1.00),UIColor(red: 0.22, green: 0.51, blue: 0.75, alpha: 1.00)], radius: 12, sentido: "Vertical")

                } else if Int(chuva_med) > 50 {
                    
                    
                    if self.lingua.contains("pt") {
                        chuv = "Chuva Muito Forte"
                    } else if self.lingua.contains("es") {
                        chuv = "Lluvias muy intensas"
                    } else {
                        chuv = "Very Heavy Rain"
                    }
                    
                    self.condicao.image = UIImage(named: "gota_chuva.png")
                    self.meteoro.applyGradient(colours: [UIColor(red: 0.00, green: 0.00, blue: 0.00, alpha: 1.00),UIColor(red: 0.22, green: 0.51, blue: 0.75, alpha: 1.00)], radius: 12, sentido: "Vertical")

                }
  
                self.temp.text = "\(String(format: "%.0f",(tem_min+tem_max)/2)) ºC"
                self.chuva.text = "\(String(format: chuv))"
                self.vento.text = "\(String(format: vento)) "
                
                self.collectionView2.reloadData()

                
                self.radar.applyGradient(colours: [UIColor(red: 0.22, green: 0.51, blue: 0.75, alpha: 1.00), UIColor(red: 0.31, green: 0.62, blue: 0.87, alpha: 1.00)], radius: 6, sentido: "Horizontal")
                self.pluvio.applyGradient(colours: [UIColor(red: 0.22, green: 0.51, blue: 0.75, alpha: 1.00), UIColor(red: 0.31, green: 0.62, blue: 0.87, alpha: 1.00)], radius: 6, sentido: "Horizontal")
                self.mapa.applyGradient(colours: [UIColor(red: 0.22, green: 0.51, blue: 0.75, alpha: 1.00), UIColor(red: 0.31, green: 0.62, blue: 0.87, alpha: 1.00)], radius: 6, sentido: "Horizontal")
                self.hidratacao.applyGradient(colours: [UIColor(red: 0.22, green: 0.51, blue: 0.75, alpha: 1.00), UIColor(red: 0.31, green: 0.62, blue: 0.87, alpha: 1.00)], radius: 6, sentido: "Horizontal")
                
               
                
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

extension UITextView {
    func centerVertically() {
        let fittingSize = CGSize(width: bounds.width, height: CGFloat.greatestFiniteMagnitude)
        let size = sizeThatFits(fittingSize)
        let topOffset = (bounds.size.height - size.height * zoomScale) / 2
        let positiveTopOffset = max(1, topOffset)
        contentOffset.y = -positiveTopOffset
    }
}



