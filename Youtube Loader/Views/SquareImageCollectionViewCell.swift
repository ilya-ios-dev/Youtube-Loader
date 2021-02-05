//
//  SquareImageCollectionViewCell.swift
//  Youtube Loader
//
//  Created by isEmpty on 26.01.2021.
//

import UIKit

/// A collection view cell that specializes in displaying a sqare image.
final class SquareImageCollectionViewCell: UICollectionViewCell {
    
    public var imageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureCell()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureCell()
    }
    
    private func configureCell() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 6
        contentView.addSubview(imageView)
        imageView.fillSuperview()
    }
}
