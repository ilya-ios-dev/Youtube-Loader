//
//  SongFromDetailTableViewCell.swift
//  Youtube Loader
//
//  Created by isEmpty on 01.02.2021.
//

import UIKit

final class SongFromDetailTableViewCell: UITableViewCell {

    //MARK: - Outlets
    @IBOutlet private weak var visualEffectBlur: UIVisualEffectView!
    @IBOutlet private weak var backgroundBlurImage: UIImageView!
    @IBOutlet private weak var playingImageView: UIImageView!
    @IBOutlet private weak var songImageView: UIImageView!
    @IBOutlet private weak var indexLabel: UILabel!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var contentBackgroundView: UIView!
    
    public func configure(name: String?, author: String?, imageURL: URL?, index: Int) {
        if let url = imageURL {
            backgroundBlurImage.af.setImage(withURL: url)
            songImageView.af.setImage(withURL: url)
        }
        indexLabel.text = String(index)
        titleLabel.text = name
        descriptionLabel.text = author
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        if selected {
            playingImageView.tintColor = songImageView.image?.averageColor?.withLuminosity(0.7)
            UIView.transition(with: playingImageView, duration: 0.325, options: .transitionCrossDissolve) {
                self.playingImageView.isHidden = false
                self.indexLabel.isHidden = true
                self.contentBackgroundView.backgroundColor = .white
            }
        } else {
            playingImageView.isHidden = true
            indexLabel.isHidden = false
            contentBackgroundView.backgroundColor = .clear
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()

        songImageView.layer.cornerRadius = 4
        contentBackgroundView.layer.cornerRadius = 8
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
