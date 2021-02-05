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
    @IBOutlet private weak var songBackgroundImageView: UIImageView!
    @IBOutlet private weak var songImageView: UIImageView!
    @IBOutlet private weak var visualEffectBlur: UIVisualEffectView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var playImageView: UIImageView!
    
    //MARK: - Properties
    override func awakeFromNib() {
        super.awakeFromNib()
        songImageView.layer.cornerRadius = 5
        songImageView.clipsToBounds = true
        songBackgroundImageView.layer.cornerRadius = 5
        songBackgroundImageView.clipsToBounds = true
        backgorundView.layer.cornerRadius = 8
    }
    
    override var isSelected: Bool {
        didSet {
            if isSelected {
                UIView.transition(with: playImageView, duration: 0.325, options: .transitionCrossDissolve) {
                    self.playImageView.image = UIImage(named: "playing")
                }
                
            } else {
                UIView.transition(with: playImageView, duration: 0.325, options: .transitionCrossDissolve) {
                    self.playImageView.image = UIImage(systemName: "play.circle.fill")
                }
            }
        }
    }
    
    public func configure(title: String?, description: String?, imageURL: URL?) {
        if let url = imageURL {
            songImageView.af.setImage(withURL: url, placeholderImage: Images.music_placeholder)
            songBackgroundImageView.af.setImage(withURL: url, placeholderImage: Images.music_placeholder)
        }
        
        titleLabel.text = title
        descriptionLabel.text = description
    }
    
    /// Adjusts the display of the `visualEffectBlur` to look like a shadow.
    private func configureBlur() {
        let maskLayer = CAGradientLayer()
        maskLayer.frame = visualEffectBlur.bounds
        maskLayer.shadowRadius = 5
        maskLayer.shadowPath = CGPath(roundedRect: visualEffectBlur.bounds.insetBy(dx: 12, dy: 12), cornerWidth: 8, cornerHeight: 8, transform: nil)
        maskLayer.shadowOpacity = 1
        maskLayer.shadowOffset = CGSize(width: 0, height: 5)
        maskLayer.shadowColor = UIColor.white.cgColor
        visualEffectBlur.layer.mask = maskLayer
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        guard visualEffectBlur.layer.mask?.frame != visualEffectBlur.frame else { return }
        configureBlur()
    }
}
