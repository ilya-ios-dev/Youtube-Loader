//
//  SelectArtistAlbumSongTableViewCell.swift
//  Youtube Loader
//
//  Created by isEmpty on 29.01.2021.
//

import UIKit

final class SelectArtistAlbumSongTableViewCell: UITableViewCell {

    //MARK: - Outlets
    @IBOutlet private weak var visualEffectBlur: UIVisualEffectView!
    @IBOutlet public weak var backgroundBlurImage: UIImageView!
    @IBOutlet public weak var songImageView: UIImageView!
    @IBOutlet public weak var indexLabel: UILabel!
    @IBOutlet public weak var titleLabel: UILabel!
    @IBOutlet public weak var descriptionLabel: UILabel!
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        UIView.animate(withDuration: 0.325) {
            self.contentView.backgroundColor = selected ? .white : .clear
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
