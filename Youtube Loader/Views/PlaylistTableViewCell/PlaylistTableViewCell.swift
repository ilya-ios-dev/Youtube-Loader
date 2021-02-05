//
//  PlaylistTableViewCell.swift
//  Youtube Loader
//
//  Created by isEmpty on 02.02.2021.
//

import UIKit

/// A table view cell that specializes in displaying a playlist in `AddToPlaylistViewController`.
final class PlaylistTableViewCell: UITableViewCell {
    
    //MARK: - Outlets
    @IBOutlet private weak var visualEffectBlur: UIVisualEffectView!
    @IBOutlet private weak var backgroundBlurImage: UIImageView!
    @IBOutlet private weak var songImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var songCountLabel: UILabel!
    
    public func configure(name: String?, songsCount: Int?, imageURL: URL?) {
        if let url = imageURL {
            backgroundBlurImage.af.setImage(withURL: url, placeholderImage: Images.vinyl_record)
            songImageView.af.setImage(withURL: url, placeholderImage: Images.vinyl_record)
        }
        titleLabel.text = name
        
        songCountLabel.text = "\(songsCount ?? 0) \(songsCount == 1 ? "Track" : "Tracks")"
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        if selected {
            UIView.transition(with: contentView, duration: 0.325, options: .transitionCrossDissolve) {
                self.contentView.backgroundColor = .white
            }
        } else {
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
