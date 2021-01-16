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
    @IBOutlet private weak var gradientView: UIView!
    @IBOutlet private weak var topGradientView: UIView!
    
    
    //MARK: - Properties
    private var isProgressBarSliding = false
    private var backgroundImageView: UIImageView!
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
        songImageView.layer.cornerRadius = 8
        audioPlayer.delegate = self
        timelineView.slider.addTarget(self, action: #selector(onSliderValChanged), for: .valueChanged)
        
        downButton.layer.cornerRadius = downButton.frame.height / 2
        configureBackgroundImageView()
        configureBlurEffectView()
        configureGradients()
        
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
    
    private func configureGradients() {
        gradientView.applyGradient(colours: [#colorLiteral(red: 0.9433182478, green: 0.9772475362, blue: 0.9983965755, alpha: 1), #colorLiteral(red: 0.9999018312, green: 1, blue: 0.9998798966, alpha: 0)], locations: [0.45, 1] ,startPoint: .bottomLeft, endPoint: .topLeft)
        topGradientView.applyGradient(colours: [#colorLiteral(red: 0.9433182478, green: 0.9772475362, blue: 0.9983965755, alpha: 1), #colorLiteral(red: 0.9999018312, green: 1, blue: 0.9998798966, alpha: 0)], locations: [0.5, 1] ,startPoint: .topLeft, endPoint: .bottomLeft)
    }
    
    private func configureBlurEffectView() {
        let blurEffect = UIBlurEffect(style: .regular)
        let blurEffectView = UIVisualEffectView()
        blurEffectView.effect = blurEffect
        view.insertSubview(blurEffectView, aboveSubview: backgroundImageView)
        blurEffectView.fillSuperview()
    }
    
    private func configureBackgroundImageView() {
        backgroundImageView = UIImageView(image: songImageView.image!)
        backgroundImageView.alpha = 0.6
        backgroundImageView.contentMode = .scaleAspectFill
        view.insertSubview(backgroundImageView, at: 0)
        backgroundImageView.fillSuperview()
    }
    
    private func configureSong(_ song: Song) {
        songImageView.image = UIImage(data: song.image!)
        backgroundImageView.image = songImageView.image
        songTitleLabel.text = song.name
        songAuthor.text = song.author
        let imageName = audioPlayer.isPlaying ? "pause.fill" : "play.fill"
        playButton.setImage(UIImage(systemName: imageName), for: .normal)
    }
}

// MARK: TimeInterval
extension TimeInterval {
    func stringFromTimeInterval() -> String {
        
        let time = NSInteger(self)
        let seconds = time % 60
        var minutes = (time / 60) % 60
        minutes += Int(time / 3600) * 60  // to account for the hours as minutes
        
        return String(format: "%0.2d:%0.2d",minutes,seconds)
    }
}

extension String {
    func convertToTimeInterval() -> TimeInterval {
        guard self != "" else {
            return 0
        }
        
        var interval:Double = 0
        
        let parts = self.components(separatedBy: ":")
        for (index, part) in parts.reversed().enumerated() {
            interval += (Double(part) ?? 0) * pow(Double(60), Double(index))
        }
        
        return interval
    }
}
