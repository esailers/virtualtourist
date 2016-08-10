//
//  Pin+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by Eric Sailers on 8/7/16.
//  Copyright © 2016 Expressive Solutions. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Pin {

    @NSManaged var latitude: NSNumber?
    @NSManaged var longitude: NSNumber?
    @NSManaged var photos: NSSet?

}
