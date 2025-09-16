//
//  StoreAnnotatin .swift
//  GC
//
//  Created by Candido Bugarin on 10/06/17.
//  Copyright © 2017 Candido Bugarin. All rights reserved.
//

import UIKit
import MapKit

class StoreAnnotation: NSObject, MKAnnotation {
    
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    var eta: String?
    
    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }
}
