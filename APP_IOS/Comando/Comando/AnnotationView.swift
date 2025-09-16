/*
 * Copyright (c) 2016 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit

protocol AnnotationViewDelegate {
    func didTouch(annotationView: AnnotationView)
}

class AnnotationView: ARAnnotationView {
    var titleLabel: UILabel?
    var distanceLabel: UILabel?
    var go: UILabel?
    var imageLabel: UIImageView?
    var delegate: AnnotationViewDelegate?
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        loadUI()
    }
    
    func loadUI() {
        titleLabel?.removeFromSuperview()
        distanceLabel?.removeFromSuperview()
        
        //print(self.frame.size.width)
        
        let label = UILabel(frame: CGRect(x: 2, y: 0, width: self.frame.size.width, height: 30))
        label.font = UIFont.systemFont(ofSize: 16)
        label.numberOfLines = 0
        label.textColor = UIColor.white
        self.addSubview(label)
        self.titleLabel = label
        
        distanceLabel = UILabel(frame: CGRect(x: 2, y: 30, width: self.frame.size.width, height: 40))
        distanceLabel?.textColor = UIColor.white
        distanceLabel?.numberOfLines = 1
        distanceLabel?.font = UIFont.systemFont(ofSize: 12)
        distanceLabel?.layer.cornerRadius = 5
        self.addSubview(distanceLabel!)
        
        if let annotation = annotation as? Place {
            titleLabel?.text = annotation.placeName
            
            if (annotation.desc).contains("Ponto de Apoio") {
                imageLabel?.image = UIImage(named: "icones/house.png")
            } else if (annotation.desc).contains("Sirene") {
                imageLabel?.image = UIImage(named: "icones/sirene_nova.png")
            }
            
            if annotation.distanceFromUser > 1000 {
                distanceLabel?.text = "Está a " + String(format: "%.0f km", annotation.distanceFromUser/1000) + " de você"
            } else {
                distanceLabel?.text = "Está a " + String(format: "%.1f m", annotation.distanceFromUser) + " de você"
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        titleLabel?.frame = CGRect(x: 2, y: 0, width: self.frame.size.width, height: 30)
        distanceLabel?.frame = CGRect(x: 2, y: 30, width: self.frame.size.width, height: 40)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        delegate?.didTouch(annotationView: self)
    }
}

