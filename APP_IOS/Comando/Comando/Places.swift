//
//  Places.swift
//  GC
//
//  Created by Candido Bugarin on 10/06/17.
//  Copyright © 2017 Candido Bugarin. All rights reserved.
//

import Foundation
import CoreLocation

class Place: ARAnnotation {
    let placeName: String
    let desc: String
    
    
    init?(location: CLLocation, name: String, desc: String) {
        placeName = name
        self.desc = desc
        
        super.init(identifier: nil, title: name, location: location)
        self.location = location
    }
    
    override var description: String {
        return placeName
    }
}
