//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Eric Sailers on 8/7/16.
//  Copyright © 2016 Expressive Solutions. All rights reserved.
//

import Foundation
import CoreData

class FlickrClient {
    
    // MARK: - HTTPMethod enum
    
    enum HTTPMethod: String {
        case GET, POST, PUT, DELETE
    }
    
    // MARK: Generate BBox string
    
    private func bboxString(latitude: Double, longitude: Double) -> String {
        
        let minimumLon = max(longitude - BBox.halfWidth, BBox.lonRange.0)
        let minimumLat = max(latitude - BBox.halfHeight, BBox.latRange.0)
        let maximumLon = min(longitude + BBox.halfWidth, BBox.lonRange.1)
        let maximumLat = min(latitude + BBox.halfHeight, BBox.latRange.1)
        return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
    }
    
    // MARK: Make request
    
    private func makeRequestForFlickr(url url: NSURL, method: HTTPMethod, body: [String:AnyObject]? = nil, responseHandler: (jsonAsDictionary: [String:AnyObject]?, error: NSError?) -> Void) {
        
        makeRequestAtURL(url, method: method, headers: nil, body: nil) {
            (data, error) in
            
            if let data = data {
                let jsonAsDictionary = try! NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments) as! [String:AnyObject]
                
                if let _ = jsonAsDictionary[JSONResponseKeys.status] as? String {
                    responseHandler(jsonAsDictionary: nil, error: error)
                } else {
                    responseHandler(jsonAsDictionary: jsonAsDictionary, error: nil)
                }
            } else {
                responseHandler(jsonAsDictionary: nil, error: error)
            }
        }
    }
    
    // MARK: Get total pages
    
    func pagesForSearch(searchURL: NSURL, completionHandler: (pages: Int, error: NSError?) -> Void) {
        makeRequestForFlickr(url: searchURL, method: .GET) { (jsonAsDictionary, error) in
            
            guard error == nil else {
                completionHandler(pages: 0, error: error)
                return
            }
            
            if let jsonAsDictionary = jsonAsDictionary,
                let photosDictionary = jsonAsDictionary[JSONResponseKeys.photos] as? [String:AnyObject], let totalPages = photosDictionary[JSONResponseKeys.pages] as? Int {
                completionHandler(pages: totalPages, error: nil)
                return
            }
        }
    }
    
    // MARK: - Requests
    
    private func makeRequestAtURL(url: NSURL, method: HTTPMethod, headers: [String:String]? = nil, body: [String:AnyObject]? = nil, completionHandler: (NSData?, NSError?) -> Void) {
        
        let request = NSMutableURLRequest(URL: url)
        
        if let headers = headers {
            for (key, value) in headers {
                request.addValue(value, forHTTPHeaderField: key)
            }
        }
        
        if let body = body {
            request.HTTPBody = try! NSJSONSerialization.dataWithJSONObject(body, options: NSJSONWritingOptions())
        }
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {
            (data, response, error) in
            
            guard error == nil else {
                return completionHandler(nil, error)
            }
            
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                return completionHandler(nil, error)
            }
            
            completionHandler(data, nil)
        }
        
        task.resume()
    }
    
    // MARK: Get photos at location
    
    func photosAtPin(pin: Pin, context: NSManagedObjectContext, completionHandler: (photos: [Photo]?, error: NSError?) -> Void) {
        
        var parameters: [String:AnyObject] = [
            ParameterKeys.method: ParameterValues.searchMethod,
            ParameterKeys.apiKey: ParameterValues.apiKey,
            ParameterKeys.boundingBox: bboxString(Double(pin.latitude!), longitude: Double(pin.longitude!)),
            ParameterKeys.format: ParameterValues.responseFormat,
            ParameterKeys.noJSONCallback: ParameterValues.disableJSONCallback,
            ParameterKeys.extras: ParameterValues.mediumURL,
            ParameterKeys.perPage: ParameterValues.defaultPerPage,
            ParameterKeys.safeSearch: ParameterValues.useSafeSearch
        ]
        
        let photoSearchURL = urlFromComponents(nil, parameters: parameters)
        
        pagesForSearch(photoSearchURL) {
            (pages, error) in
            
            guard error == nil else {
                completionHandler(photos: nil, error: error)
                return
            }
            
            parameters[ParameterKeys.page] = Int(arc4random_uniform(UInt32(pages)) + 1)
            let photoSearchURLWithPage = self.urlFromComponents(nil, parameters: parameters)
            
            self.makeRequestForFlickr(url: photoSearchURLWithPage, method: .GET) {
                (jsonAsDictionary, error) in
                
                guard error == nil else {
                    completionHandler(photos: nil, error: error)
                    return
                }
                
                if let jsonAsDictionary = jsonAsDictionary, photosDictionary = jsonAsDictionary[JSONResponseKeys.photos] as? [String:AnyObject], photoArrayOfDictionaries = photosDictionary[JSONResponseKeys.photo] as? [[String:AnyObject]] {
                    let albumSize = 20
                    if photoArrayOfDictionaries.count >= albumSize {
                        let startIndex = Int(arc4random_uniform(UInt32(photoArrayOfDictionaries.count - albumSize)))
                        let sliceOfArrayOfDictionaries = Array(photoArrayOfDictionaries[startIndex..<startIndex + albumSize])
                        completionHandler(photos: Photo.photosFromArrayOfDictionaries(sliceOfArrayOfDictionaries, context: context), error: nil)
                    } else {
                        completionHandler(photos: Photo.photosFromArrayOfDictionaries(photoArrayOfDictionaries, context: context), error: nil)
                    }
                    return
                }
                
                completionHandler(photos: nil, error: error)
            }
        }
    }
    
    // MARK: - Construct URL
    
    private func urlFromComponents(method: String?, withPathExtension: String? = nil, parameters: [String: AnyObject]? = nil) -> NSURL {
        
        let components = NSURLComponents()
        components.scheme = Components.scheme
        components.host = Components.host
        components.path = Components.path + (method ?? "") + (withPathExtension ?? "")
        
        if let parameters = parameters {
            components.queryItems = [NSURLQueryItem]()
            for (key, value) in parameters {
                let queryItem = NSURLQueryItem(name: key, value: "\(value)")
                components.queryItems!.append(queryItem)
            }
        }
        
        return components.URL!
    }
    
    // MARK: Get a photo
    
    func imageDataForPhoto(photo: Photo, completionHandler: (imageData: NSData?, error: NSError?) -> Void) {
        
        let url = NSURL(string: photo.path!)!
        
        makeRequestAtURL(url, method: .GET) {
            (data, error) in

            guard error == nil else {
                completionHandler(imageData: nil, error: error)
                return
            }
            
            completionHandler(imageData: data, error: nil)
        }
    }
    
    // MARK: - Shared Instance
    
    class func sharedInstance() -> FlickrClient {
        
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        
        return Singleton.sharedInstance
    }
}
