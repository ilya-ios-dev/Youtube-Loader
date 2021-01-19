//
//  PlaylistCollectionViewCell.swift
//  Youtube Loader
//
//  Created by isEmpty on 19.01.2021.
//

import UIKit

final class PlaylistCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var visualEffectView: UIVisualEffectView!
    @IBOutlet weak var playlistImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        configureBlur()
        playlistImageView.layer.cornerRadius = 8
    }

    public func configure(title: String?, description: String?, image: UIImage?) {
        titleLabel.text = title
        descriptionLabel.text = description
        playlistImageView.image = image
        backgroundImageView.image = image
    }
    
    /// Adjusts the display of the `visualEffectBlur` to look like a shadow.
    private func configureBlur() {
        DispatchQueue.main.async { [self] in
            let maskLayer = CAGradientLayer()
            maskLayer.frame = visualEffectView.bounds
            maskLayer.shadowRadius = 8
            maskLayer.shadowPath = CGPath(rect: visualEffectView.bounds.insetBy(dx: 10, dy: 30), transform: nil)
            maskLayer.shadowOpacity = 1
            maskLayer.shadowOffset = CGSize.zero
            maskLayer.shadowColor = UIColor.white.cgColor
            visualEffectView.layer.mask = maskLayer

        }
    }
}
