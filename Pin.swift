//
//  Pin.swift
//  VirtualTourist
//
//  Created by Eric Sailers on 8/7/16.
//  Copyright © 2016 Expressive Solutions. All rights reserved.
//

import Foundation
import CoreData

class Pin: NSManagedObject {

    // MARK: - Initializer
    
    convenience init(latitude: Double, longitude: Double, context: NSManagedObjectContext) {
        if let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context) {
            self.init(entity: entity, insertIntoManagedObjectContext: context)
            self.latitude = latitude
            self.longitude = longitude
        } else {
            fatalError("Unable to find entity name")
        }
    }
    
    // MARK: Remove photos
    
    func removePhotos(context: NSManagedObjectContext) {
        if let photos = photos {
            for photo in photos {
                context.deleteObject(photo as! NSManagedObject)
            }
        }
    }

}
