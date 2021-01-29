//
//  RecommendationsCollectionViewCell.swift
//  Youtube Loader
//
//  Created by isEmpty on 23.01.2021.
//

import UIKit

protocol RecommendationsCollectionViewCellDelegate: class {
    func downloadTapped(_ cell: RecommendationsCollectionViewCell)
    func cancelTapped(_ cell: RecommendationsCollectionViewCell)
    func pauseTapped(_ cell: RecommendationsCollectionViewCell)
    func resumeTapped(_ cell: RecommendationsCollectionViewCell)
}

final class RecommendationsCollectionViewCell: UICollectionViewCell {
    
    //MARK: - Outlets
    @IBOutlet private weak var backgroundBlurImage: UIImageView!
    @IBOutlet private weak var songImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var pauseOrResumeButton: UIButton!
    @IBOutlet private weak var donwloadOrCancelButton: UIButton!
    @IBOutlet private weak var buttonsStackView: UIStackView!
    @IBOutlet private weak var progressView: UIProgressView!
    @IBOutlet private weak var visualEffectBlur: UIVisualEffectView!
    
    
    //MARK: - Properties
    public weak var delegate: RecommendationsCollectionViewCellDelegate?
    
    private var isPaused = false
    private var isDownloading = false

    //MARK: - Actions
    @IBAction func tapPauseOrResume(_ sender: Any) {
        isPaused ? resume() : pause()
        isPaused = !isPaused
    }
    
    @IBAction func tapDownloadOrCancel(_ sender: Any) {
        isDownloading ? cancel() : download()
        isDownloading = !isDownloading
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        songImageView.layer.cornerRadius = 4
        contentView.layer.cornerRadius = 8
        configureBlur()
    }
}

//MARK: - Supporting Methods
extension RecommendationsCollectionViewCell {
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
    
    private func pause() {
        delegate?.pauseTapped(self)
        pauseOrResumeButton.setImage(UIImage(systemName: "play.circle.fill"), for: .normal)
    }
    
    private func resume() {
        delegate?.resumeTapped(self)
        pauseOrResumeButton.setImage(UIImage(systemName: "pause.circle.fill"), for: .normal)
    }
    
    private func download() {
        delegate?.downloadTapped(self)
        UIView.transition(with: donwloadOrCancelButton, duration: 0.325, options: .transitionCrossDissolve) {
            self.donwloadOrCancelButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
            self.pauseOrResumeButton.isHidden = false
            self.progressView.isHidden = false
        }
    }
    
    private func cancel() {
        delegate?.cancelTapped(self)
        progressView.progress = 0
        UIView.transition(with: donwloadOrCancelButton, duration: 0.325, options: .transitionCrossDissolve) {
            self.donwloadOrCancelButton.setImage(UIImage(systemName: "arrow.down.circle.fill"), for: .normal)
            self.pauseOrResumeButton.isHidden = true
            self.progressView.isHidden = true
        }
    }
    
    //MARK: - Public Methods
    
    /// Adjusts the display of the call based on the provided conditions.
    /// - Parameters:
    ///   - video: The object to be displayed.
    ///   - downloading: Whether the object is currently loading.
    ///   - paused: Whether the object is paused.
    ///   - url: Link to image.
    public func configure(video: Video, downloading: Bool, paused: Bool, url: URL?) {
        if let url = url {
            backgroundBlurImage.af.setImage(withURL: url, placeholderImage: #imageLiteral(resourceName: "music_placeholder"))
            songImageView.af.setImage(withURL: url, placeholderImage: #imageLiteral(resourceName: "music_placeholder"))
        }
        
        titleLabel.text = video.snippet?.title
        descriptionLabel.text = video.snippet?.channelTitle
        self.isDownloading = downloading
        self.isPaused = paused
        
        if video.isDownloaded {
            buttonsStackView.isHidden = true
            progressView.isHidden = true
        } else if downloading {
            progressView.isHidden = false
            buttonsStackView.isHidden = false
            pauseOrResumeButton.isHidden = false
            donwloadOrCancelButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        } else {
            donwloadOrCancelButton.setImage(UIImage(systemName: "arrow.down.circle.fill"), for: .normal)
            progressView.isHidden = true
            buttonsStackView.isHidden = false
            pauseOrResumeButton.isHidden = true
        }
        
        let image = isPaused ? UIImage(systemName: "play.circle.fill") : UIImage(systemName: "pause.circle.fill")
        pauseOrResumeButton.setImage(image, for: .normal)
        
    }
    
    /// Updates the progressView value.
    /// - Parameter progress: Displayed progress (0.0 to 1.0).
    public func updateDisplay(progress: Float) {
        progressView.progress = progress
    }
    
    /// Indicates that the object was loaded successfully.
    public func finishDownload() {
        UIView.transition(with: progressView, duration: 0.325, options: .transitionCrossDissolve) {
            self.progressView.isHidden = true
            self.buttonsStackView.isHidden = true
        }
    }
}
