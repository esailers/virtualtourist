//
//  Photo.swift
//  VirtualTourist
//
//  Created by Eric Sailers on 8/7/16.
//  Copyright © 2016 Expressive Solutions. All rights reserved.
//

import UIKit
import CoreData

class Photo: NSManagedObject {
    
    // MARK: - Initializer

    convenience init(dictionary: [String: AnyObject], context: NSManagedObjectContext) {
        if let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context) {
            self.init(entity: entity, insertIntoManagedObjectContext: context)
            self.title = dictionary[FlickrClient.JSONResponseKeys.title] as? String
            self.path = dictionary[FlickrClient.JSONResponseKeys.mediumURL] as? String
        } else {
            fatalError("Unable to find entity name")
        }
    }
    
    // MARK: - Methods
    
    static func photosFromArrayOfDictionaries(dictionaries: [[String:AnyObject]], context: NSManagedObjectContext) -> [Photo] {
        var photos = [Photo]()
        for photoDictionary in dictionaries {
            photos.append(Photo(dictionary: photoDictionary, context: context))
        }
        return photos
    }
    
    func getImage() -> UIImage? {
        guard let imageData = imageData else {
            return nil
        }
        return UIImage(data: imageData)
    }

}
