# YoutubeLoader
![App Preview Banner](https://i.imgur.com/YGyGzt8.jpg)
## About
**Youtube Loader** is an IOS music player app that downloads music from YouTube to your local library. Music videos can be downloaded and the app will automatically extract only the audio. In the app, you can sort songs by artist, album and playlist. When downloading a song from Youtube, the player automatically creates an artist for the channel from which the video is downloaded.

## Features
- Downloads videos from Youtube.
- Extract audio from video.
- Search songs and videos right in the app.
- Recommendations based on uploaded songs.
- You can edit the information and image of the song, artist, album and playlist.
- Search for images directly in the app.
- Play songs in the background.
- Formation of a list of played songs based on an album, playlist or artist.
- Changing the order of the songs being played using the shuffle and reverse list.
- Changing the repeating song playback.

![App Overview Banner](https://imgur.com/6LccTv6.jpg)

## Installation
1. Clone/Download the repo.
2. Open `Youtube Loader.xcodeproj` in Xcode.
3. Open `/SupportingFiles/ApiKeys.swift`
4. Add your [Youtube v3 Api Key](https://developers.google.com/youtube/v3/getting-started)
5. Add your [Unsplash Api Key](https://unsplash.com/documentation)
6. Build & run!

## Libraries
- HTTP networking: [Alamofire](https://github.com/Alamofire/Alamofire)
- Asynchronous image loading: [AlamofireImage](https://github.com/Alamofire/AlamofireImage)
- YouTube URL extractor: [XCDYouTubeKit](https://github.com/0xced/XCDYouTubeKit)
