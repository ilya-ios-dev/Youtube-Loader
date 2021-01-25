//
//  AudioPlayer.swift
//  Youtube Loader
//
//  Created by isEmpty on 11.01.2021.
//

import AVFoundation

protocol AudioPlayerDelegate: class {
    func audioPlayerPeriodicUpdate(currentTime: Float, duration: Float)
    func audioPlayerPlayingStatusChanged(isPlaying: Bool)
    func songChanged(_ song: Song)
}

final class AudioPlayer: NSObject {
    
    //MARK: - Properties
    private var updater = CADisplayLink()
    private var audioPlayer: AVAudioPlayer!
    
    public var currentSong: Song!
    public var songs = [Song]()
    public weak var delegate: AudioPlayerDelegate?
    public var isPlaying: Bool {
        return audioPlayer?.isPlaying ?? false
    }
    public var songIndex: Int? {
        return songs.firstIndex(of: currentSong)
    }

    //MARK: - Initialization
    override init() {
        super.init()
    }
    
    //MARK: - Supporting Methods
    @discardableResult
    public func selectSong(at index: Int) -> Bool {
        guard !songs.isEmpty else { return false }
        if index >= songs.count || index < 0 {
            return setupPlayer(withSong: songs[0])
        } else {
            return setupPlayer(withSong: songs[index])
        }
    }
    
    @discardableResult
    public func setupPlayer(withSong song: Song) -> Bool {
        guard let songURL = song.songURL else { return false }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: songURL)
            audioPlayer.delegate = self
            audioPlayer.prepareToPlay()
            delegate?.audioPlayerPlayingStatusChanged(isPlaying: false)
            delegate?.songChanged(song)
            updater = CADisplayLink(target: self, selector: #selector(updateDelegate))
            currentSong = song
            play()
            return true
        } catch {
            
            print(error)
            return false
        }
    }
    
    public func playOrPause() {
        isPlaying ? pause() : play()
    }
    
    public func play() {
        audioPlayer.play()
        delegate?.audioPlayerPlayingStatusChanged(isPlaying: true)
        updater = CADisplayLink(target: self, selector: #selector(updateDelegate))
        updater.add(to: RunLoop.current, forMode: RunLoop.Mode.common)
    }

    public func pause() {
        audioPlayer.pause()
        delegate?.audioPlayerPlayingStatusChanged(isPlaying: false)
        updater.invalidate()
    }

    public func nextSong() {
        guard let songIndex = songIndex else { return }
        selectSong(at: songIndex + 1)
    }
    
    public func previousSong() {
        guard let songIndex = songIndex else { return }
        selectSong(at: songIndex - 1)
    }

    
    // Может перенести в плейлист менеджер?
    public func setPlayerCurrentTime(withPercentage percenatge: Float) {
        guard audioPlayer != nil else { return }
        audioPlayer.currentTime = TimeInterval(percenatge * Float(audioPlayer.duration))
    }
    
    @objc private func updateDelegate() {
        delegate?.audioPlayerPeriodicUpdate(currentTime: Float(audioPlayer?.currentTime ?? 0) , duration: Float(audioPlayer?.duration ?? 0))
    }
}

//MARK: - AVAudioPlayerDelegate
extension AudioPlayer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        nextSong()
    }
}
