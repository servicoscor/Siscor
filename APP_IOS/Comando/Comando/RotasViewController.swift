//
//  RotasViewController.swift
//  Comando
//
//  Created by Candido Bugarin on 26/12/18.
//  Copyright © 2018 Candido Bugarin. All rights reserved.
//

import UIKit

class RotasViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var table: UITableView!
    
    var fav: Array<Rotas> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Rotas"
        
        table.layer.cornerRadius = 5
        table.layer.borderColor = UIColor(red:0.00, green:0.51, blue:0.69, alpha:1.0).cgColor
        table.layer.borderWidth = 1
        
        self.table.dataSource = self
        self.table.delegate = self
        
        self.fav = ColetaDados_Rotas.getdata()
        
        let xib = UINib(nibName: "CellAvisos", bundle: nil)
        self.table.register(xib,forCellReuseIdentifier:"cell")
        
        table.contentInset = UIEdgeInsets.zero
        self.automaticallyAdjustsScrollViewInsets = false
        // Do any additional setup after loading the view.

        // Do any additional setup after loading the view.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.fav.count
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.table.dequeueReusableCell(withIdentifier: "cell")! as! CellAvisos
        cell.cellNome.text = (self.fav[indexPath.row].nome).capitalized
        cell.cellDesc.text = "Tempo: " + self.fav[indexPath.row].tempo + " minutos"
        return cell
    }
    
    func tableView(_ didSelectRowAttableView:UITableView, didSelectRowAt indexPath: IndexPath) {
        let alert = UIAlertController(title: (self.fav[indexPath.row].nome).capitalized, message: (self.fav[indexPath.row].endereco), preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Ok!", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
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

extension String {
    func capitalizingFirstLetter() -> String {
        return prefix(1).uppercased() + self.lowercased().dropFirst()
    }
    
    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
}
