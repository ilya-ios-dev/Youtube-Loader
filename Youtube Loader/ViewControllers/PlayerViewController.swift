//
//  PlayerViewController.swift
//  Youtube Loader
//
//  Created by isEmpty on 11.01.2021.
//

import UIKit
import CoreData

protocol PlayerSourceProtocol: class {
    var originatingFrameInWindow: CGRect { get }
    var originatingCoverImageView: UIImageView { get }
}

final class PlayerViewController: UIViewController {
    
    //MARK: - Outlets
    @IBOutlet private weak var songImageView: UIImageView!
    @IBOutlet private weak var songTitleLabel: UILabel!
    @IBOutlet private weak var songAuthor: UILabel!
    @IBOutlet private weak var timelineView: TimelineView!
    @IBOutlet private weak var playButton: PlayButton!
    @IBOutlet private weak var forwardButton: UIButton!
    @IBOutlet private weak var backwardButton: UIButton!
    @IBOutlet private weak var downButton: UIButton!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var backgroundImageView: UIImageView!
    @IBOutlet private weak var visualEffectView: UIVisualEffectView!
    
    
    //MARK: - Properties
    private var isProgressBarSliding = false
    private var context: NSManagedObjectContext  = {
        return (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    }()
    
    public var sourceView: PlayerSourceProtocol!
    public var audioPlayer: AudioPlayer!
    
    //MARK: - View Life Cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureCircleView()
        
        configureBlur()
        backgroundImageView.layer.cornerRadius = backgroundImageView.frame.height / 2
        songImageView.layer.cornerRadius = songImageView.frame.height / 2
        audioPlayer.delegate = self
        timelineView.slider.addTarget(self, action: #selector(onSliderValChanged), for: .valueChanged)
        
        downButton.layer.cornerRadius = downButton.frame.height / 2
        configureSong(audioPlayer.currentSong)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        audioPlayer.delegate = nil
    }
    
    //MARK: - Actions
    @IBAction private func playTapped(_ sender: Any) {
        audioPlayer.playOrPause()
    }
    
    @IBAction func backwardButtonTapped(_ sender: Any) {
        audioPlayer.previousSong()
    }
    
    @IBAction func forwardButtonTapped(_ sender: Any) {
        audioPlayer.nextSong()
    }
    
    @IBAction func dismissTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
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
        if let imageUrl = song.thumbnails?.largeUrl {
            songImageView.af.setImage(withURL: imageUrl)
            backgroundImageView.af.setImage(withURL: imageUrl)
        }
        songTitleLabel.text = song.name
        songAuthor.text = song.author?.name
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
}
