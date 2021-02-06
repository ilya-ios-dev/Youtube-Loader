//
//  MainScreenAlbumCollectionViewCell.swift
//  Youtube Loader
//
//  Created by isEmpty on 19.01.2021.
//

import UIKit

/// A collection view cell that specializes in displaying a album.
final class AlbumCollectionViewCell: UICollectionViewCell {

    //MARK: - Outlets
    @IBOutlet private weak var backgroundImageView: UIImageView!
    @IBOutlet private weak var visualEffectView: UIVisualEffectView!
    @IBOutlet private weak var albumImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        configureBlur()
        albumImageView.layer.cornerRadius = 8
        contentView.backgroundColor = Colors.backgorundColor
    }

    public func configure(title: String?, imageUrl: URL?) {
        titleLabel.text = title
        if let url = imageUrl {
            albumImageView.af.setImage(withURL: url, placeholderImage: Images.vinyl_record)
            backgroundImageView.af.setImage(withURL: url, placeholderImage: Images.vinyl_record)
        }
    }
    
    /// Adjusts the display of the `visualEffectBlur` to look like a shadow.
    private func configureBlur() {
        let maskLayer = CAGradientLayer()
        maskLayer.frame = visualEffectView.bounds
        maskLayer.shadowRadius = 8
        maskLayer.shadowPath = CGPath(rect: visualEffectView.bounds.insetBy(dx: 10, dy: 30), transform: nil)
        maskLayer.shadowOpacity = 1
        maskLayer.shadowOffset = CGSize.zero
        maskLayer.shadowColor = UIColor.white.cgColor
        visualEffectView.layer.mask = maskLayer
        visualEffectView.isHidden = false
        backgroundImageView.isHidden = false
    }
}
