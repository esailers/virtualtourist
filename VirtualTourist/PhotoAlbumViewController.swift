//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Eric Sailers on 8/5/16.
//  Copyright © 2016 Expressive Solutions. All rights reserved.
//

import UIKit
import MapKit

class PhotoAlbumViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    // MARK: - Properties
    
    var pin: Pin!
    var photos = [Photo]()
    var selectedIndexes = [NSIndexPath]()
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var noImagesLabel: UILabel!
    @IBOutlet weak var bottomBarButton: UIBarButtonItem!
    
    var itemCount: Int!
    
    // MARK: - UIViewController lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        noImagesLabel.hidden = true

        collectionView.dataSource = self
        collectionView.delegate = self
        
        if let mapView = mapView {
            let mapCenter = CLLocationCoordinate2D(latitude: CLLocationDegrees(pin.latitude!), longitude: CLLocationDegrees(pin.longitude!))
            let mapSpan = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            let mapRegion = MKCoordinateRegionMake(mapCenter, mapSpan)
            mapView.setRegion(mapRegion, animated: true)
            mapView.userInteractionEnabled = false
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = mapCenter
            mapView.addAnnotation(annotation)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        itemCount = photos.count
        
        if itemCount == 0 {
            bottomBarButton.enabled = false
            getNewCollectionOfPhotos()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Actions
    
    @IBAction func bottomBarButtonTapped(sender: UIBarButtonItem) {
        if selectedIndexes.isEmpty {
            pin.removePhotos(CoreDataStackManager.sharedInstance().managedObjectContext)
            photos.removeAll(keepCapacity: true)
            
            collectionView.reloadData()
            
            getNewCollectionOfPhotos()
        } else {
            
            var selectedPhotos = [Photo]()
            
            // http://victorlin.me/posts/2016/04/29/uicollectionview-invalid-number-of-items-crash-issue recommends performBatchUpdates and itemCount to properly update the collectionView
            collectionView.performBatchUpdates ({
                
                let sortedIndexes = self.selectedIndexes.sort {$0.row > $1.row}
                
                for indexPath in sortedIndexes {
                    let photoObject = self.photos[indexPath.row]
                    self.photos.removeAtIndex(indexPath.row)
                    self.collectionView.deleteItemsAtIndexPaths([indexPath])
                    self.itemCount = self.itemCount - 1
                    selectedPhotos.append(photoObject)
                }
                
                }
                , completion: { (completed) in
                    
                    if self.itemCount == 0 {
                        dispatch_async(dispatch_get_main_queue()) {
                            self.noImagesLabel.text = "Album is Empty"
                            self.noImagesLabel.hidden = false
                            CoreDataStackManager.sharedInstance().saveContext()
                        }
                    }
            })
            
            for photo in selectedPhotos {
                CoreDataStackManager.sharedInstance().managedObjectContext.deleteObject(photo)
            }
            
            selectedIndexes = [NSIndexPath]()
            collectionView.reloadData()
            
            setTextForBottomBarButton()
        }
    }
    
    // MARK: - Helpers
    
    private func setTextForBottomBarButton() {
        bottomBarButton.title = selectedIndexes.count > 0 ? "Remove Selected Photos" : "New Collection"
        bottomBarButton.tintColor = bottomBarButton.title == "Remove Selected Photos" ? UIColor.redColor() : UIColor(red: 0, green: 0.48, blue: 1, alpha: 1)
    }
    
    // MARK: - Get Photos
    
    func getNewCollectionOfPhotos() {
        FlickrClient().photosAtPin(pin, context: CoreDataStackManager.sharedInstance().managedObjectContext) {
            (photos, error) in
            
            guard error == nil else {
                print(error)
                return
            }
            
            if let photos = photos {
                for photo in photos {
                    photo.pin = self.pin
                }
                dispatch_async(dispatch_get_main_queue()) {
                    self.photos = photos
                    self.itemCount = self.photos.count
                    CoreDataStackManager.sharedInstance().saveContext()
                }
                dispatch_async(dispatch_get_main_queue()) {
                    if self.itemCount == 0 {
                        self.noImagesLabel.text = "No Images Found"
                        self.noImagesLabel.hidden = false
                    } else {
                        self.noImagesLabel.hidden = true
                    }
                    self.collectionView.reloadData()
                    self.bottomBarButton.enabled = true
                }
            }
        }
    }
    
    // MARK: - UICollectionViewDataSource
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return itemCount
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCell", forIndexPath: indexPath) as! PhotoCollectionViewCell
        let photo = photos[indexPath.row]
        itemCount = photos.count
        
        if let photoImage = photo.getImage() {
            cell.photoImageView.image = photoImage
        } else {
            cell.photoImageView.image = UIImage(named: "placeholder")
            cell.activityIndicator.hidden = false
            cell.activityIndicator.startAnimating()
            
            FlickrClient().imageDataForPhoto(photo) {
                (imageData, error) in
                
                guard error == nil else {
                    return
                }
                
                dispatch_async(dispatch_get_main_queue()) {
                    cell.activityIndicator.hidden = true
                    cell.activityIndicator.stopAnimating()
                    cell.photoImageView.image = UIImage(data: imageData!)
                }
            }
        }
        
        cell.photoImageView.alpha = 1.0
        
        return cell
    }
    
    // MARK: - UICollectionViewDelegate
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCollectionViewCell
        
        if let index = selectedIndexes.indexOf(indexPath) {
            selectedIndexes.removeAtIndex(index)
            cell.photoImageView.alpha = 1.0
        } else {
            selectedIndexes.append(indexPath)
            cell.photoImageView.alpha = 0.3
        }
        
        setTextForBottomBarButton()
    }

}
