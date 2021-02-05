//
//  NowPlayingViewController.swift
//  Youtube Loader
//
//  Created by isEmpty on 15.01.2021.
//

import UIKit

protocol MiniPlayerDelegate: class {
    func expandSong(song: Song?)
    func didSelectedItem(_ item: Song?)
}

final class MiniPlayerViewController: UIViewController {

    //MARK: - Outlets
    // Image
    @IBOutlet private weak var songImageView: UIImageView!
    @IBOutlet private weak var backgroundImageView: UIImageView!
    @IBOutlet private weak var visualEffectView: UIVisualEffectView!
    // Labels
    @IBOutlet private weak var authorLabel: UILabel!
    @IBOutlet private weak var titleLabel: UILabel!
    // Buttons
    @IBOutlet private weak var nextButton: UIButton!
    @IBOutlet private weak var playOrPauseButton: UIButton!
    // Bottom control
    @IBOutlet private weak var endSongTimelineLabel: UILabel!
    @IBOutlet private weak var startSongTimelineLabel: UILabel!
    @IBOutlet private weak var songProgress: UIProgressView!
    // Tap Gesture
    @IBOutlet private var tapGesture: UITapGestureRecognizer!
    
    //MARK: - Properties
    public weak var delegate: MiniPlayerDelegate?
    public var sourceProtocol: PlayerSourceProtocol!
    public var songs: [Song] {
        get {
            return audioplayer.songs
        } set {
            audioplayer.songs = newValue
        }
    }
    private var audioplayer: AudioPlayer {
        return sourceProtocol.audioPlayer
    }
    
    //MARK: - View Life Cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        audioplayer.delegate = self
        configureSong(audioplayer.currentSong)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureImageViews()
        configureBlur()
    }
        
    //MARK: - Actions
    @IBAction private func nextTapped(_ sender: Any) {
        audioplayer.nextSong()
    }
    
    @IBAction private func pauseTapped(_ sender: Any) {
        audioplayer.togglePlaying()
    }
    
    @IBAction private func tapGesture(_ sender: Any) {
        guard audioplayer.currentSong != nil else { return }
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
    
    private func configureImageViews() {
        backgroundImageView.layer.cornerRadius = 5
        backgroundImageView.clipsToBounds = true
        backgroundImageView.layer.masksToBounds = true
        songImageView.layer.cornerRadius = 5
        songImageView.clipsToBounds = true
        songImageView.layer.masksToBounds = true
    }
    
    /// Changes the colors of all elements to the desired one
    /// - Parameter song: A song that is expected to get a medium color.
    private func configureColorElementOf(_ song: Song) {
        let group = DispatchGroup()
        var color: UIColor?
        group.enter()
        DispatchQueue.global().async(group: group) {
            if let url = song.thumbnails?.smallUrl {
                guard let data = try? Data(contentsOf: url) else {
                    group.leave()
                    return
                }
                color = UIImage(data: data)?.averageColor?.withLuminosity(0.5)
                group.leave()
            } else {
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            self.playOrPauseButton.tintColor = color
            self.songProgress.progressTintColor = color
            self.startSongTimelineLabel.textColor = color
            self.nextButton.tintColor = color
        }
    }
}

//MARK: - AudioPlayerDelegate
extension MiniPlayerViewController: AudioPlayerDelegate {
    private func configureSong(_ song: Song?) {
        guard let song = song else { return }
        delegate?.didSelectedItem(song)
        
        titleLabel.text = song.name
        authorLabel.text = song.author?.name
        if let imageUrl = song.thumbnails?.smallUrl {
            songImageView.af.setImage(withURL: imageUrl, placeholderImage: #imageLiteral(resourceName: "music_placeholder"))
            backgroundImageView.af.setImage(withURL: imageUrl, placeholderImage: #imageLiteral(resourceName: "music_placeholder"))
        }
        
        configureColorElementOf(song)
        
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
