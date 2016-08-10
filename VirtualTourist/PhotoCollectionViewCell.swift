//
//  PhotoCollectionViewCell.swift
//  VirtualTourist
//
//  Created by Eric Sailers on 8/5/16.
//  Copyright © 2016 Expressive Solutions. All rights reserved.
//

import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {
    
    // MARK: - Properties
    
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - Configurations
    
    override func awakeFromNib() {
        activityIndicator.color = UIColor.lightGrayColor()
    }
}
