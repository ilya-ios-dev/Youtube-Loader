//
//  ArtistCollectionViewCell.swift
//  Youtube Loader
//
//  Created by isEmpty on 19.01.2021.
//

import UIKit

final class ArtistCollectionViewCell: UICollectionViewCell {

    //MARK: - Outlets
    @IBOutlet private weak var backgroundImageView: UIImageView!
    @IBOutlet private weak var visualEffectView: UIVisualEffectView!
    @IBOutlet private weak var artistImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()

        configureBlur()
        backgroundImageView.layer.cornerRadius = backgroundImageView.frame.height / 2
        artistImageView.layer.cornerRadius = artistImageView.frame.height / 2
        contentView.backgroundColor = Colors.backgorundColor
    }

    public func configure(title: String?, url: URL?) {
        titleLabel.text = title
        if let url = url {
            artistImageView.af.setImage(withURL: url, placeholderImage: Images.artist_placeholder)
            backgroundImageView.af.setImage(withURL: url, placeholderImage: Images.artist_placeholder)
        }
    }
    
    /// Adjusts the display of the `visualEffectBlur` to look like a shadow.
    private func configureBlur() {
        DispatchQueue.main.async {
            let maskLayer = CAGradientLayer()
            maskLayer.frame = self.visualEffectView.bounds
            maskLayer.shadowRadius = 8
            maskLayer.shadowPath = CGPath(ellipseIn: self.visualEffectView.bounds.insetBy(dx: 10, dy: 30), transform: nil)
            maskLayer.shadowOpacity = 1
            maskLayer.shadowOffset = CGSize.zero
            maskLayer.shadowColor = UIColor.white.cgColor
            self.visualEffectView.layer.mask = maskLayer
        }
    }
}
