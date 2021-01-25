//
//  CoreData+Extensions.swift
//  Youtube Loader
//
//  Created by isEmpty on 19.01.2021.
//

import CoreData

//MARK: - Thumbnail
extension Thumbnail {
    @discardableResult public class func create(context: NSManagedObjectContext, small: URL?, medium: URL?, large: URL?) -> Thumbnail {
        let thumbnail = Thumbnail(context: context)
        thumbnail.large = large?.lastPathComponent
        thumbnail.medium = medium?.lastPathComponent
        thumbnail.small = small?.lastPathComponent
        return thumbnail
    }

    @discardableResult public class func create(context: NSManagedObjectContext, small: String?, medium: String?, large: String?) -> Thumbnail {
        let thumbnail = Thumbnail(context: context)
        thumbnail.large = large
        thumbnail.medium = medium
        thumbnail.small = small
        return thumbnail
    }
    
    public var largeUrl: URL? {
        return FileManager.default.url(for: .documentDirectory, filename: self.large ?? "")
    }
    
    public var mediumUrl: URL? {
        return FileManager.default.url(for: .documentDirectory, filename: self.medium ?? "")
    }
    
    public var smallUrl: URL? {
        return FileManager.default.url(for: .documentDirectory, filename: self.small ?? "")
    }
    
}

//MARK: - Song
extension Song {
    @discardableResult public class func create(context: NSManagedObjectContext, small: URL?, medium: URL?, large: URL?, songURL: URL?, dateSave: Date = Date(), id: String?, name: String?, artist: Artist? = nil) -> Song {
        let song = Song(context: context)
        song.thumbnails = Thumbnail.create(context: context, small: small, medium: medium, large: large)
        song.song = songURL
        song.dateSave = dateSave
        song.id = id
        song.name = name
        return song
    }
    
    @discardableResult public class func create(context: NSManagedObjectContext, thumbnails: Thumbnail, songURL: URL?, dateSave: Date = Date(), id: String?, name: String?, artist: Artist? = nil) -> Song {
        let song = Song(context: context)
        song.thumbnails = thumbnails
        song.song = songURL
        song.dateSave = dateSave
        song.id = id
        song.name = name
        song.author = artist
        return song
    }
    
    public var songURL: URL? {
        guard let name = self.song?.lastPathComponent else { return nil }
        return FileManager.default.url(for: .documentDirectory, filename: name)
    }
}

//MARK: - Album
extension Album {
    @discardableResult public class func create(context: NSManagedObjectContext, thumbnails: Thumbnail, name: String, author: Artist? = nil, songs: [Song?] = []) -> Album {
        let album = Album(context: context)
        album.dateSave = Date()
        album.thumbnails = thumbnails
        album.name = name
        album.author = author
        album.songs = NSSet(array: songs as [Any])
        return album
    }
    
    @discardableResult public class func create(context: NSManagedObjectContext, small: URL?, medium: URL?, large: URL?, name: String, author: Artist? = nil, songs: [Song?] = []) -> Album {
        let album = Album(context: context)
        album.dateSave = Date()
        album.thumbnails = Thumbnail.create(context: context, small: small, medium: medium, large: large)
        album.name = name
        album.author = author
        album.songs = NSSet(array: songs as [Any])
        return album
    }
}

//MARK: - Artist
extension Artist {
    @discardableResult public class func create(context: NSManagedObjectContext, thumbnails: Thumbnail, id: String, name: String) -> Artist {
        let fetchRequest: NSFetchRequest = Artist.fetchRequest()
        let predicate = NSPredicate(format: "id == %@", id)
        fetchRequest.predicate = predicate
        var artist = try? context.fetch(fetchRequest).first
        
        if artist == nil {
            artist = Artist(context: context)
            artist?.dateSave = Date()
            artist?.thumbnails = thumbnails
            artist?.id = id
            artist?.name = name
        }
        
        return artist!
    }

    @discardableResult public class func create (context: NSManagedObjectContext, small: URL?, medium: URL?, large: URL?, id: String? = nil, name: String) -> Artist {
        let artist = Artist(context: context)
        artist.dateSave = Date()
        artist.thumbnails = Thumbnail.create(context: context, small: small, medium: medium, large: large)
        artist.id = id
        artist.name = name
        return artist
    }
}

//MARK: - Playlist
extension Playlist {
    @discardableResult public class func create (context: NSManagedObjectContext, imageName: String?, name: String?, songs: [Song?] = []) -> Playlist {
        let playlist = Playlist(context: context)
        playlist.dateSave = Date()
        playlist.name = name
        playlist.imageName = imageName ?? "playlist_img_1"
        return playlist
    }
}
