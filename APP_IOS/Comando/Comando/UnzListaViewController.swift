//
//  UnzListaViewController.swift
//  Comando
//
//  Created by Candido Bugarin on 19/07/19.
//  Copyright © 2019 Candido Bugarin. All rights reserved.
//

import UIKit

class UnzListaViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var table: UITableView!

    let dispatchQueue = DispatchQueue(label: "Dispatch Queue", attributes: [], target: nil)
    
    var fav: Array<Interdicoes> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        if #available(iOS 15, *) {
            
            let logoContainer = UIView(frame: CGRect(x: 0, y: 0, width: 270, height: 30))
            
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(red:0.00, green:0.34, blue:0.75, alpha:1.0)
            appearance.shadowColor = .none
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationItem.titleView = logoContainer
            navigationController?.navigationBar.scrollEdgeAppearance = navigationController?.navigationBar.standardAppearance
                    
            
        }
        
        title = "Pontos de Retenção"
        
        let xib = UINib(nibName: "CellAvisos", bundle: nil)
        self.table.register(xib,forCellReuseIdentifier:"cell")
        
        self.table.dataSource = self
        self.table.delegate = self
        
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 300
        
        table.contentInset = UIEdgeInsets.zero
        self.automaticallyAdjustsScrollViewInsets = false
        
        table.layer.cornerRadius = 5
        table.layer.borderColor = UIColor(red:0.00, green:0.51, blue:0.69, alpha:1.0).cgColor
        table.layer.borderWidth = 1
        
        // Do any additional setup after loading the view.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.fav.count
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.table.dequeueReusableCell(withIdentifier: "cell")! as! CellAvisos
        cell.cellNome.text = self.fav[indexPath.row].via
        cell.cellDesc.text = "Vel. Normal: "+self.fav[indexPath.row].nor+" KM/H - Vel. Atual: "+self.fav[indexPath.row].reg+" KM/H"
        return cell
    }
    
    func tableView(_ didSelectRowAttableView:UITableView, didSelectRowAt indexPath: IndexPath) {
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
