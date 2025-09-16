//
//  TransitoViewController.swift
//  Comando
//
//  Created by Candido Bugarin on 03/12/18.
//  Copyright © 2018 Candido Bugarin. All rights reserved.
//

import UIKit

class TransitoViewController: UIViewController {

    @IBOutlet weak var feiras: UIButton!
    @IBOutlet weak var eventos: UIButton!
    @IBOutlet weak var rotas: UIButton!
    @IBOutlet weak var cameras: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Trânsito"
        
        feiras.layer.cornerRadius = 5
        feiras.layer.borderColor = UIColor(red:0.00, green:0.51, blue:0.69, alpha:1.0).cgColor
        feiras.layer.borderWidth = 1
        
        eventos.layer.cornerRadius = 5
        eventos.layer.borderColor = UIColor(red:0.00, green:0.51, blue:0.69, alpha:1.0).cgColor
        eventos.layer.borderWidth = 1
        
        rotas.layer.cornerRadius = 5
        rotas.layer.borderColor = UIColor(red:0.00, green:0.51, blue:0.69, alpha:1.0).cgColor
        rotas.layer.borderWidth = 1
        
        cameras.layer.cornerRadius = 5
        cameras.layer.borderColor = UIColor(red:0.00, green:0.51, blue:0.69, alpha:1.0).cgColor
        cameras.layer.borderWidth = 1
        
        // Do any additional setup after loading the view.
    }

    @IBAction func cameras_action(_ sender: UIButton) {
        let vc = CamerasViewController(nibName:"CamerasViewController", bundle:nil)
        self.navigationController!.pushViewController(vc, animated: true)
    }
    
    
    @IBAction func transito_action(_ sender: UIButton) {
        let vc = InterdicoesViewController(nibName:"InterdicoesViewController", bundle:nil)
        self.navigationController!.pushViewController(vc, animated: true)
    }
    @IBAction func rotas_action(_ sender: UIButton) {
        let vc = RotasViewController(nibName:"RotasViewController", bundle:nil)
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
