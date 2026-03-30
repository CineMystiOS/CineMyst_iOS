//
//  VideoPlayerView.swift
//  CineMystApp
//
//  Created by user@55 on 20/11/25.
//
import UIKit
import AVFoundation

class VideoPlayerView: UIView {

    private var player: AVPlayer?

    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }

    private var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }

    func configure(url: URL, isMuted: Bool = true, shouldLoop: Bool = true) {
        player = AVPlayer(url: url)
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspectFill
        player?.isMuted = isMuted

        // Loop video
        if shouldLoop {
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: player?.currentItem,
                queue: .main) { _ in
                    self.player?.seek(to: .zero)
                    self.player?.play()
                }
        }

        player?.play()
    }
}
