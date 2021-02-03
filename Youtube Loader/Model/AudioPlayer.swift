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

/// The sequence in which songs will be delivered.
enum OrderType: CaseIterable {
    case none, reversed, shuffle
}

/// Repetitions, which will be applied after the song ends.
enum RepeatType: CaseIterable {
    case  none, once, infinity
}

final class AudioPlayer: NSObject {
    
    //MARK: - Properties
    public static let shared = AudioPlayer()
    public weak var delegate: AudioPlayerDelegate?
    
    public var isPlaying: Bool {
        return audioPlayer?.isPlaying ?? false
    }
    public var previousSongIndex: Int? {
        guard let prevSong = prevSong else { return nil }
        return _songs.firstIndex(of: prevSong)
    }
    public var songIndex: Int? {
        return _songs.firstIndex(of: currentSong!)
    }
    public var songs = [Song]() {
        didSet {
            orderType = .none
            repeatType = .none
            _songs = songs
        }
    }
    // List of songs that will be used inside the object.
    // Changing the sort changes the object.
    private var _songs = [Song]()
    private var updater = CADisplayLink()
    private var audioPlayer: AVAudioPlayer!
    private(set) var currentSong: Song!
    private(set) var prevSong: Song?
    private(set) var repeatType = RepeatType.none
    private(set) var orderType = OrderType.none
    
    //MARK: - Supporting Methods
    
    /// Selects a song from the list by index. The list is not affected by the sort setting.
    /// - Parameter index: Selected song index.
    /// - Returns: Whether the operation was successful.
    @discardableResult public func selectSong(at index: Int) -> Bool {
        // If songs list is not empty, and song index greater than songs count,
        // than it starts from the beginning.
        guard !songs.isEmpty else { return false }
        if index >= songs.count || index < 0 {
            return setupPlayer(withSong: songs[0])
        } else {
            return setupPlayer(withSong: songs[index])
        }
    }
    
    /// Selects a song from the list by index. The index respects the sort parameter.
    /// - Parameter index: Selected song index.
    /// - Returns: Whether the operation was successful.
    @discardableResult public func setupPlayer(at index: Int) -> Bool {
        // If songs list is not empty, and song index greater than songs count,
        // than it starts from the beginning.
        guard !_songs.isEmpty else { return false }
        if index >= _songs.count || index < 0 {
            return setupPlayer(withSong: _songs[0])
        } else {
            return setupPlayer(withSong: _songs[index])
        }
    }
    
    /// Takes a song as a parameter. Deletes the previous player, and creates a new one with a new song.
    /// - Parameter song: The song that will be launched.
    /// - Returns: Whether the operation was successful.
    @discardableResult public func setupPlayer(withSong song: Song) -> Bool {
        guard let songURL = song.songURL else { return false }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: songURL)
            audioPlayer.delegate = self
            audioPlayer.prepareToPlay()
            updater = CADisplayLink(target: self, selector: #selector(updateDelegate))
            prevSong = currentSong
            currentSong = song
            delegate?.audioPlayerPlayingStatusChanged(isPlaying: false)
            delegate?.songChanged(song)
            play()
            return true
        } catch {
            print(error)
            return false
        }
    }
    
    /// Returns a list of songs with sorting.
    public func getOrderingSongs() -> [Song] {
        return _songs
    }
    
    /// Changes the sort parameter to the following. All ordering parameters are contained in `OrderType`.
    public func changeOrdering() {
        orderType = orderType.next()
        switch orderType {
        case .reversed:
            _songs.reverse()
        case .shuffle:
            _songs.shuffle()
        case .none:
            _songs = songs
        }
    }
    
    /// Changes the repetition setting to the next. All repeating parameters are contained in `RepeatType`.
    public func changeRepeating() {
        repeatType = repeatType.next()
    }
    
    /// Switches the play value to the opposite.
    public func togglePlaying() {
        isPlaying ? pause() : play()
    }
    
    /// Starts playing the song in the audio player.
    public func play() {
        audioPlayer.play()
        delegate?.audioPlayerPlayingStatusChanged(isPlaying: true)
        updater = CADisplayLink(target: self, selector: #selector(updateDelegate))
        updater.add(to: RunLoop.current, forMode: RunLoop.Mode.common)
    }
    
    /// Pauses the audio player.
    public func pause() {
        audioPlayer.pause()
        delegate?.audioPlayerPlayingStatusChanged(isPlaying: false)
        updater.invalidate()
    }
    
    /// Switches the song to the next. If there is no next one, then the playlist starts over.
    public func nextSong() {
        guard let songIndex = songIndex else { return }
        setupPlayer(at: songIndex + 1)
    }
    
    /// Switches the song to the previous one. If there is no previous one, then it opens the current one from the beginning.
    public func previousSong() {
        guard let songIndex = songIndex else { return }
        setupPlayer(at: songIndex - 1)
    }
    
    /// Updates the listening time of the song.
    /// - Parameter percenatge: Percentage value from which to start playback.
    public func setPlayerCurrentTime(withPercentage percenatge: Float) {
        guard audioPlayer != nil else { return }
        audioPlayer.currentTime = TimeInterval(percenatge * Float(audioPlayer.duration))
    }
    
    /// Updates the song playing time in the delegate.
    @objc private func updateDelegate() {
        delegate?.audioPlayerPeriodicUpdate(currentTime: Float(audioPlayer?.currentTime ?? 0) , duration: Float(audioPlayer?.duration ?? 0))
    }
}

//MARK: - AVAudioPlayerDelegate
extension AudioPlayer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        guard let songIndex = songIndex else { return }
        switch repeatType {
        case .none:
            nextSong()
        case .once:
            if let prevSong = prevSong, prevSong == currentSong {
                nextSong()
            } else {
                setupPlayer(at: songIndex)
            }
        case .infinity:
            setupPlayer(at: songIndex)
        }
    }
}
