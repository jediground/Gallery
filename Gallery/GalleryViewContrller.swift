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
        galleryView.delegate = self
    }
    
    private func setupEventsHandler() {
    }
}

extension GalleryViewContrller: GalleryViewPosterDataSource, GalleryViewPosterDelegate {
    func numberOfElements(in galleryView: GalleryView) -> Int {
        return data.count
    }
    
    func galleryView(_ galleryView: GalleryView, loadContentsFor cell: GalleryViewCell) {
        let image = data[cell.index]
        if cell.image != image {
            print("loadContentsFor cell: \(cell.index)")
            cell.image = image
        }
    }
    
    func galleryView(_ galleryView: GalleryView, didUpdatePageTo index: Int) {
        print("didUpdatePageTo: \(index)")
    }
    
    func galleryView(_ galleryView: GalleryView, didSingleTappedAt location: CGPoint, in cell: GalleryViewCell) {
        let rect = cell.convert(cell.displayView.frame, from: cell.displayView)
        print("touchsIndisplayView: \(rect.contains(location))")
    }
    
    func galleryView(_ galleryView: GalleryView, didLongPressedAt location: CGPoint, `in` cell: GalleryViewCell) {
        let rect = cell.convert(cell.displayView.frame, from: cell.displayView)
        print("longPressIndisplayView: \(rect.contains(location))")
    }
}
