//
//  FotoViewController.swift
//  Comando
//
//  Created by Candido Bugarin on 24/10/19.
//  Copyright © 2019 Candido Bugarin. All rights reserved.
//

import UIKit

class FotoViewController: UIViewController {

    @IBOutlet var photoSliderView: PhotoSliderView!
    
    // MARK: View Methods
    var id_c = ""
    
    var images: [UIImage] = []
    
    var fav6: Array<Fotos> = []


    let dispatchQueue = DispatchQueue(label: "Dispatch Queue", attributes: [], target: nil)
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if #available(iOS 15, *) {
            
            let logoContainer = UIView(frame: CGRect(x: 0, y: 0, width: 270, height: 30))
            
            let myimage = UIImage(named: "logo_cor.png")?.withRenderingMode(.alwaysOriginal)

            let attributes = [NSAttributedString.Key.font: UIFont(name: "Raleway-Bold", size: 20)!]
            
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
        
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Hide the navigation bar on the this view controller
        
        let text = "Coletando informações"
        self.showWaitOverlayWithText(text)
        

        dispatchQueue.async {
            OperationQueue.main.addOperation() {
                
                            
                var x = 0
                while x != (self.fav6.count) {
                    if (self.fav6[x].nome) != "" {
                        let url =  URL(string: self.fav6[x].nome)
                        let data = try? Data(contentsOf: url!) //make sure your image in this url does exist, otherwise unwrap in a if let check / try-catch
                        self.images.append(UIImage(data: data!)!)
                    }
                    x += 1
                }
                
            
                print(self.images)
                self.removeAllOverlays()
                self.photoSliderView.configure(with: self.images)

            
                
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
