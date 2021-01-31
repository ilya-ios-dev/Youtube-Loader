//
//  MainScreenAlbumCollectionViewCell.swift
//  Youtube Loader
//
//  Created by isEmpty on 19.01.2021.
//

import UIKit

final class AlbumCollectionViewCell: UICollectionViewCell {

    //MARK: - Outlets
    @IBOutlet private weak var backgroundImageView: UIImageView!
    @IBOutlet private weak var visualEffectView: UIVisualEffectView!
    @IBOutlet private weak var albumImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        configureBlur()
        contentView.backgroundColor = #colorLiteral(red: 0.937254902, green: 0.9568627451, blue: 0.9921568627, alpha: 1)
    }

    public func configure(title: String?, imageUrl: URL?) {
        titleLabel.text = title
        if let url = imageUrl {
            albumImageView.af.setImage(withURL: url, placeholderImage: #imageLiteral(resourceName: "vinyl_record"))
            backgroundImageView.af.setImage(withURL: url, placeholderImage: #imageLiteral(resourceName: "vinyl_record"))
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
