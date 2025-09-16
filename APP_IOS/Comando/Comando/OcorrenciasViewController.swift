//
//  OcorrenciasViewController.swift
//  Comando
//
//  Created by Candido Bugarin on 09/07/19.
//  Copyright © 2019 Candido Bugarin. All rights reserved.
//


import UIKit
import CoreLocation
import SwiftOverlays
import MapKit

class OcorrenciasViewController: UIViewController, UITableViewDelegate, UITableViewDataSource  {
    
    
    let dispatchQueue = DispatchQueue(label: "Dispatch Queue", attributes: [], target: nil)
    var filtro = ""
    var fav8: Array<Comando> = []
    var fav7: Array<Comando> = []

    var device_uuid: String = ""
    var activityIndicatorAlert: UIAlertController?

    @IBOutlet weak var table: UITableView!
    
    var lingua = ""
    
    override func viewDidLoad() {
        
        if ((UserDefaults.standard.string(forKey: "lingua_usu")) != nil) {
            lingua = UserDefaults.standard.string(forKey: "lingua_usu")!
        } else {
            lingua = UserDefaults.standard.stringArray(forKey: "AppleLanguages")![0]
        }
        

        super.viewDidLoad()
        if self.lingua.contains("pt") {
            self.title = "Incidente"
           
        } else if self.lingua.contains("es") {
            self.title = "Incidente"
        } else {
            self.title = "Incident"
        }
        
        
        let xib = UINib(nibName: "OcorrenciaTableViewCell", bundle: nil)
        
        self.table.register(xib,forCellReuseIdentifier:"cell")
        
        self.table.dataSource = self
        self.table.delegate = self
        
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
        return self.fav7.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.table.dequeueReusableCell(withIdentifier: "cell")! as! OcorrenciaTableViewCell
        
        cell.titulo.text = self.fav7[indexPath.row].nome_e+"\n\n"+self.fav7[indexPath.row].local+"\n\n"+self.fav7[indexPath.row].data
        
   
        
        if self.fav7[indexPath.row].criti.contains("1") {
            cell.view_2.applyGradient(colours: [UIColor(red: 0.25, green: 0.44, blue: 0.29, alpha: 1.00), UIColor(red: 0.25, green: 0.60, blue: 0.32, alpha: 1.00)], radius: 0, sentido: "Vertical")
        } else if self.fav7[indexPath.row].criti.contains("2") {
            cell.view_2.applyGradient(colours: [UIColor(red: 0.93, green: 0.75, blue: 0.22, alpha: 1.00),UIColor(red: 1.00, green: 0.91, blue: 0.65, alpha: 1.00)], radius: 0, sentido: "Vertical")
        } else if self.fav7[indexPath.row].criti.contains("3") {
            cell.view_2.applyGradient(colours: [UIColor(red: 0.25, green: 0.44, blue: 0.29, alpha: 1.00), UIColor(red: 0.25, green: 0.60, blue: 0.32, alpha: 1.00)], radius: 0, sentido: "Vertical")

        } else if self.fav7[indexPath.row].criti.contains("4") {
            cell.view_2.applyGradient(colours: [UIColor(red: 0.25, green: 0.44, blue: 0.29, alpha: 1.00), UIColor(red: 0.25, green: 0.60, blue: 0.32, alpha: 1.00)], radius: 0, sentido: "Vertical")
        } else if self.fav7[indexPath.row].criti.contains("0") {
            cell.view_2.applyGradient(colours: [UIColor(red: 0.25, green: 0.44, blue: 0.29, alpha: 1.00), UIColor(red: 0.25, green: 0.60, blue: 0.32, alpha: 1.00)], radius: 0, sentido: "Vertical")
        }
        
        if self.lingua.contains("pt") {
            
            
            if self.fav7[indexPath.row].nome.contains("Acidentes") {
                cell.imagem.image = UIImage(named: "accident.png")
            } else if self.fav7[indexPath.row].nome.contains("Eventos") {
                cell.imagem.image = UIImage(named: "calendar.png")
            } else if self.fav7[indexPath.row].nome.contains("Buracos na Via") {
                cell.imagem.image = UIImage(named: "traffic-cone.png")
            } else if self.fav7[indexPath.row].nome.contains("Outros") {
                cell.imagem.image = UIImage(named: "more.png")
            } else if self.fav7[indexPath.row].nome.contains("Deslizamentos") {
                cell.imagem.image = UIImage(named: "landslide.png")
            } else if self.fav7[indexPath.row].nome.contains("Alagamentos") {
                cell.imagem.image = UIImage(named: "flood.png")
            } else if self.fav7[indexPath.row].nome.contains("Incêndios") {
                cell.imagem.image = UIImage(named: "fire.png")
            } else if self.fav7[indexPath.row].nome.contains("Operação Policial") {
                cell.imagem.image = UIImage(named: "policeman.png")
            } else if self.fav7[indexPath.row].nome.contains("Quedas de Árvore") {
                cell.imagem.image = UIImage(named: "lightning.png")
            } else if self.fav7[indexPath.row].nome.contains("Obras") {
                cell.imagem.image = UIImage(named: "traffic-cone.png")
            } else if self.fav7[indexPath.row].nome.contains("Todas") {
                cell.imagem.image = UIImage(named: "search.png")
            }
        } else if self.lingua.contains("es") {
            if self.fav7[indexPath.row].nome.contains("Accidentes") {
                cell.imagem.image = UIImage(named: "accident.png")
            } else if self.fav7[indexPath.row].nome.contains("Eventos") {
                cell.imagem.image = UIImage(named: "calendar.png")
            } else if self.fav7[indexPath.row].nome.contains("Agujeros en la carretera") {
                cell.imagem.image = UIImage(named: "traffic-cone.png")
            } else if self.fav7[indexPath.row].nome.contains("Otros") {
                cell.imagem.image = UIImage(named: "more.png")
            } else if self.fav7[indexPath.row].nome.contains("Derrumbes") {
                cell.imagem.image = UIImage(named: "landslide.png")
            } else if self.fav7[indexPath.row].nome.contains("Inundación") {
                cell.imagem.image = UIImage(named: "flood.png")
            } else if self.fav7[indexPath.row].nome.contains("Incendios") {
                cell.imagem.image = UIImage(named: "fire.png")
            } else if self.fav7[indexPath.row].nome.contains("Operación policial") {
                cell.imagem.image = UIImage(named: "policeman.png")
            } else if self.fav7[indexPath.row].nome.contains("Caídas del árbol") {
                cell.imagem.image = UIImage(named: "lightning.png")
            } else if self.fav7[indexPath.row].nome.contains("Construcción") {
                cell.imagem.image = UIImage(named: "traffic-cone.png")
            } else if self.fav7[indexPath.row].nome.contains("Todas") {
                cell.imagem.image = UIImage(named: "search.png")
            }
        } else {
            if self.fav7[indexPath.row].nome.contains("Accidents") {
                cell.imagem.image = UIImage(named: "accident.png")
            } else if self.fav7[indexPath.row].nome.contains("Events") {
                cell.imagem.image = UIImage(named: "calendar.png")
            } else if self.fav7[indexPath.row].nome.contains("Holes in the Road") {
                cell.imagem.image = UIImage(named: "traffic-cone.png")
            } else if self.fav7[indexPath.row].nome.contains("Others") {
                cell.imagem.image = UIImage(named: "more.png")
            } else if self.fav7[indexPath.row].nome.contains("Landslides") {
                cell.imagem.image = UIImage(named: "landslide.png")
            } else if self.fav7[indexPath.row].nome.contains("Floods") {
                cell.imagem.image = UIImage(named: "flood.png")
            } else if self.fav7[indexPath.row].nome.contains("Fires") {
                cell.imagem.image = UIImage(named: "fire.png")
            } else if self.fav7[indexPath.row].nome.contains("Police Operation") {
                cell.imagem.image = UIImage(named: "policeman.png")
            } else if self.fav7[indexPath.row].nome.contains("Tree Falls") {
                cell.imagem.image = UIImage(named: "lightning.png")
            } else if self.fav7[indexPath.row].nome.contains("Construction") {
                cell.imagem.image = UIImage(named: "traffic-cone.png")
            } else if self.fav7[indexPath.row].nome.contains("All") {
                cell.imagem.image = UIImage(named: "search.png")
            }
        }
        
        return cell
    }
    
