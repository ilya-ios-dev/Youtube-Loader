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
        songImageView.layer.cornerRadius = 4
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
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

//MARK: - AudioPlayerDelegate
extension MiniPlayerViewController: AudioPlayerDelegate {
    private func configureSong(_ song: Song?) {
        guard let song = song else {
            return
        }
        songTitleLabel.text = song.name
        songDesctiptionLabel.text = song.author
        songImageView.image = UIImage(data: song.image ?? Data())
        let imageName = audioplayer.isPlaying ? "pause.fill" : "play.fill"
        playOrPauseButton.setImage(UIImage(systemName: imageName), for: .normal)
        playOrPauseButton.tintColor = audioplayer.isPlaying ? #colorLiteral(red: 0.6705882353, green: 0.7254901961, blue: 0.7568627451, alpha: 1) : #colorLiteral(red: 0.2352941176, green: 0.2588235294, blue: 0.3568627451, alpha: 1)
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
        playOrPauseButton.setImage(UIImage(systemName: imageName), for: .normal)
        playOrPauseButton.tintColor = isPlaying ? #colorLiteral(red: 0.6705882353, green: 0.7254901961, blue: 0.7568627451, alpha: 1) : #colorLiteral(red: 0.2352941176, green: 0.2588235294, blue: 0.3568627451, alpha: 1) 
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
