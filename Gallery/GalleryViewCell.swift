//
//  GalleryViewCell.swift
//  Gallery
//
//  Created by Shaw on 9/12/18.
//  Copyright © 2018 Shaw. All rights reserved.
//

import UIKit

open class GalleryViewCell: UIView {
    public typealias DisplayView = UIView & PosterDisplayable
    open static var displayViewClass: DisplayView.Type = UIImageView.self
    
    internal var page: Int = -1
    internal var reusable: Bool = true

    private let scrollView: UIScrollView = {
        let view = UIScrollView(frame: .zero)
        view.bouncesZoom = true
        view.scrollsToTop = true
        view.showsVerticalScrollIndicator = false
        view.showsHorizontalScrollIndicator = false
        view.alwaysBounceHorizontal = false
        view.alwaysBounceVertical = false
        view.isPagingEnabled = false
        view.isMultipleTouchEnabled = true
        view.isUserInteractionEnabled = true
        view.delaysContentTouches = false
        view.clipsToBounds = true
        view.contentInsetAdjustmentBehavior = .never
        view.maximumZoomScale = 3
        view.minimumZoomScale = 1
        return view
    }()
    
    open let displayView: DisplayView = {
        let view = GalleryViewCell.displayViewClass.init()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.isUserInteractionEnabled = false
        return view
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    open override var frame: CGRect {
        didSet {
            layoutContents()
        }
    }

    private func setup() {
        clipsToBounds = true
        
        scrollView.frame = bounds
        scrollView.delegate = self
        addSubview(scrollView)
        
        displayView.frame = bounds
        scrollView.addSubview(displayView)
    }
    
    private func layoutContents() {
        scrollView.zoomScale = 1
        scrollView.frame = bounds
        
        let height: CGFloat
        if let image = displayView.image {
            height = image.size.height * bounds.width / image.size.width
        } else {
            height = bounds.height
        }
        let size = CGSize(width: bounds.width, height: height)
        displayView.frame = CGRect(origin: .zero, size: size)
        scrollView.contentSize = size
        
        centerContents()
    }
    
    private func centerContents() {
        var top: CGFloat = 0, left: CGFloat = 0
        if scrollView.contentSize.height < scrollView.bounds.height {
            top = (scrollView.bounds.height - scrollView.contentSize.height) * 0.5
        }
        if scrollView.contentSize.width < scrollView.bounds.width {
            left = (scrollView.bounds.width - scrollView.contentSize.width) * 0.5
        }
        scrollView.contentInset = UIEdgeInsets(top: top, left: left, bottom: top, right: left)
    }
}

// MARK: - UIScrollViewDelegate

extension GalleryViewCell: UIScrollViewDelegate {
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return displayView
    }
    
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerContents()
    }
}

// MARK: -

public extension GalleryViewCell {
    public var image: UIImage? {
        get {
            return displayView.image
        }
        set {
            let current = CACurrentMediaTime()
            
            displayView.image = newValue
            
            if let image = newValue {
                let iw = image.size.width
                let ih = image.size.height
                let vw = bounds.width
                let vh = bounds.height
                let scale = (ih / iw) / (vh / vw)
                if !scale.isNaN && scale > 1.0 {
                    // image: h > w
                    contentMode = .scaleAspectFill
                    layer.contentsRect = CGRect(x: 0, y: 0, width: 1, height: (iw / ih) * (vh / vw))
                } else {
                    // image: w > h
                    contentMode = .scaleAspectFit
                    layer.contentsRect = CGRect(origin: .zero, size: CGSize(width: 1, height: 1))
                }
            }
            
            if CACurrentMediaTime() - current > 0.2 {
                layer.add(CATransition(), forKey: kCATransition)
            }
            
            layoutContents()
        }
    }
}