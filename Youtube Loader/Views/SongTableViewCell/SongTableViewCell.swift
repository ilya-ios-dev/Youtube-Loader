//
//  SongTableViewCell.swift
//  Youtube Loader
//
//  Created by isEmpty on 12.01.2021.
//

import UIKit

final class SongTableViewCell: UITableViewCell {

    //MARK: - Outlets
    @IBOutlet private weak var detailButton: UIButton!
    @IBOutlet private weak var visualEffectBlur: UIVisualEffectView!
    @IBOutlet public weak var backgroundBlurImage: UIImageView!
    @IBOutlet private weak var playingImageView: UIImageView!
    
    @IBOutlet public weak var songImageView: UIImageView!
    @IBOutlet public weak var indexLabel: UILabel!
    @IBOutlet public weak var titleLabel: UILabel!
    @IBOutlet public weak var descriptionLabel: UILabel!
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        if selected {
            playingImageView.tintColor = songImageView.image?.averageColor?.withLuminosity(0.7)
            UIView.transition(with: playingImageView, duration: 0.325, options: .transitionCrossDissolve) {
                self.playingImageView.isHidden = false
                self.indexLabel.isHidden = true
                self.contentView.backgroundColor = .white
            }
        } else {
            playingImageView.isHidden = true
            indexLabel.isHidden = false
            contentView.backgroundColor = .clear
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()

        songImageView.layer.cornerRadius = 4
        contentView.layer.cornerRadius = 8
        configureBlur()
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
