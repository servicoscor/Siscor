//
//  AlertasViewController.swift
//  Comando
//
//  Created by Candido Bugarin on 03/07/19.
//  Copyright © 2019 Candido Bugarin. All rights reserved.
//

import UIKit


class AvisosCarnavalViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var table: UITableView!
    
    var fav: Array<Avisos> = []
    
    @IBOutlet weak var view_fora: UIView!
    
    let dispatchQueue = DispatchQueue(label: "Dispatch Queue", attributes: [], target: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Avisos"
        
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
        view_fora.layer.shadowColor = UIColor.gray.cgColor
        view_fora.layer.shadowOpacity = 0.3
        view_fora.layer.shadowOffset = CGSize.zero
        view_fora.layer.shadowRadius = 6
        view_fora.layer.cornerRadius = 5

        
        let xib = UINib(nibName: "AvisoTableViewCell", bundle: nil)
              self.table.register(xib,forCellReuseIdentifier:"cell")
              self.table.dataSource = self
              self.table.delegate = self
              self.table.backgroundColor = UIColor.clear

        
        
    
        // Do any additional setup after loading the view.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.fav.count
        
    }
    
   func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       let cell = self.table.dequeueReusableCell(withIdentifier: "cell")! as! AvisoTableViewCell
       
       cell.titulo.text = self.fav[indexPath.row].nome
       
       if self.fav[indexPath.row].caus.contains("Tempo") {
           cell.imagem.image = UIImage(named: "water.png")
       } else if self.fav[indexPath.row].caus.contains("Trânsito") {
           cell.imagem.image = UIImage(named: "transito.png")
       } else if self.fav[indexPath.row].caus.contains("Evento") {
           cell.imagem.image = UIImage(named: "calendar.png")
       } else if self.fav[indexPath.row].caus.contains("Sirenes") {
            cell.imagem.image = UIImage(named: "alarm.png")
        }

                
        if self.fav[indexPath.row].risc.contains("Baixo") {
            print(cell.linha.subviews.count)
            cell.linha.applyGradient(colours: [UIColor(red: 0.25, green: 0.44, blue: 0.29, alpha: 1.00), UIColor(red: 0.25, green: 0.60, blue: 0.32, alpha: 1.00)], radius: 6, sentido: "Vertical")
        } else if self.fav[indexPath.row].risc.contains("Médio") {
            cell.linha.applyGradient(colours: [UIColor(red: 0.93, green: 0.75, blue: 0.22, alpha: 1.00),UIColor(red: 1.00, green: 0.91, blue: 0.65, alpha: 1.00)], radius: 6, sentido: "Vertical")
        } else if self.fav[indexPath.row].risc.contains("Alto") {
            cell.linha.applyGradient(colours: [UIColor(red: 0.66, green: 0.07, blue: 0.19, alpha: 1.00),UIColor(red: 0.87, green: 0.13, blue: 0.13, alpha: 1.00)], radius: 6, sentido: "Vertical")
        } else if self.fav[indexPath.row].risc.contains("Crítico") {
            cell.linha.applyGradient(colours: [UIColor(red: 0.25, green: 0.44, blue: 0.29, alpha: 1.00), UIColor(red: 0.25, green: 0.60, blue: 0.32, alpha: 1.00)], radius: 6, sentido: "Vertical")
        }
       
       return cell
    }
    
    func tableView(_ didSelectRowAttableView:UITableView, didSelectRowAt indexPath: IndexPath) {
      
            let vc = TextViewController(nibName:"TextViewController", bundle:nil)
        vc.texto_input = self.fav[indexPath.row].text
            vc.titulo = self.fav[indexPath.row].nome
            vc.fonte_t = "COR RIO Informa"
            self.navigationController!.pushViewController(vc, animated: true)
            
            table.deselectRow(at: indexPath, animated: true)
       
        
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
