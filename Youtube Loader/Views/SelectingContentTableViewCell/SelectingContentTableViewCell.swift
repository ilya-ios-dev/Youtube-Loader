//
//  SelectingContentTableViewCell.swift
//  Youtube Loader
//
//  Created by isEmpty on 29.01.2021.
//

import UIKit

/// A table view cell that specializes in displaying a selected entity in `CreateOrEditContentViewController`.
final class SelectingContentTableViewCell: UITableViewCell {

    //MARK: - Outlets
    @IBOutlet private weak var visualEffectBlur: UIVisualEffectView!
    @IBOutlet private weak var backgroundBlurImage: UIImageView!
    @IBOutlet private weak var songImageView: UIImageView!
    @IBOutlet private weak var indexLabel: UILabel!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    
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
    
    public func configure(name: String?, description: String?, url: URL?, index: Int) {
        if let url = url {
            songImageView.af.setImage(withURL: url, placeholderImage: Images.music_placeholder)
            backgroundBlurImage.af.setImage(withURL: url, placeholderImage: Images.music_placeholder)
        }
        titleLabel.text = name
        descriptionLabel.text = description
        indexLabel.text = String(index)
    }
}
