//
//  PlayerViewController.swift
//  Youtube Loader
//
//  Created by isEmpty on 11.01.2021.
//

import UIKit
import CoreData

final class PlayerViewController: UIViewController {
    //MARK: - Outlets
    // Top panel
    @IBOutlet private weak var downButton: UIButton!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    // Central content panel
    @IBOutlet private weak var timelineView: TimelineView!
    @IBOutlet private weak var songTitleLabel: UILabel!
    @IBOutlet private weak var songAuthor: UILabel!
    @IBOutlet private weak var songImageView: UIImageView!
    @IBOutlet private weak var backgroundImageView: UIImageView!
    @IBOutlet private weak var visualEffectView: UIVisualEffectView!
    // Playback setting buttons
    @IBOutlet private weak var playButton: PlayButton!
    @IBOutlet private weak var forwardButton: UIButton!
    @IBOutlet private weak var backwardButton: UIButton!
    // Bottom configuration buttons
    @IBOutlet private weak var songsListButton: UIButton!
    @IBOutlet private weak var shuffleButton: UIButton!
    @IBOutlet private weak var repeatButton: UIButton!
    @IBOutlet private weak var addToPlaylist: UIButton!
    
    //MARK: - Properties
    public var sourceProtocol: PlayerSourceProtocol!
    
    private var isProgressBarSliding = false
    private var audioPlayer: AudioPlayer {
        return sourceProtocol.audioPlayer
    }
    private var context: NSManagedObjectContext  = {
        return (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    }()
    
    //MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
        
        audioPlayer.delegate = self
        configureSong(audioPlayer.currentSong)
    }
        
    //MARK: - Actions
    @IBAction private func playTapped(_ sender: Any) {
        audioPlayer.togglePlaying()
    }
    
    @IBAction private func backwardButtonTapped(_ sender: Any) {
        audioPlayer.previousSong()
    }
    
    @IBAction private func forwardButtonTapped(_ sender: Any) {
        audioPlayer.nextSong()
    }
    
    @IBAction private func dismissTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction private func songsListTapped(_ sender: Any) {
        let storyboard = UIStoryboard(name: "PlayerSongsList", bundle: nil)
        guard let vc = storyboard.instantiateInitialViewController() as? PlayerSongsListViewController else { return }
        // Delay the capture of snapshot by 0.1 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1 , execute: {
            // take a snapshot of current view and set it as backingImage
            vc.backingImage = self.view.asImage()
            
            // set the modal presentation to full screen, in iOS 13, its no longer full screen by default
            vc.modalPresentationStyle = .fullScreen
            vc.sourceProtocol = self.sourceProtocol

            // present the view controller modally without animation
            self.present(vc, animated: false, completion: nil)
        })
    }
    
    @IBAction private func shuffleTapped(_ sender: Any) {
        audioPlayer.changeOrdering()
        configureShuffleButton()
    }
    
    @IBAction private func repeatTapped(_ sender: Any) {
        audioPlayer.changeRepeating()
        configureRepeatButton()
    }
    
    @IBAction private func addToPlaylistTapped(_ sender: Any) {
        let storyboard = UIStoryboard(name: "AddToPlaylist", bundle: nil)
        guard let vc = storyboard.instantiateInitialViewController() as? AddToPlaylistViewController else { return }
        // Delay the capture of snapshot by 0.1 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1 , execute: {
            // take a snapshot of current view and set it as backingImage
            vc.backingImage = self.view.asImage()
            vc.currentSong = self.audioPlayer.currentSong
            // set the modal presentation to full screen, in iOS 13, its no longer full screen by default
            vc.modalPresentationStyle = .fullScreen
            
            // present the view controller modally without animation
            self.present(vc, animated: false, completion: nil)
        })
    }
}

//MARK: - AudioPlayerDelegate
extension PlayerViewController: AudioPlayerDelegate {
    func songChanged(_ song: Song) {
        configureSong(song)
    }
    
    func audioPlayerPeriodicUpdate(currentTime: Float, duration: Float) {
        if !isProgressBarSliding {
            timelineView.startLabel.text = TimeInterval(exactly: currentTime)?.stringFromTimeInterval()
            timelineView.endLabel.text = "-" + TimeInterval(exactly: duration-currentTime)!.stringFromTimeInterval()
            timelineView.slider.value = currentTime/duration
        }
    }
    
    func audioPlayerPlayingStatusChanged(isPlaying: Bool) {
        let imageName = isPlaying ? "pause.fill" : "play.fill"
        playButton.setImage(UIImage(systemName: imageName), for: .normal)
    }
}

