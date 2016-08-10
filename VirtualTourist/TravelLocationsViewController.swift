//
//  TravelLocationsViewController.swift
//  VirtualTourist
//
//  Created by Eric Sailers on 8/5/16.
//  Copyright © 2016 Expressive Solutions. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsViewController: UIViewController, MKMapViewDelegate {
    
    // MARK: - Properties
    
    var editBarButton: UIBarButtonItem!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var editPinsLabel: UILabel!
    var longPressGestureRecognizer: UILongPressGestureRecognizer!
    var pin: Pin!
    
    // MARK: - UIViewController lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self

        editBarButton = UIBarButtonItem(title: "Edit", style: .Plain, target: self, action: #selector(self.editPins(_:)))
        navigationItem.rightBarButtonItem = editBarButton
        
        editPinsLabel.hidden = true
        
        loadAnnotations()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressRecognized(_:)))
        mapView.addGestureRecognizer(longPressGestureRecognizer)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillAppear(animated)
        
        mapView.removeGestureRecognizer(longPressGestureRecognizer)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Actions
    
    func editPins(sender: UIBarButtonItem) {
        if editing {
            editBarButton.title = "Edit"
            editPinsLabel.hidden = true
            self.setEditing(false, animated: true)
        } else {
            editBarButton.title = "Done"
            editPinsLabel.hidden = false
            self.setEditing(true, animated: true)
        }
    }
    
    func longPressRecognized(longPress: UIGestureRecognizer) {
        
        if !editing {
            let location = longPress.locationInView(mapView)
            let locationCoordinate = mapView.convertPoint(location, toCoordinateFromView: mapView)
            let pin = Pin(latitude: locationCoordinate.latitude, longitude: locationCoordinate.longitude, context: CoreDataStackManager.sharedInstance().managedObjectContext)
            let pinAnnotation = PinAnnotation(objectID: pin.objectID, title: nil, subtitle: nil, coordinate: locationCoordinate)
            mapView.addAnnotation(pinAnnotation)
        }
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    // MARK: Add Annotations
    
    func loadAnnotations() {
        
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        do {
            if let pins = try? CoreDataStackManager.sharedInstance().managedObjectContext.executeFetchRequest(fetchRequest) as! [Pin] {
                var pinAnnotations = [PinAnnotation]()
                
                for pin in pins {
                    let latitude = CLLocationDegrees(pin.latitude!)
                    let longitude = CLLocationDegrees(pin.longitude!)
                    let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    pinAnnotations.append(PinAnnotation(objectID: pin.objectID, title: nil, subtitle: nil, coordinate: coordinate))
                }
                
                mapView.addAnnotations(pinAnnotations)
            }
        }
    }
    
    // MARK: - MapViewDelegate
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        mapView.deselectAnnotation(view.annotation, animated: false)
        
        do {
            let pinAnnotation = view.annotation as! PinAnnotation
            let fetchRequest = NSFetchRequest(entityName: "Pin")
            let predicate = NSPredicate(format: "latitude == %@ AND longitude == %@", argumentArray: [pinAnnotation.coordinate.latitude, pinAnnotation.coordinate.longitude])
            fetchRequest.predicate = predicate
            let pins = try CoreDataStackManager.sharedInstance().managedObjectContext.executeFetchRequest(fetchRequest) as? [Pin]
            pin = pins![0]
        } catch let error as NSError {
            print("failed to get pin by object id")
            print(error.localizedDescription)
            return
        }
        
        if editing {
            mapView.removeAnnotation(view.annotation!)
            CoreDataStackManager.sharedInstance().managedObjectContext.deleteObject(pin)
            CoreDataStackManager.sharedInstance().saveContext()
            return
        } else {
            performSegueWithIdentifier(StoryboardSegue.kSegueToPhotoAlbum, sender: self)
        }
        
    }
    
    // MARK: - Navigation
    
    private struct StoryboardSegue {
        static let kSegueToPhotoAlbum = "segueToPhotoAlbum"
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == StoryboardSegue.kSegueToPhotoAlbum {
            if let photoAlbumViewController = segue.destinationViewController as? PhotoAlbumViewController {
                photoAlbumViewController.mapView = mapView
                photoAlbumViewController.pin = pin
                if let photos = pin!.photos?.allObjects as? [Photo] {
                    photoAlbumViewController.photos = photos
                }
            }
        }
    }
    

}
