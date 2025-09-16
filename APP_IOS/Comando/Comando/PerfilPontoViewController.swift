//
//  PerfilPontoViewController.swift
//  Comando
//
//  Created by Candido Bugarin on 26/01/24.
//  Copyright © 2024 Candido Bugarin. All rights reserved.
//

import UIKit

class PerfilPontoViewController: UIViewController {

    @IBOutlet weak var text_descricao: UITextView!
    @IBOutlet weak var texto_titulo: UILabel!
    
    var titulo = ""
    var texto = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.text_descricao.text = texto
        self.texto_titulo.text = titulo
        self.title = titulo

        // Do any additional setup after loading the view.
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
