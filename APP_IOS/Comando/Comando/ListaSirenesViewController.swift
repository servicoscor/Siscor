//
//  ListaSirenesViewController.swift
//  Comando
//
//  Created by Candido Bugarin on 21/05/19.
//  Copyright © 2019 Candido Bugarin. All rights reserved.
//

import UIKit

class ListaSirenesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let dispatchQueue = DispatchQueue(label: "Dispatch Queue", attributes: [], target: nil)
    var lingua = ""
    
    @IBOutlet weak var table: UITableView!
    
    
    var fav: Array<Sirene> = []
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if ((UserDefaults.standard.string(forKey: "lingua_usu")) != nil) {
            lingua = UserDefaults.standard.string(forKey: "lingua_usu")!
        } else {
            lingua = UserDefaults.standard.stringArray(forKey: "AppleLanguages")![0]
        }
        
        
        if lingua.contains("pt") {
            title = "Sirenes"
        } else if lingua.contains("es") {
            title = "Sirenas"
        } else {
            title = "Sirens"
        }
        
        
        
        if #available(iOS 15, *) {
            
            let logoContainer = UIView(frame: CGRect(x: 0, y: 0, width: 270, height: 30))
            
            let myimage = UIImage(named: "logo_cor.png")?.withRenderingMode(.alwaysOriginal)


            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
           
            if self.traitCollection.userInterfaceStyle == .dark {
                appearance.backgroundColor = UIColor(red: 0.00, green: 0.00, blue: 0.00, alpha: 1.00)
            } else {
                appearance.backgroundColor = UIColor(red: 0.30, green: 0.50, blue: 0.73, alpha: 1.00)
            }
            
            
            appearance.shadowColor = .none
            
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationItem.titleView = logoContainer
            
            navigationController?.navigationBar.scrollEdgeAppearance = navigationController?.navigationBar.standardAppearance
            
            let rightBarButton = UIBarButtonItem(image: myimage, style: UIBarButtonItem.Style.plain, target: self, action: "")
            self.navigationItem.rightBarButtonItem = rightBarButton
            
            
        }
        
        table.layer.cornerRadius = 5
        self.table.layer.shadowOpacity = 0.3
        self.table.layer.shadowOffset = CGSize.zero
        self.table.layer.shadowRadius = 5
        
        self.table.dataSource = self
        self.table.delegate = self
        
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        table.contentInset = UIEdgeInsets.zero
        self.automaticallyAdjustsScrollViewInsets = false
        
        
        // Do any additional setup after loading the view.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.fav.count
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.table.dequeueReusableCell(withIdentifier: "cell")
        
        if lingua.contains("pt") {
            if (self.fav[indexPath.row].status).contains("ds") {
                cell?.textLabel?.text = self.fav[indexPath.row].comunidade + " - " + self.fav[indexPath.row].nome + " - Desmobilizada"
            } else {
               cell?.textLabel?.text = self.fav[indexPath.row].comunidade + " - " + self.fav[indexPath.row].nome + " - Mobilizada"
            }
        } else if lingua.contains("es") {
            if (self.fav[indexPath.row].status).contains("ds") {
                cell?.textLabel?.text = self.fav[indexPath.row].comunidade + " - " + self.fav[indexPath.row].nome + " - Desmovilizados"
            } else {
               cell?.textLabel?.text = self.fav[indexPath.row].comunidade + " - " + self.fav[indexPath.row].nome + " - Movilizados"
            }
        } else {
            if (self.fav[indexPath.row].status).contains("ds") {
                cell?.textLabel?.text = self.fav[indexPath.row].comunidade + " - " + self.fav[indexPath.row].nome + " - Demobilized"
            } else {
               cell?.textLabel?.text = self.fav[indexPath.row].comunidade + " - " + self.fav[indexPath.row].nome + " - Mobilized"
            }
        }
        
        
     

        return cell!
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
