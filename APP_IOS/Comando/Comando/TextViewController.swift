//
//  TextViewController.swift
//  DCNI
//
//  Created by Candido Bugarin on 23/11/17.
//  Copyright © 2017 Candido Bugarin. All rights reserved.
//

import UIKit

class TextViewController: UIViewController {
    
    @IBOutlet weak var view_fora: UIView!
    @IBOutlet weak var texto: UITextView!
    @IBOutlet weak var titulolabel: UILabel!
    
    var texto_input = ""
    var fonte_t = ""
    var data = ""
    var titulo = ""
    var poli = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.titulolabel.text = titulo
        title = fonte_t
        
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
        
        self.texto.text = texto_input.replacingOccurrences(of: "pulalinha", with: "\n").replacingOccurrences(of: "pontovirgula", with: ";").replacingOccurrences(of: "jumpline", with: "\n\n")

        view_fora.layer.cornerRadius = 5
        view_fora.layer.masksToBounds = false
        
        view_fora.layer.shadowColor = UIColor.gray.cgColor
        view_fora.layer.shadowOpacity = 0.5
        view_fora.layer.shadowOffset = CGSize.zero
        view_fora.layer.shadowRadius = 3
        
        let defaults = UserDefaults.standard
         
        let array = defaults.object(forKey:"SavedArray") as? [String] ?? [String]()
        
         self.texto.isSelectable = true
         self.texto.dataDetectorTypes = .link
        
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
