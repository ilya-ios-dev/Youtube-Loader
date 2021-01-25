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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        configureBlur()
        playlistImageView.layer.cornerRadius = 8
//        configureImage(image: UIImage(named: "playlist_img_\(Int.random(in: 1...10))"))
    }
    public func configureImage(image: String?) {
        configureImage(image: UIImage(named: image ?? ""))
    }
    
    public func configureImage(image: UIImage?) {
        backgroundImageView.image = image
        playlistImageView.image = image
    }
    
    public func configure(title: String?, image: UIImage?) {
        titleLabel.text = title
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
