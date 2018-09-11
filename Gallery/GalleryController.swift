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

    private let collectionView: UICollectionView = {
        let layout = GalleryCollectionViewLayout()
        layout.scrollDirection = .vertical
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
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.bounds.size
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return .leastNonzeroMagnitude
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return .leastNonzeroMagnitude
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
    public var pageSpacing: CGFloat = 20
    
    public override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let attributes = super.layoutAttributesForElements(in: rect) else { return nil }
        return attributes.map { transformLayoutAttributes($0) }
    }
    
    public override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        // We have to return true here so that the layout attributes would be recalculated
        // everytime we scroll the collection view.
        return collectionView!.bounds != newBounds
    }
    
    private func transformLayoutAttributes(_ attributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        guard let collectionView = collectionView else { return attributes }
        
        // The ratio of the distance between the **start** of the cell and the end of the collectionView and the height/width of the cell depending on the scrollDirection. It's 0 when the **start** of the cell aligns the end of the collectionView. It gets positive when the cell moves towards the scrolling direction (right/down) while getting negative when moves opposite.
        let endOffsetRatio = (attributes.frame.origin.x - collectionView.contentOffset.x - collectionView.frame.width) / attributes.frame.width
        if endOffsetRatio < 0 && endOffsetRatio > -1 {
            if scrollDirection == .horizontal {
                attributes.transform = CGAffineTransform(translationX: (1 - pow(abs(endOffsetRatio), 3.0)) * pageSpacing, y: 0)
            } else {
                attributes.transform = CGAffineTransform(translationX: 0, y: (1 - pow(abs(endOffsetRatio), 3.0)) * pageSpacing)
            }
            attributes.alpha = 1.0 * abs(endOffsetRatio)
        } else {
            attributes.transform = .identity
            attributes.alpha = 1.0
        }
        return attributes
    }
}
