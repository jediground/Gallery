//
//  GalleryView.swift
//  Gallery
//
//  Created by Shaw on 9/12/18.
//  Copyright © 2018 Shaw. All rights reserved.
//

import UIKit

public protocol GalleryViewPosterDataSource: class {
    func numberOfElements(in galleryView: GalleryView) -> Int
    /// In one transcation may invoke this methods multiple times with same indexed cell.
    func galleryView(_ galleryView: GalleryView, loadContentsFor cell: GalleryViewCell)
}

public protocol GalleryViewPosterDelegate: class {
    func galleryView(_ galleryView: GalleryView, didUpdatePageTo index: Int)
    func galleryView(_ galleryView: GalleryView, didSingleTappedAt location: CGPoint, `in` cell: GalleryViewCell)
    func galleryView(_ galleryView: GalleryView, didLongPressedAt location: CGPoint, `in` cell: GalleryViewCell)
}

extension GalleryViewPosterDelegate {
    func galleryView(_ galleryView: GalleryView, didUpdatePageTo index: Int) {}
    func galleryView(_ galleryView: GalleryView, didSingleTappedAt location: CGPoint, `in` cell: GalleryViewCell) {}
    func galleryView(_ galleryView: GalleryView, didLongPressedAt location: CGPoint, `in` cell: GalleryViewCell) {}
}

open class GalleryView: UIView {
    @IBInspectable open var pageSpacing: CGFloat = 20 {
        didSet {
            scrollViewWidthAnchor.constant = pageSpacing
            setNeedsUpdateConstraints()
        }
    }
    
    open private(set) var currentPage: Int = 0 {
        didSet {
            if oldValue != currentPage {
                delegate?.galleryView(self, didUpdatePageTo: currentPage)
            }
        }
    }
    
    open weak var dataSource: GalleryViewPosterDataSource? {
        didSet {
            reloadData()
        }
    }
    
    open weak var delegate: GalleryViewPosterDelegate?
    
    private let scrollView: UIScrollView = {
        let view = UIScrollView(frame: .zero)
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
        view.delaysContentTouches = false
        view.canCancelContentTouches = true
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
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        reloadData()
    }
    
    private func setup() {
        backgroundColor = .black
        
        scrollView.delegate = self
        addSubview(scrollView)
        scrollView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        scrollView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        scrollView.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        scrollViewWidthAnchor = scrollView.widthAnchor.constraint(equalTo: widthAnchor, constant: pageSpacing)
        scrollViewWidthAnchor.isActive = true
        
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(onSingleTap(sender:)))
        addGestureRecognizer(singleTap)
        
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(onDoubleTap(sender:)))
        doubleTap.numberOfTapsRequired = 2
        singleTap.require(toFail: doubleTap)
        addGestureRecognizer(doubleTap)
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(onLongPress(sender:)))
        addGestureRecognizer(longPress)
        
//        let pan = UIPanGestureRecognizer(target: self, action: #selector(onPan(sender:)))
//        addGestureRecognizer(pan)
    }
    
    private func reloadData() {
        guard let dataSource = dataSource else { return }
        
        let itemWidth = scrollView.bounds.width
        let itemHeight = scrollView.bounds.height
        guard itemWidth > 0 && itemHeight > 0 else { return }
        let numberOfItems = dataSource.numberOfElements(in: self)
        
        scrollView.alwaysBounceHorizontal = numberOfItems > 0
        scrollView.contentSize = CGSize(width: CGFloat(numberOfItems) * itemWidth, height: itemHeight)
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
        let numberOfItems = dataSource.numberOfElements(in: self)
        assert(numberOfItems >= 0, "Fatal Error: `numberOfItems` should >= 0.")
        
        for index in range where index >= 0 && index < numberOfItems {
            let cell = acquireCell(for: index)
            if cell.reusable {
                cell.reusable = false
                dataSource.galleryView(self, loadContentsFor: cell)
            }
        }
        
        currentPage = page
    }
    
    private func markCellAsReusableIfNeeded() {
        reusableCells.lazy.filter({ !$0.reusable }).forEach { cell in
            let offset = scrollView.contentOffset.x
            let width = scrollView.bounds.width
            if cell.frame.minX > offset + 2.0 * width || cell.frame.maxX < offset - width {
                cell.reusable = true
                cell.index = -1
            }
        }
    }
    
    private func acquireCell(`for` index: Int) -> GalleryViewCell {
        return loadedCell(of: index) ?? dequeueReusableCell(for: index)
    }
    
    private func loadedCell(of index: Int) -> GalleryViewCell? {
        return reusableCells.lazy.filter({ $0.index == index }).first
    }
    
    private func dequeueReusableCell(`for` index: Int) -> GalleryViewCell {
        let one: GalleryViewCell = reusableCells.lazy.filter({ $0.reusable }).first ?? GalleryViewCell()
        var rect = bounds
        rect.origin.x = rect.size.width * CGFloat(index) + pageSpacing * (CGFloat(index) + 0.5)
        one.frame = rect
        one.index = index
        if nil == one.superview {
            scrollView.addSubview(one)
            reusableCells.append(one)
        }
        return one
    }
}

// MARK: - Gestures

private extension GalleryView {
    @objc private func onSingleTap(sender: UITapGestureRecognizer) {
        guard sender.state == .ended, let cell = loadedCell(of: currentPage), let delegate = delegate else { return }
        let touchPoint = sender.location(in: cell)
        delegate.galleryView(self, didSingleTappedAt: touchPoint, in: cell)
    }
    
    @objc private func onDoubleTap(sender: UITapGestureRecognizer) {
        guard sender.state == .ended, let cell = loadedCell(of: currentPage) else { return }
        cell.onDoubleTap(sender: sender)
    }
    
    @objc private func onLongPress(sender: UILongPressGestureRecognizer) {
        guard sender.state == .ended, let cell = loadedCell(of: currentPage), let delegate = delegate else { return }
        let touchPoint = sender.location(in: cell)
        delegate.galleryView(self, didLongPressedAt: touchPoint, in: cell)
    }
    
    @objc private func onPan(sender: UIPanGestureRecognizer) {
        print("\(NSString(string: #file).lastPathComponent):\(#line):\(String(describing: self)):\(#function)...")
    }
}
