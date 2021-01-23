//
//  MainScreenSongCollectionViewCell.swift
//  Youtube Loader
//
//  Created by isEmpty on 19.01.2021.
//

import UIKit

final class SongCollectionViewCell: UICollectionViewCell {

    //MARK: - Outlets
    @IBOutlet private weak var backgorundView: UIView!
    @IBOutlet public weak var songBackgroundImageView: UIImageView!
    @IBOutlet public weak var songImageView: UIImageView!
    @IBOutlet private weak var visualEffectBlur: UIVisualEffectView!
    @IBOutlet private weak var playPauseButton: UIButton!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    
    //MARK: - Properties
    public var isPlayed = false
    override func awakeFromNib() {
        super.awakeFromNib()
        songImageView.layer.cornerRadius = 4
        backgorundView.layer.cornerRadius = 8
        configureBlur()
    }
    
    @IBAction private func playOrPauseTapped(_ sender: Any) {
        if isPlayed {
            playPauseButton.setImage(UIImage(systemName: "play.circle.fill"), for: .normal)
        } else {
            playPauseButton.setImage(UIImage(systemName: "pause.circle.fill"), for: .normal)
        }
        isPlayed = !isPlayed
    }
    
    public func configure(title: String?, description: String?, image: UIImage?) {
        titleLabel.text = title
        descriptionLabel.text = description
        songImageView.image = image
        songBackgroundImageView.image = image
    }
    
    /// Adjusts the display of the `visualEffectBlur` to look like a shadow.
    private func configureBlur() {
        let maskLayer = CAGradientLayer()
        maskLayer.frame = visualEffectBlur.bounds
        maskLayer.shadowRadius = 5
        maskLayer.shadowPath = CGPath(roundedRect: visualEffectBlur.bounds.insetBy(dx: 8, dy: 8), cornerWidth: 10, cornerHeight: 10, transform: nil)
        maskLayer.shadowOpacity = 1
        maskLayer.shadowOffset = CGSize.zero
        maskLayer.shadowColor = UIColor.white.cgColor
        visualEffectBlur.layer.mask = maskLayer
    }
}
