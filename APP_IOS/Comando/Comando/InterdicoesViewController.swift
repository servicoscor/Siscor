//
//  InterdicoesViewController.swift
//  Comando
//
//  Created by Candido Bugarin on 04/12/18.
//  Copyright © 2018 Candido Bugarin. All rights reserved.
//

import UIKit

class InterdicoesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let dispatchQueue = DispatchQueue(label: "Dispatch Queue", attributes: [], target: nil)

    @IBOutlet weak var table: UITableView!

    var fav: Array<Interdicoes> = []
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Interdições"
        
        table.layer.cornerRadius = 5
        table.layer.borderColor = UIColor(red:0.00, green:0.51, blue:0.69, alpha:1.0).cgColor
        table.layer.borderWidth = 1
        
        self.table.dataSource = self
        self.table.delegate = self
        
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
        table.deselectRow(at: indexPath, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Hide the navigation bar on the this view controller
        
        let text = "Coletando informações"
        self.showWaitOverlayWithText(text)
        
        
        dispatchQueue.async {
            OperationQueue.main.addOperation() {
                
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
