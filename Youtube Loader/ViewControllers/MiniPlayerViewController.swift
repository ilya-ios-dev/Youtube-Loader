//
//  NowPlayingViewController.swift
//  Youtube Loader
//
//  Created by isEmpty on 15.01.2021.
//

import UIKit

protocol MiniPlayerDelegate: class {
    func expandSong(song: Song?)
}

final class MiniPlayerViewController: UIViewController {

    //MARK: - Outlets
    @IBOutlet private weak var songImageView: UIImageView!
    @IBOutlet private weak var songDesctiptionLabel: UILabel!
    @IBOutlet private weak var songTitleLabel: UILabel!
    @IBOutlet private weak var heartButton: UIButton!
    @IBOutlet private weak var playOrPauseButton: UIButton!
    @IBOutlet private weak var endSongTimelineLabel: UILabel!
    @IBOutlet private weak var startSongTimelineLabel: UILabel!
    @IBOutlet private weak var songProgress: UIProgressView!
    @IBOutlet private weak var backgroundImageView: UIImageView!
    @IBOutlet private weak var visualEffectView: UIVisualEffectView!
    
    //MARK: - Properties
    public weak var delegate: MiniPlayerDelegate?
    public var audioplayer = AudioPlayer()
    
    //MARK: - View Life Cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        audioplayer.delegate = self
        configureSong(audioplayer.currentSong)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        backgroundImageView.layer.cornerRadius = 5
        backgroundImageView.clipsToBounds = true
        backgroundImageView.layer.masksToBounds = true
        songImageView.layer.cornerRadius = 5
        songImageView.clipsToBounds = true
        songImageView.layer.masksToBounds = true
        
        configureBlur()
    }
        
    //MARK: - Actions
    @IBAction func heartTapped(_ sender: Any) {
    }
    
    @IBAction func pauseTapped(_ sender: Any) {
        audioplayer.playOrPause()
    }
    
    @IBAction func tapGesture(_ sender: Any) {
        delegate?.expandSong(song: nil)
    }
    
    public func play(at index: Int) {
        audioplayer.selectSong(at: index)
    }
}

//MARK: - Supporting Methods
extension MiniPlayerViewController {
    /// Adjusts the display of the `visualEffectView` to look like a shadow.
    private func configureBlur() {
        let maskLayer = CAGradientLayer()
        maskLayer.frame = visualEffectView.bounds
        maskLayer.shadowRadius = 7
        maskLayer.shadowPath = CGPath(roundedRect: visualEffectView.bounds.insetBy(dx: 5, dy: 8), cornerWidth: 10, cornerHeight: 10, transform: nil)
        maskLayer.shadowOpacity = 1
        maskLayer.shadowOffset = CGSize.zero
        maskLayer.shadowColor = UIColor.white.cgColor
        visualEffectView.layer.mask = maskLayer
    }
}

//MARK: - AudioPlayerDelegate
extension MiniPlayerViewController: AudioPlayerDelegate {
    private func configureSong(_ song: Song?) {
        guard let song = song else {
            return
        }
        songTitleLabel.text = song.name
        songDesctiptionLabel.text = song.author?.name
        if let imageUrl = song.thumbnails?.smallUrl {
            songImageView.af.setImage(withURL: imageUrl)
            backgroundImageView.af.setImage(withURL: imageUrl)
        }
        
        // Changes the colors of all elements to the desired one.
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            if let url = song.thumbnails?.smallUrl {
                guard let data = try? Data(contentsOf: url) else { return }
                let imageColor = UIImage(data: data)?.averageColor?.withLuminosity(0.5)
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.playOrPauseButton.tintColor = imageColor
                    self.songProgress.progressTintColor = imageColor
                    self.startSongTimelineLabel.textColor = imageColor
                    self.heartButton.tintColor = imageColor
                }
            }
        }
        
        let imageName = audioplayer.isPlaying ? "pause.fill" : "play.fill"
        playOrPauseButton.setImage(UIImage(systemName: imageName), for: .normal)
    }
    
    func songChanged(_ song: Song) {
        configureSong(song)
    }
    
    func audioPlayerPeriodicUpdate(currentTime: Float, duration: Float) {
        startSongTimelineLabel.text = TimeInterval(exactly: currentTime)?.stringFromTimeInterval()
        endSongTimelineLabel.text = "-" + TimeInterval(exactly: duration-currentTime)!.stringFromTimeInterval()
        songProgress.setProgress(currentTime/duration, animated: false)
    }
    
    func audioPlayerPlayingStatusChanged(isPlaying: Bool) {
        let imageName = isPlaying ? "pause.fill" : "play.fill"
        let largeConfig = UIImage.SymbolConfiguration(scale: .large)
        playOrPauseButton.setImage(UIImage(systemName: imageName, withConfiguration: largeConfig), for: .normal)
    }
}

//MARK: - PlayerSourceProtocol
extension MiniPlayerViewController: PlayerSourceProtocol {
    var originatingFrameInWindow: CGRect {
      return view.convert(view.frame, to: nil)
    }
    
    var originatingCoverImageView: UIImageView {
      return songImageView
    }
}