    func tableView(_ didSelectRowAttableView:UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if self.lingua.contains("pt") {
            let vc = OcorrenciaPageViewController(nibName:"OcorrenciaPageViewController", bundle:nil)
            vc.lat = self.fav7[indexPath.row].lat
            vc.lon = self.fav7[indexPath.row].lon
            vc.id = self.fav7[indexPath.row].id
            vc.data = "Data\n"+self.fav7[indexPath.row].data
            vc.end_texto = "Endereço\n"+self.fav7[indexPath.row].local
            vc.acidente_texto = "Incidente\n"+self.fav7[indexPath.row].nome_e
            vc.tipo_texto = "Tipo\n"+self.fav7[indexPath.row].nome
            self.navigationController!.pushViewController(vc, animated: true)
            table.deselectRow(at: indexPath, animated: true)
        } else if self.lingua.contains("es") {
            let vc = OcorrenciaPageViewController(nibName:"OcorrenciaPageViewController", bundle:nil)
            vc.lat = self.fav7[indexPath.row].lat
            vc.lon = self.fav7[indexPath.row].lon
            vc.id = self.fav7[indexPath.row].id
            vc.data = "Fecha\n"+self.fav7[indexPath.row].data
            vc.end_texto = "DIRECCIÓN\n"+self.fav7[indexPath.row].local
            vc.acidente_texto = "Incidente\n"+self.fav7[indexPath.row].nome_e
            vc.tipo_texto = ""+self.fav7[indexPath.row].nome
            self.navigationController!.pushViewController(vc, animated: true)
            table.deselectRow(at: indexPath, animated: true)
        } else {
            let vc = OcorrenciaPageViewController(nibName:"OcorrenciaPageViewController", bundle:nil)
            vc.lat = self.fav7[indexPath.row].lat
            vc.lon = self.fav7[indexPath.row].lon
            vc.id = self.fav7[indexPath.row].id
            vc.data = "Date\n"+self.fav7[indexPath.row].data
            vc.end_texto = "Address\n"+self.fav7[indexPath.row].local
            vc.acidente_texto = "Incident\n"+self.fav7[indexPath.row].nome_e
            vc.tipo_texto = ""+self.fav7[indexPath.row].nome
            self.navigationController!.pushViewController(vc, animated: true)
            table.deselectRow(at: indexPath, animated: true)
        }
        
       
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Hide the navigation bar on the this view controller
        
        let text = "Coletando informações"
        self.showWaitOverlayWithText(text)

        dispatchQueue.async {
            OperationQueue.main.addOperation() {
                
                if self.lingua.contains("pt") {
                    self.fav8 = ColetaDados_Comando.getdata()
                } else if self.lingua.contains("es") {
                    self.fav8 = ColetaDados_Comando_ES.getdata()
                } else {
                    self.fav8 = ColetaDados_Comando_EN.getdata()
                }
                
                self.fav7.removeAll()
                
                
                if self.lingua.contains("pt") {
                    if self.filtro.contains("Todos") {
                        var x = 0
                        while x != self.fav8.count {
                            self.fav7.append(self.fav8[x])
                            x += 1
                        }
                        
                    } else {
                        
                        var x = 0
                        while x != self.fav8.count {
                            if self.fav8[x].nome.contains(self.filtro) {
                                self.fav7.append(self.fav8[x])
                            }
                            x += 1
                        }
                    }
                } else if self.lingua.contains("es") {
                    if self.filtro.contains("Todos") {
                        var x = 0
                        while x != self.fav8.count {
                            self.fav7.append(self.fav8[x])
                            x += 1
                        }
                        
                    } else {
                        
                        var x = 0
                        while x != self.fav8.count {
                            if self.fav8[x].nome.contains(self.filtro) {
                                self.fav7.append(self.fav8[x])
                            }
                            x += 1
                        }
                    }
                } else {
                    if self.filtro.contains("All") {
                        var x = 0
                        while x != self.fav8.count {
                            self.fav7.append(self.fav8[x])
                            x += 1
                        }
                        
                    } else {
                        
                        var x = 0
                        while x != self.fav8.count {
                            if self.fav8[x].nome.contains(self.filtro) {
                                self.fav7.append(self.fav8[x])
                            }
                            x += 1
                        }
                    }
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