//MARK: - Supporting Methods
extension PlayerViewController {
    @objc func onSliderValChanged(slider: UISlider, event: UIEvent) {
        if let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
            case .began:
                // handle drag began
                isProgressBarSliding = true
                break
            case .ended:
                // handle drag ended
                isProgressBarSliding = false
                audioPlayer.setPlayerCurrentTime(withPercentage: slider.value)
            case .moved:
                // handle drag moved
                let start = timelineView.startLabel.text?.convertToTimeInterval()
                let end = String(timelineView.endLabel.text?.dropFirst() ?? "").convertToTimeInterval()
                let songDuration = Float(start! + end)
                let selectedTime = (songDuration * slider.value).rounded(.toNearestOrAwayFromZero)
                let timeLeft = (songDuration * (1 - slider.value)).rounded(.toNearestOrAwayFromZero)
                timelineView.startLabel.text = TimeInterval(exactly: selectedTime)?.stringFromTimeInterval()
                timelineView.endLabel.text = "-" + TimeInterval(exactly: timeLeft)!.stringFromTimeInterval()
                break
            default:
                break
            }
        }
    }
    
    private func configureSong(_ song: Song) {
        UIView.transition(with: songImageView, duration: 0.325, options: .transitionCrossDissolve) {
            if let imageUrl = song.thumbnails?.largeUrl {
                self.songImageView.af.setImage(withURL: imageUrl, placeholderImage: #imageLiteral(resourceName: "vinyl_record"))
                self.backgroundImageView.af.setImage(withURL: imageUrl, placeholderImage: #imageLiteral(resourceName: "vinyl_record"))
            }
            self.songTitleLabel.text = song.name
            self.songAuthor.text = song.author?.name
        } completion: { (_) in }
        
        songImageView.rotate(duration: 1)
        
        let imageName = audioPlayer.isPlaying ? "pause.fill" : "play.fill"
        playButton.setImage(UIImage(systemName: imageName), for: .normal)
        
        // Changes the colors of all elements to the desired one.
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            if let url = song.thumbnails?.smallUrl {
                guard let data = try? Data(contentsOf: url) else { return }
                guard let imageColor = UIImage(data: data)?.averageColor?.withLuminosity(0.5) else { return }
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.timelineView.changeAccentColor(to: imageColor)
                }
            }
        }
    }
    
    /// Adds a circle to the center of the songImageView.
    private func configureCircleView() {
        let circleView = UIView()
        circleView.backgroundColor = #colorLiteral(red: 0.9411764706, green: 0.9568627451, blue: 0.9882352941, alpha: 1)
        circleView.layer.cornerRadius = (songImageView.frame.height / 2) * 0.2
        circleView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(circleView)
        NSLayoutConstraint.activate([
            circleView.centerYAnchor.constraint(equalTo: songImageView.centerYAnchor),
            circleView.centerXAnchor.constraint(equalTo: songImageView.centerXAnchor),
            circleView.heightAnchor.constraint(equalTo: songImageView.heightAnchor, multiplier: 0.2),
            circleView.widthAnchor.constraint(equalTo: circleView.heightAnchor)
        ])
    }
    
    /// Adjusts the display of the `visualEffectView` to look like a shadow.
    private func configureBlur() {
        let maskLayer = CAGradientLayer()
        maskLayer.frame = visualEffectView.bounds
        maskLayer.shadowRadius = 15
        
        maskLayer.shadowPath = CGPath(roundedRect: visualEffectView.bounds.inset(by: UIEdgeInsets(top: songImageView.frame.height / 2, left: 30, bottom: 0, right: 30)), cornerWidth: 20, cornerHeight: 20, transform: nil)
        maskLayer.shadowOpacity = 1
        maskLayer.shadowOffset = CGSize.zero
        maskLayer.shadowColor = UIColor.white.cgColor
        visualEffectView.layer.mask = maskLayer
    }
    
    private func configureShuffleButton() {
        shuffleButton.tintColor = audioPlayer.orderType == .none ? #colorLiteral(red: 0.5254901961, green: 0.6392156863, blue: 0.7450980392, alpha: 1) : #colorLiteral(red: 0.1803921569, green: 0.2666666667, blue: 0.4274509804, alpha: 1)
        let mediumConfig = UIImage.SymbolConfiguration(scale: .medium)
        switch audioPlayer.orderType {
        case .reversed:
            shuffleButton.setImage(UIImage(systemName: "arrow.up.arrow.down")?.withConfiguration(mediumConfig), for: .normal)
        case .shuffle:
            shuffleButton.setImage(UIImage(systemName: "shuffle")?.withConfiguration(mediumConfig), for: .normal)
        case .none:
            shuffleButton.setImage(UIImage(systemName: "arrow.up.arrow.down")?.withConfiguration(mediumConfig), for: .normal)
        }
    }
    
    private func configureRepeatButton() {
        repeatButton.tintColor = audioPlayer.repeatType == .none ? #colorLiteral(red: 0.5254901961, green: 0.6392156863, blue: 0.7450980392, alpha: 1) : #colorLiteral(red: 0.1803921569, green: 0.2666666667, blue: 0.4274509804, alpha: 1)
        let mediumConfig = UIImage.SymbolConfiguration(scale: .medium)
        switch audioPlayer.repeatType {
        case .none:
            repeatButton.setImage(UIImage(systemName: "repeat")?.withConfiguration(mediumConfig), for: .normal)
        case .once:
            repeatButton.setImage(UIImage(systemName: "repeat.1")?.withConfiguration(mediumConfig), for: .normal)
        case .infinity:
            repeatButton.setImage(UIImage(systemName: "repeat")?.withConfiguration(mediumConfig), for: .normal)
        }
    }
    
    private func configureViews() {
        configureShuffleButton()
        configureRepeatButton()
        configureCircleView()
        configureBlur()
        backgroundImageView.layer.cornerRadius = backgroundImageView.frame.height / 2
        songImageView.layer.cornerRadius = songImageView.frame.height / 2
        timelineView.slider.addTarget(self, action: #selector(onSliderValChanged), for: .valueChanged)
        downButton.layer.cornerRadius = downButton.frame.height / 2
    }
}
