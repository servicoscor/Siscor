//
//  TextViewController.swift
//  DCNI
//
//  Created by Candido Bugarin on 23/11/17.
//  Copyright © 2017 Candido Bugarin. All rights reserved.
//

import UIKit

class TextViewController: UIViewController {
    var titulo = ""
    var texto = ""
    @IBOutlet weak var texto_rec: UITextView!
    override func viewDidLoad() {
        super.viewDidLoad()
        title = titulo
        texto_rec.text = texto.replacingOccurrences(of: "<br/>", with: "\n")
        texto_rec.layer.cornerRadius = 10
        texto_rec.layer.borderColor = UIColor(red:1, green:1, blue:1, alpha:1.0).cgColor
        texto_rec.layer.borderWidth = 2.5
        texto_rec.contentInset = UIEdgeInsets.init(top: 5,left: 0,bottom: 0,right: 0);
        texto_rec.contentInset = UIEdgeInsets.zero
        self.automaticallyAdjustsScrollViewInsets = false
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
