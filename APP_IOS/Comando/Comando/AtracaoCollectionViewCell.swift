//
//  AtracaoCollectionViewCell.swift
//  Lud
//
//  Created by Candido Bugarin on 06/03/19.
//  Copyright © 2019 Candido Bugarin. All rights reserved.
//

import UIKit

class AtracaoCollectionViewCell: UITableViewCell {

    @IBOutlet weak var imagem: UIImageView!
    @IBOutlet weak var titulo: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    @IBOutlet weak var containerView: UIView! {
        didSet {
            // Make it card-like
            containerView.layer.shadowOpacity = 0
        }
    }
    
    @IBOutlet weak var clippingView: UIView! {
        didSet {
            clippingView.layer.cornerRadius = 10
            clippingView.layer.masksToBounds = true
        }
    }

}
