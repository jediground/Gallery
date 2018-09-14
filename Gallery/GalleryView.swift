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
    
    func didDismiss(_ galleryView: GalleryView)
}

extension GalleryViewPosterDelegate {
    func galleryView(_ galleryView: GalleryView, didUpdatePageTo index: Int) {}
    func galleryView(_ galleryView: GalleryView, didSingleTappedAt location: CGPoint, `in` cell: GalleryViewCell) {}
    func galleryView(_ galleryView: GalleryView, didLongPressedAt location: CGPoint, `in` cell: GalleryViewCell) {}
    func didDismiss(_ galleryView: GalleryView) {}
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
    
    private let backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    @IBInspectable override open var backgroundColor: UIColor? {
        get {
            return backgroundView.backgroundColor
        }
        set {
            backgroundView.backgroundColor = newValue
        }
    }
    
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
        addSubview(backgroundView)
        backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        backgroundView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
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
        
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(onPan(sender:)))
        panGestureRecognizer.delegate = self
        addGestureRecognizer(panGestureRecognizer)
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

    private var panGestureRecognizer: UIPanGestureRecognizer!
    open var disablePanToDismiss: Bool = false {
        didSet {
            panGestureRecognizer.isEnabled = !disablePanToDismiss
        }
    }
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
            one.scrollView.panGestureRecognizer.require(toFail: panGestureRecognizer)
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
        switch sender.state {
        case .changed:
            let translation = sender.translation(in: self).y
            let ratio = abs(translation / bounds.size.height)
            scrollView.transform = CGAffineTransform(translationX: 0, y: translation)
            backgroundView.alpha = 1 - ratio
        case .ended:
            let velocity = sender.velocity(in: self).y
            let translation = sender.translation(in: self).y
            
            if abs(velocity) > 1000 || abs(translation) > 100 {
                // -∞, -50, 50, +∞
                // if [-∞, -50], MoveUp
                // elif [-50, 50] && translation < 0, MoveUp
                let isMoveUp = velocity < -50 || (abs(velocity) < 50 && translation < 0)
                let movement = isMoveUp ? translation : -translation
                let timeFactor = TimeInterval((bounds.size.height + movement) / bounds.size.height)
                
                UIView.animate(withDuration: timeFactor * 0.3, delay: 0, options: [.curveLinear, .beginFromCurrentState], animations: {
                    self.scrollView.transform = CGAffineTransform(translationX: 0, y: self.bounds.size.height * (isMoveUp ? -1.0 : 1.0))
                    self.backgroundView.alpha = 0
                }, completion: { _ in
                    self.removeFromSuperview()
                    self.delegate?.didDismiss(self)
                })
            } else {
                UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: velocity / 1000.0, options: [.curveEaseInOut, .beginFromCurrentState, .allowUserInteraction], animations: {
                    self.scrollView.transform = .identity
                    self.backgroundView.alpha = 1
                }, completion: { _ in
                })
            }
        default:
            self.scrollView.transform = .identity
            self.backgroundView.alpha = 1
        }
    }
}

extension GalleryView: UIGestureRecognizerDelegate {
    override open func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == panGestureRecognizer {
            let velocity = panGestureRecognizer.velocity(in: panGestureRecognizer.view)
            if fabs(velocity.y) > fabs(velocity.x), let cell = loadedCell(of: currentPage), cell.scrollView.zoomScale == 1.0, !cell.scrollView.isDragging, !cell.scrollView.isDecelerating {
                let contentHeight = cell.scrollView.contentSize.height
                let boundsHeight = cell.scrollView.bounds.size.height
                let offsetY = cell.scrollView.contentOffset.y
                if contentHeight > boundsHeight {
                    if offsetY <= 0 {
                        return velocity.y > 250
                    }
                    if offsetY + boundsHeight >= contentHeight {
                        return velocity.y < -250
                    }
                } else {
                    return true
                }
            }
            return false
        }
        return super.gestureRecognizerShouldBegin(gestureRecognizer)
    }
}
