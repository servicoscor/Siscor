//
//  AlertasCollectionViewCell.swift
//  Comando
//
//  Created by Candido Bugarin on 07/08/19.
//  Copyright © 2019 Candido Bugarin. All rights reserved.
//

import UIKit
import MapKit

class AlertasCollectionViewCell: UICollectionViewCell,MKMapViewDelegate {


    @IBOutlet weak var titulo: UILabel!
    @IBOutlet weak var maps: MKMapView!
    @IBOutlet weak var texto: UITextView!
    
    @IBOutlet weak var widthConstraint: NSLayoutConstraint!

    
    let latitude:CLLocationDegrees = -22.9241421
    let longitude:CLLocationDegrees = -43.4405087
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        // Initialization code
        
        texto.isScrollEnabled = false
        self.containerView.translatesAutoresizingMaskIntoConstraints = false
        let screen = UIScreen.main.bounds.size.width
        widthConstraint.constant = screen - (2 * 12)

    }
    
    @IBOutlet weak var containerView: UIView! {
        didSet {
            
            containerView.layer.shadowColor = UIColor.gray.cgColor
            containerView.layer.shadowOpacity = 0.3
            containerView.layer.shadowOffset = CGSize.zero
            containerView.layer.shadowRadius = 5
            containerView.layer.cornerRadius = 16
            
            
       
            
            
        }
    }
    
    
    @IBOutlet weak var clippingView: UIView! {
        didSet {
            clippingView.layer.cornerRadius = 10
            clippingView.layer.masksToBounds = true
        }
    }

}
