//
//  KeepAlive.swift
//  Terrain
//
//  Created from mond
//

import AVFoundation
import UIKit

public final class KeepAlive {
    public static let shared = KeepAlive()
    
    private var player: AVAudioPlayer?
    private var timer: Timer?
    
    private init() {}
    
    public func start() {
        guard player == nil else { return }
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: .mixWithOthers)
        try? AVAudioSession.sharedInstance().setActive(true)

        let sr = 8000, samples = Int(Double(sr) * 0.5)
        var w = Data("RIFF".utf8)
        w += withUnsafeBytes(of: UInt32(36 + samples * 2).littleEndian) { Data($0) }
        w += Data("WAVEfmt ".utf8)
        w += withUnsafeBytes(of: UInt32(16).littleEndian) { Data($0) }
        w += withUnsafeBytes(of: UInt16(1).littleEndian) { Data($0) }
        w += withUnsafeBytes(of: UInt16(1).littleEndian) { Data($0) }
        w += withUnsafeBytes(of: UInt32(sr).littleEndian) { Data($0) }
        w += withUnsafeBytes(of: UInt32(sr * 2).littleEndian) { Data($0) }
        w += withUnsafeBytes(of: UInt16(2).littleEndian) { Data($0) }
        w += withUnsafeBytes(of: UInt16(16).littleEndian) { Data($0) }
        w += Data("data".utf8)
        w += withUnsafeBytes(of: UInt32(samples * 2).littleEndian) { Data($0) }
        w += Data(count: samples * 2)

        player = try? AVAudioPlayer(data: w)
        player?.volume = 0
        player?.numberOfLoops = -1
        player?.play()

        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.player?.play()
        }
        
        print("(ka) background keep-alive started")
    }

    public func stop() {
        timer?.invalidate()
        timer = nil
        player?.stop()
        player = nil
        print("(ka) background keep-alive stopped")
    }
}
