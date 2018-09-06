//
//  GalleryController.swift
//  Gallery
//
//  Created by Shaw on 9/6/18.
//  Copyright © 2018 Shaw. All rights reserved.
//

import UIKit

final class GalleryController: UIViewController {
    private lazy var data: [UIImage] = {
        let bundlePath = Bundle(for: type(of: self)).path(forResource: "Unsplash", ofType: "bundle")!
        let bundle = Bundle(path: bundlePath)!
        let images = (0...10).map({ UIImage(named: "unsplash-\($0).jpg", in: bundle, compatibleWith: nil) })
        return images.compactMap({ $0 })
    }()
    
    let colors: [UIColor] = {
        let dd = (0...10).map({ _ in UIColor.any })
        return dd
    }()
    
    private let collectionView: UICollectionView = {
        let layout = GalleryCollectionViewLayout()
        layout.scrollDirection = .horizontal
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.showsHorizontalScrollIndicator = false
        view.showsVerticalScrollIndicator = false
        view.alwaysBounceVertical = false
        view.alwaysBounceHorizontal = false
        view.bounces = true
        view.bouncesZoom = true
        view.isPagingEnabled = true
        view.clipsToBounds = true
        view.contentInsetAdjustmentBehavior = .never
        view.scrollsToTop = false
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        collectionView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        collectionView.register(GalleryCell.self, forCellWithReuseIdentifier: GalleryCell.identifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.reloadData()
    }
}

// MARK: - DataSource & Delegate

extension GalleryController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GalleryCell.identifier, for: indexPath) as! GalleryCell
        cell.populate(data[indexPath.item])
        cell.contentView.backgroundColor = colors[indexPath.item]
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.bounds.size
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }
}

// MARK: - Cell

final class GalleryCell: UICollectionViewCell {
    public static let identifier: String = "GalleryCell"
    private let posterView = PosterView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        clipsToBounds = true
        contentView.addSubview(posterView)
        posterView.translatesAutoresizingMaskIntoConstraints = false
        posterView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        posterView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        posterView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        posterView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
    }
    
    func populate(_ image: UIImage) {
        posterView.image = image
    }
}

// MARK: - Layout

// See: https://github.com/KelvinJin/AnimatedCollectionViewLayout
final class GalleryCollectionViewLayout: UICollectionViewFlowLayout {
    
    /// The animator that would actually handle the transitions.
    public var animator = ParallaxAttributesAnimator()
    
    /// Overrided so that we can store extra information in the layout attributes.
    public override class var layoutAttributesClass: AnyClass { return GalleryCollectionViewLayoutAttributes.self }
    
    public override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let attributes = super.layoutAttributesForElements(in: rect) else { return nil }
        return attributes.compactMap { $0.copy() as? GalleryCollectionViewLayoutAttributes }.map { transformLayoutAttributes($0) }
    }
    
    public override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        // We have to return true here so that the layout attributes would be recalculated
        // everytime we scroll the collection view.
        return true
    }
    
    private func transformLayoutAttributes(_ attributes: GalleryCollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        guard let collectionView = collectionView else { return attributes }
        
        let oneAttributes = attributes
        let distance: CGFloat
        let itemOffset: CGFloat
        
        if scrollDirection == .horizontal {
            distance = collectionView.frame.width
            itemOffset = oneAttributes.center.x - collectionView.contentOffset.x
            oneAttributes.startOffset = (oneAttributes.frame.origin.x - collectionView.contentOffset.x) / oneAttributes.frame.width
            oneAttributes.endOffset = (oneAttributes.frame.origin.x - collectionView.contentOffset.x - collectionView.frame.width) / oneAttributes.frame.width
        } else {
            distance = collectionView.frame.height
            itemOffset = oneAttributes.center.y - collectionView.contentOffset.y
            oneAttributes.startOffset = (oneAttributes.frame.origin.y - collectionView.contentOffset.y) / oneAttributes.frame.height
            oneAttributes.endOffset = (oneAttributes.frame.origin.y - collectionView.contentOffset.y - collectionView.frame.height) / oneAttributes.frame.height
        }
        
        oneAttributes.scrollDirection = scrollDirection
        oneAttributes.middleOffset = itemOffset / distance - 0.5
        
        // Cache the contentView since we're going to use it a lot.
        if oneAttributes.contentView == nil,
            let c = collectionView.cellForItem(at: attributes.indexPath)?.contentView {
            oneAttributes.contentView = c
        }
        
        animator.animate(collectionView: collectionView, attributes: oneAttributes)
        
        return oneAttributes
    }
}

final class GalleryCollectionViewLayoutAttributes: UICollectionViewLayoutAttributes {
    public var contentView: UIView?
    public var scrollDirection: UICollectionViewScrollDirection = .vertical
    
    public var startOffset: CGFloat = 0
    public var middleOffset: CGFloat = 0
    public var endOffset: CGFloat = 0
    
    public override func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! GalleryCollectionViewLayoutAttributes
        copy.contentView = contentView
        copy.scrollDirection = scrollDirection
        copy.startOffset = startOffset
        copy.middleOffset = middleOffset
        copy.endOffset = endOffset
        return copy
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let o = object as? GalleryCollectionViewLayoutAttributes else { return false }
        
        return super.isEqual(o)
            && o.contentView == contentView
            && o.scrollDirection == scrollDirection
            && o.startOffset == startOffset
            && o.middleOffset == middleOffset
            && o.endOffset == endOffset
    }
}

public struct ParallaxAttributesAnimator {
    /// The higher the speed is, the more obvious the parallax.
    /// It's recommended to be in range [0, 1] where 0 means no parallax. 0.5 by default.
    public var speed: CGFloat
    
    public init(speed: CGFloat = 0.5) {
        self.speed = speed
    }
    
    func animate(collectionView: UICollectionView, attributes: GalleryCollectionViewLayoutAttributes) {
        let position = attributes.middleOffset
        let direction = attributes.scrollDirection
        
        guard let contentView = attributes.contentView else { return }
        
        if abs(position) >= 1 {
            // Reset views that are invisible.
            contentView.frame = attributes.bounds
        } else if direction == .horizontal {
            let width = collectionView.frame.width
            let transitionX = -(width * speed * position)
            let transform = CGAffineTransform(translationX: transitionX, y: 0)
            let newFrame = attributes.bounds.applying(transform)
            
            contentView.frame = newFrame
        } else {
            let height = collectionView.frame.height
            let transitionY = -(height * speed * position)
            let transform = CGAffineTransform(translationX: 0, y: transitionY)
            
            // By default, the content view takes all space in the cell
            let newFrame = attributes.bounds.applying(transform)
            
            // We don't use transform here since there's an issue if layoutSubviews is called
            // for every cell due to layout changes in binding method.
            contentView.frame = newFrame
        }
    }
}
