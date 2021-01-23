//
//  ArtistCollectionViewCell.swift
//  Youtube Loader
//
//  Created by isEmpty on 19.01.2021.
//

import UIKit

final class ArtistCollectionViewCell: UICollectionViewCell {

    //MARK: - Outlets
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var visualEffectView: UIVisualEffectView!
    @IBOutlet weak var artistImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        configureBlur()
        backgroundImageView.layer.cornerRadius = backgroundImageView.frame.height / 2
        artistImageView.layer.cornerRadius = artistImageView.frame.height / 2
    }

    public func configure(title: String?, url: URL?) {
        titleLabel.text = title
        if let url = url {
            artistImageView.af.setImage(withURL: url)
            backgroundImageView.af.setImage(withURL: url)
        }
    }
    
    /// Adjusts the display of the `visualEffectBlur` to look like a shadow.
    private func configureBlur() {
        DispatchQueue.main.async { [self] in
            let maskLayer = CAGradientLayer()
            maskLayer.frame = visualEffectView.bounds
            maskLayer.shadowRadius = 8
            maskLayer.shadowPath = CGPath(ellipseIn: visualEffectView.bounds.insetBy(dx: 10, dy: 30), transform: nil)
            maskLayer.shadowOpacity = 1
            maskLayer.shadowOffset = CGSize.zero
            maskLayer.shadowColor = UIColor.white.cgColor
            visualEffectView.layer.mask = maskLayer

        }
    }
}
