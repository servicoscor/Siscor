//
//  OcorrenciasCollectionViewCell.swift
//  Comando
//
//  Created by Candido Bugarin on 08/07/23.
//  Copyright © 2023 Candido Bugarin. All rights reserved.
//

import UIKit

class OcorrenciasCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var imagem: UIImageView!
    @IBOutlet weak var titulo: UILabel!
    
    // Para o gradiente
    private var gradientLayer: CAGradientLayer?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        
        // Melhorar a tipografia do texto
        titulo.textColor = .white
        titulo.font = UIFont.systemFont(ofSize: titulo.font.pointSize, weight: .medium)
        
        // Adicionar espaçamento entre letras para maior legibilidade
        if let text = titulo.text {
            let attributedString = NSMutableAttributedString(string: text)
            attributedString.addAttribute(NSAttributedString.Key.kern, value: 0.5, range: NSRange(location: 0, length: text.count))
            titulo.attributedText = attributedString
        }
        
        // Aplicar gradiente ao fundo
    }
    
    // Método para aplicar o gradiente
   
    
    // Garantir que o gradiente seja atualizado quando o tamanho mudar
    override func layoutSubviews() {
        super.layoutSubviews()
        if let gradientLayer = containerView.layer.sublayers?.first as? CAGradientLayer {
            gradientLayer.frame = containerView.bounds
        }
        
        // Atualizar o layout para garantir que tudo esteja alinhado
        if titulo.frame.origin.y + titulo.frame.height > containerView.bounds.height - 12 {
            titulo.frame.origin.y = containerView.bounds.height - titulo.frame.height - 12
        }
    }
    

    
    @IBOutlet weak var containerView: UIView! {
        didSet {
           
            
        }
    }
    
    @IBOutlet weak var clippingView: UIView! {
        didSet {
            clippingView.layer.cornerRadius = 10
            clippingView.layer.masksToBounds = true
            
            // Adicionar borda sutil mais refinada
            clippingView.layer.borderWidth = 0.5
            clippingView.layer.borderColor = UIColor.white.withAlphaComponent(0.15).cgColor
            
            // Adicionar um efeito de profundidade sutil com inner shadow
            let innerShadow = CALayer()
            innerShadow.frame = clippingView.bounds
            innerShadow.shadowColor = UIColor.black.cgColor
            innerShadow.shadowOffset = CGSize.zero
            innerShadow.shadowOpacity = 0.1
            innerShadow.shadowRadius = 3
            innerShadow.masksToBounds = true
            clippingView.layer.addSublayer(innerShadow)
            
            clippingView.backgroundColor = UIColor(red: 0.38, green: 0.58, blue: 0.78, alpha: 0.85) // Azul mais claro
        }
    }
    
    // Adicionar feedback visual ao toque
    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.1) {
                if self.isHighlighted {
                    self.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
                    self.containerView.alpha = 0.9
                } else {
                    self.transform = .identity
                    self.containerView.alpha = 1.0
                }
            }
        }
    }
}
