//
//  GalleryView.swift
//  Gallery
//
//  Created by Shaw on 9/12/18.
//  Copyright © 2018 Shaw. All rights reserved.
//

import UIKit

public protocol GalleryViewPosterDataSource: class {
    var numberOfItems: Int { get }
    /// In one transcation same index may call multipe times.
    func loadCell(at index: Int, forPosterDisplayView view: GalleryViewCell.DisplayView)
}

open class GalleryView: UIView {
    @IBInspectable open var pageSpacing: CGFloat = 20 {
        didSet {
            scrollViewWidthAnchor.constant = pageSpacing
            setNeedsUpdateConstraints()
        }
    }
    
    open var currentPage: Int = 0 {
        didSet {
            
        }
    }
    
    private class GalleryInnerScrollView: UIScrollView {
        private var loaded: Bool = false
        open override var bounds: CGRect {
            didSet {
                if !loaded && bounds.size != .zero {
                    loaded = true
                    (superview as? GalleryView)?.reload()
                }
            }
        }
    }
    
    private let scrollView: UIScrollView = {
        let view = GalleryInnerScrollView(frame: .zero)
        view.clipsToBounds = true
        view.scrollsToTop = false
        view.bounces = true
        view.bouncesZoom = true
        view.alwaysBounceVertical = false
        view.alwaysBounceHorizontal = false
        view.showsVerticalScrollIndicator = false
        view.showsHorizontalScrollIndicator = false
        view.isPagingEnabled = true
        view.contentInsetAdjustmentBehavior = .never
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var scrollViewWidthAnchor: NSLayoutConstraint!
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    open weak var dataSource: GalleryViewPosterDataSource? {
        didSet {
            reload()
        }
    }
    
    private func setup() {
        scrollView.delegate = self
        addSubview(scrollView)
        scrollView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        scrollView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        scrollView.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        scrollViewWidthAnchor = scrollView.widthAnchor.constraint(equalTo: widthAnchor, constant: pageSpacing)
        scrollViewWidthAnchor.isActive = true
        
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap(sender:)))
        addGestureRecognizer(singleTap)
    }
    
    fileprivate func reload() {
        guard let dataSource = dataSource else { return }
        
        let itemWidth = scrollView.bounds.width
        let itemHeight = scrollView.bounds.height
        guard itemWidth > 0 && itemHeight > 0 else { return }
        
        scrollView.contentSize = CGSize(width: CGFloat(dataSource.numberOfItems) * itemWidth, height: itemHeight)
        scrollView.scrollRectToVisible(CGRect(x: itemWidth * CGFloat(currentPage), y: 0, width: itemWidth, height: itemHeight), animated: false)
        scrollViewDidScroll(scrollView)
    }
    
    private var reusableCells: [GalleryViewCell] = []
}

extension GalleryView: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Mark cell as reusable if needed
        markCellAsReusableIfNeeded()
        
        guard let dataSource = dataSource else { return }
        
        // Load preview & next page
        let page = Int(scrollView.contentOffset.x / scrollView.bounds.width)
        let range = page - 1 ... page + 1
        let numberOfItems = dataSource.numberOfItems
        assert(numberOfItems >= 0, "Fatal Error: `numberOfItems` should >= 0.")
        
        for index in range where index >= 0 && index < numberOfItems {
            let cell = acquireCell(for: index)
            if cell.reusable {
                cell.reusable = false
                dataSource.loadCell(at: index, forPosterDisplayView: cell.displayView)
            }
        }
    }
    
    private func markCellAsReusableIfNeeded() {
        reusableCells.lazy.filter({ !$0.reusable }).forEach { cell in
            let offset = scrollView.contentOffset.x
            let width = scrollView.bounds.width
            if cell.frame.minX > offset + 2.0 * width || cell.frame.maxX < offset - width {
                cell.reusable = true
                cell.page = -1
            }
        }
    }
    
    private func acquireCell(`for` index: Int) -> GalleryViewCell {
        return loadedCell(of: index) ?? dequeueReusableCell(for: index)
    }
    
    private func loadedCell(of index: Int) -> GalleryViewCell? {
        return reusableCells.lazy.filter({ $0.page == index }).first
    }
    
    private func dequeueReusableCell(`for` index: Int) -> GalleryViewCell {
        let one: GalleryViewCell = reusableCells.lazy.filter({ $0.reusable }).first ?? GalleryViewCell()
        var rect = bounds
        rect.origin.x = rect.size.width * CGFloat(index) + pageSpacing * (CGFloat(index) + 0.5)
        one.frame = rect
        one.page = index
        if nil == one.superview {
            scrollView.addSubview(one)
            reusableCells.append(one)
        }
        return one
    }
}

private extension GalleryView {
    @objc private func handleSingleTap(sender: UITapGestureRecognizer) {
        
    }
}
