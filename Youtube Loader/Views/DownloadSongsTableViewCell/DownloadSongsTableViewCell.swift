//
//  AddSongTableViewCell.swift
//  Youtube Loader
//
//  Created by isEmpty on 16.01.2021.
//

import UIKit
import Alamofire
import AlamofireImage

protocol AddSongTableViewCellDelegate: class {
    func downloadTapped(_ cell: DownloadSongsTableViewCell)
    func cancelTapped(_ cell: DownloadSongsTableViewCell)
    func pauseTapped(_ cell: DownloadSongsTableViewCell)
    func resumeTapped(_ cell: DownloadSongsTableViewCell)
}

/// A table view cell that specializes in displaying a songs available for download.
final class DownloadSongsTableViewCell: UITableViewCell {
    
    //MARK: - Outlets
    // Image
    @IBOutlet private weak var backgroundBlurImage: UIImageView!
    @IBOutlet private weak var visualEffectBlur: UIVisualEffectView!
    @IBOutlet private weak var songImageView: UIImageView!
    // Title's
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    // Button's stack
    @IBOutlet private weak var pauseOrResumeButton: UIButton!
    @IBOutlet private weak var donwloadOrCancelButton: UIButton!
    @IBOutlet private weak var buttonsStackView: UIStackView!
    // Progress
    @IBOutlet private weak var progressView: UIProgressView!
    
    
    //MARK: - Properties
    public weak var delegate: AddSongTableViewCellDelegate?
    
    private var isPaused = false
    private var isDownloading = false
    
    //MARK: - Actions
    @IBAction private func tapPauseOrResume(_ sender: Any) {
        isPaused ? resume() : pause()
        isPaused = !isPaused
    }
    
    @IBAction private func tapDownloadOrCancel(_ sender: Any) {
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
extension DownloadSongsTableViewCell {
    // Adjusts the display of the visualEffectBlur to look like a shadow.
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
    
    // Animate pausing and pass it to delegate
    private func pause() {
        delegate?.pauseTapped(self)
        pauseOrResumeButton.setImage(UIImage(systemName: "play.circle.fill"), for: .normal)
    }
    
    // Animate resuming and pass it to deleagate
    private func resume() {
        delegate?.resumeTapped(self)
        pauseOrResumeButton.setImage(UIImage(systemName: "pause.circle.fill"), for: .normal)
    }
    
    // Animate downloading and pass it to delegate
    private func download() {
        delegate?.downloadTapped(self)
        UIView.transition(with: donwloadOrCancelButton, duration: 0.325, options: .transitionCrossDissolve) {
            self.donwloadOrCancelButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
            self.pauseOrResumeButton.isHidden = false
            self.progressView.isHidden = false
        }
    }
    
    // Animate cancellation and pass it to delegate.
    private func cancel() {
        delegate?.cancelTapped(self)
        progressView.progress = 0
        UIView.transition(with: donwloadOrCancelButton, duration: 0.325, options: .transitionCrossDissolve) {
            self.donwloadOrCancelButton.setImage(UIImage(systemName: "arrow.down.circle.fill"), for: .normal)
            self.pauseOrResumeButton.isHidden = true
            self.progressView.isHidden = true
        }
    }
}

//MARK: - Public Methods
extension DownloadSongsTableViewCell {
    /// Adjusts the display of the call based on the provided conditions.
    /// - Parameters:
    ///   - video: The object to be displayed.
    ///   - downloading: Whether the object is currently loading.
    ///   - paused: Whether the object is paused.
    ///   - url: Link to image.
    public func configure(video: Video, downloading: Bool, paused: Bool, url: URL?) {
        if let url = url {
            backgroundBlurImage.af.setImage(withURL: url, placeholderImage: Images.music_placeholder)
            songImageView.af.setImage(withURL: url, placeholderImage: Images.music_placeholder)
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
