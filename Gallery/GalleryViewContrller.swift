//
//  GalleryViewContrller.swift
//  Gallery
//
//  Created by Shaw on 9/12/18.
//  Copyright © 2018 Shaw. All rights reserved.
//

import UIKit

internal final class GalleryViewContrller: UIViewController {
    @IBOutlet weak var galleryView: GalleryView!
    
    private lazy var data: [UIImage] = {
        let bundlePath = Bundle(for: type(of: self)).path(forResource: "Unsplash", ofType: "bundle")!
        let bundle = Bundle(path: bundlePath)!
        let images = (0...10).map({ UIImage(named: "unsplash-\($0).jpg", in: bundle, compatibleWith: nil) })
        return images.compactMap({ $0 })
    }()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUserInterface()
        setupEventsHandler()
    }
    
    private func setupUserInterface() {
        galleryView.dataSource = self
    }
    
    private func setupEventsHandler() {
    }
}

extension GalleryViewContrller: GalleryViewPosterDataSource {
    var numberOfItems: Int {
        return data.count
    }
    
    func loadCell(at index: Int, forPosterDisplayView view: GalleryViewCell.DisplayView) {
        let image = data[index]
        if view.image != image {
            print("load cell: \(index)")
            view.image = image
        }
    }
}
