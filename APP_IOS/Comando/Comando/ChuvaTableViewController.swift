//
//  ChuvaTableViewController.swift
//  DCNI
//
//  Created by Candido Bugarin on 13/10/17.
//  Copyright © 2017 Candido Bugarin. All rights reserved.
//

import UIKit

class ChuvaTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var table: UITableView!
    @IBOutlet weak var mapa_but: UIButton!

    var fav3: Array<Estacao> = []

    
    let dispatchQueue = DispatchQueue(label: "Dispatch Queue", attributes: [], target: nil)
    var lingua = ""

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if ((UserDefaults.standard.string(forKey: "lingua_usu")) != nil) {
            lingua = UserDefaults.standard.string(forKey: "lingua_usu")!
        } else {
            lingua = UserDefaults.standard.stringArray(forKey: "AppleLanguages")![0]
        }
        
        
        if lingua.contains("pt") {
            self.title = "Estações Pluviométricas"
           
        } else if lingua.contains("es") {
            self.title = "Estaciones pluviométricas"
        } else {
            self.title = "Rain gauge stations"
        }
        
       
        
        let xib = UINib(nibName: "CellChuva", bundle: nil)
        self.table.register(xib,forCellReuseIdentifier:"cell")
        self.table.dataSource = self
        self.table.delegate = self
        table.contentInset = UIEdgeInsets.zero
        self.automaticallyAdjustsScrollViewInsets = false
        
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
        

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.fav3.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.table.dequeueReusableCell(withIdentifier: "cell")! as! CellChuva
        cell.cellNome.text = self.fav3[indexPath.row].nome
        
        if lingua.contains("pt") {
            cell.cellDesc.text = "Última leitura: "+String(self.fav3[indexPath.row].chuva_1)+" mm/h"

           
        } else if lingua.contains("es") {
            cell.cellDesc.text = "Última información: "+String(self.fav3[indexPath.row].chuva_1)+" mm/h"

        } else {
            cell.cellDesc.text = "Latest information: "+String(self.fav3[indexPath.row].chuva_1)+" mm/h"

        }
        
        
        cell.cellFonte.text = self.fav3[indexPath.row].data+" - "+self.fav3[indexPath.row].fonte
        
        var coisa:UIImage = #imageLiteral(resourceName: "wht-blank.png")
        let valor_chuva = self.fav3[indexPath.row].chuva_1
        
        if self.fav3[indexPath.row].situ.contains("atual") {
        if valor_chuva == 0.0 {
            coisa = #imageLiteral(resourceName: "wht-blank.png")
            
            cell.cellicon.applyGradient(colours: [UIColor(red: 0.25, green: 0.44, blue: 0.29, alpha: 1.00), UIColor(red: 0.25, green: 0.60, blue: 0.32, alpha: 1.00)], radius: 0, sentido: "Vertical")
            
        } else if valor_chuva > 0.1 && valor_chuva <= 5.0 {
            coisa = #imageLiteral(resourceName: "blu-blank.png")
            
            cell.cellicon.applyGradient(colours: [UIColor(red: 0.31, green: 0.62, blue: 0.87, alpha: 1.00), UIColor(red: 0.15, green: 0.85, blue: 0.96, alpha: 1.00)], radius: 0, sentido: "Vertical")
            
        } else if valor_chuva > 5 && valor_chuva <= 25 {
            
            coisa = #imageLiteral(resourceName: "ylw-blank.png")
            
            cell.cellicon.applyGradient(colours: [UIColor(red: 0.93, green: 0.75, blue: 0.22, alpha: 1.00),UIColor(red: 1.00, green: 0.91, blue: 0.65, alpha: 1.00)], radius: 0, sentido: "Vertical")

                        
        } else if valor_chuva > 25 && valor_chuva <= 50 {
            
            coisa = #imageLiteral(resourceName: "orangeblank.png")
            
            cell.cellicon.applyGradient(colours: [UIColor(red: 0.25, green: 0.44, blue: 0.29, alpha: 1.00), UIColor(red: 0.25, green: 0.60, blue: 0.32, alpha: 1.00)], radius: 0, sentido: "Vertical")
            
        } else if valor_chuva > 50 {
            
            coisa = #imageLiteral(resourceName: "red-stars.png")
            
            cell.cellicon.applyGradient(colours: [UIColor(red: 0.45, green: 0.18, blue: 0.50, alpha: 1.00),UIColor(red: 0.86, green: 0.36, blue: 0.95, alpha: 1.00)], radius: 0, sentido: "Vertical")
        }
        
        } 
        
        
        return cell
    }
    
    func tableView(_ didSelectRowAttableView:UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = EstaPluViewController(nibName:"EstaPluViewController", bundle:nil)
        vc.fav3 = [self.fav3[indexPath.row]]
        self.navigationController!.pushViewController(vc, animated: true)
        table.deselectRow(at: indexPath, animated: true)
    }
    
    @IBAction func mapa_act(_ sender: UIButton) {
        let vc = MapaViewController(nibName:"MapaViewController", bundle:nil)
        self.navigationController!.pushViewController(vc, animated: true)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
