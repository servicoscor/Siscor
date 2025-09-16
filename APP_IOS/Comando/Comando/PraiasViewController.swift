//
//  PraiasViewController.swift
//  Comando
//
//  Created by Candido Bugarin on 06/12/18.
//  Copyright © 2018 Candido Bugarin. All rights reserved.
//

import UIKit

class PraiasViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var fav: Array<Praias> = []
    var fav3: Array<UV> = []

    @IBOutlet weak var mapa: UIButton!
    @IBOutlet weak var mares: UIButton!
    @IBOutlet weak var table: UITableView!
    
    @IBOutlet weak var uvlabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Praias"
        
        mapa.layer.cornerRadius = 5
        mapa.layer.borderColor = UIColor(red:0.00, green:0.51, blue:0.69, alpha:1.0).cgColor
        mapa.layer.borderWidth = 1
        
        mares.layer.cornerRadius = 5
        mares.layer.borderColor = UIColor(red:0.00, green:0.51, blue:0.69, alpha:1.0).cgColor
        mares.layer.borderWidth = 1
        
        table.layer.cornerRadius = 5
        table.layer.borderColor = UIColor(red:0.00, green:0.51, blue:0.69, alpha:1.0).cgColor
        table.layer.borderWidth = 1
        
        self.table.dataSource = self
        self.table.delegate = self
        
        self.fav = ColetaDados_Praias.getdata()
        self.fav3 = ColetaDados_UV.getdata()
        
        uvlabel.layer.cornerRadius = 5
        
        if 0.0 < (self.fav3[0].valor) && (self.fav3[0].valor) < 2.9 {
            self.uvlabel.text = "UV Baixo"
             uvlabel.layer.backgroundColor  = UIColor(red:0.21, green:0.83, blue:0.85, alpha:1.0).cgColor

        } else if 3 < (self.fav3[0].valor) && (self.fav3[0].valor) < 5.9 {
            self.uvlabel.text = "UV Moderado"
            uvlabel.layer.backgroundColor  = UIColor(red:0.61, green:0.72, blue:0.02, alpha:1.0).cgColor

        } else if 6 < (self.fav3[0].valor) && (self.fav3[0].valor) < 7.9 {
            self.uvlabel.text = "UV Alto"
             uvlabel.layer.backgroundColor  = UIColor(red:1.00, green:0.97, blue:0.39, alpha:1.0).cgColor

        } else if 8 < (self.fav3[0].valor) && (self.fav3[0].valor) < 10.9 {
            self.uvlabel.text = "UV Muito Alto"
             uvlabel.layer.backgroundColor  = UIColor(red:0.97, green:0.61, blue:0.07, alpha:1.0).cgColor

        } else if 11 < (self.fav3[0].valor) {
            self.uvlabel.text = "UV Extremo"
            uvlabel.layer.backgroundColor = UIColor(red:0.95, green:0.24, blue:0.02, alpha:1.0).cgColor
            
        }
        
        let xib = UINib(nibName: "CellAvisos", bundle: nil)
        self.table.register(xib,forCellReuseIdentifier:"cell")
        
        table.contentInset = UIEdgeInsets.zero
        self.automaticallyAdjustsScrollViewInsets = false
        // Do any additional setup after loading the view.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.fav.count
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.table.dequeueReusableCell(withIdentifier: "cell")! as! CellAvisos
        cell.cellNome.text = self.fav[indexPath.row].nome
        cell.cellDesc.text = self.fav[indexPath.row].status
        return cell
    }
    
    func tableView(_ didSelectRowAttableView:UITableView, didSelectRowAt indexPath: IndexPath) {
        let alert = UIAlertController(title: (self.fav[indexPath.row].nome).capitalized, message: (self.fav[indexPath.row].status + "\n" + self.fav[indexPath.row].loc), preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Ok!", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
        table.deselectRow(at: indexPath, animated: true)
    }

    @IBAction func mapa_open(_ sender: UIButton) {
        let vc = MapaPraiasViewController(nibName:"MapaPraiasViewController", bundle:nil)
        self.navigationController!.pushViewController(vc, animated: true)
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
