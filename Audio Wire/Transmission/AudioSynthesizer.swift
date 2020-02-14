//
//  AudioSynthesizer.swift
//  Audio Wire
//
//  Created by Иван Дахненко on 25.01.2020.
//  Copyright © 2020 Ivan Dakhnenko. All rights reserved.

import AVFoundation
import Foundation

// Single synthesizer instance.
let gAudioSynthesizer: AudioSynthesizer = AudioSynthesizer()

class AudioSynthesizer {

    // The maximum number of audio buffers in flight. Setting to two allows one
    // buffer to be played while the next is being written.
    var kInFlightAudioBuffers: Int = 2

    // The number of audio samples per buffer. A lower value reduces latency for
    // changes but requires more processing but increases the risk of being unable
    // to fill the buffers in time. A setting of 1024 represents about 23ms of
    // samples.
    let kSamplesPerBuffer: AVAudioFrameCount = AVAudioFrameCount(GlobalParameters.samplesPerBuffer)

    // The audio engine manages the sound system.
    let audioEngine: AVAudioEngine = AVAudioEngine()

    // The player node schedules the playback of the audio buffers.
    let playerNode: AVAudioPlayerNode = AVAudioPlayerNode()

    // Use standard non-interleaved PCM audio.
    let audioFormat = AVAudioFormat(standardFormatWithSampleRate: Double(GlobalParameters.sampleRate), channels: 1)

    // A circular queue of audio buffers.
    var audioBuffers: [AVAudioPCMBuffer] = [AVAudioPCMBuffer]()

    // The index of the next buffer to fill.
    var bufferIndex: Int = 0

    // The dispatch queue to render audio samples.
    let audioQueue: DispatchQueue = DispatchQueue(label: "AudioSynthesizerQueue", attributes: [])

    // A semaphore to gate the number of buffers processed.
    let audioSemaphore: DispatchSemaphore

    class func sharedSynth() -> AudioSynthesizer {
        return gAudioSynthesizer
    }

    public init() {
        // init the semaphore
        audioSemaphore = DispatchSemaphore(value: kInFlightAudioBuffers)
        
        // Create a pool of audio buffers.
        for _ in 0..<kInFlightAudioBuffers {
          audioBuffers.append(AVAudioPCMBuffer(pcmFormat: audioFormat!,
                                               frameCapacity: kSamplesPerBuffer)!)
        }
        
        // Attach and connect the player node.
        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: audioFormat)
        
        do {
            try audioEngine.start()
        } catch {
            print("AudioEngine didn't start")
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(AudioSynthesizer.audioEngineConfigurationChange(_:)), name: NSNotification.Name.AVAudioEngineConfigurationChange, object: audioEngine)
    }
    
    func play(frequencies: [Float32], length: Int) {
        let unitVelocity = Float32(2.0 * .pi / (audioFormat?.sampleRate)!)
        let frequenciesVelocities = frequencies.map {$0 * unitVelocity}
        audioQueue.async {
            var sampleTime: Float32 = 0
            let rampDuration: Float32 = 100
            var fadeOutIndex = rampDuration
            for _ in 0..<length {
                // Wait for a buffer to become available.
                self.audioSemaphore.wait(timeout: DispatchTime.distantFuture)
                
                // Fill the buffer with new samples.
                let audioBuffer = self.audioBuffers[self.bufferIndex]
                let leftChannel = audioBuffer.floatChannelData?[0]
                let rightChannel = audioBuffer.floatChannelData?[1]
                for sampleIndex in 0 ..< Int(self.kSamplesPerBuffer) {
                    var sample = frequenciesVelocities.reduce(0, {x, y in
                        x + sin(y * sampleTime)
                    }) // / Float(frequencies.count) // MARK: do we really need this?
                    if sampleTime < rampDuration {
                        sample *= 1 - (rampDuration - sampleTime) / rampDuration
                    }
                    if sampleTime > Float32(1024 * length) - rampDuration {
                        sample *= fadeOutIndex / rampDuration
                        fadeOutIndex -= 1
                    }
                    
                    leftChannel?[sampleIndex] = sample
                    rightChannel?[sampleIndex] = sample
                    sampleTime = sampleTime + 1.0
                }
                audioBuffer.frameLength = self.kSamplesPerBuffer
                
                // Schedule the buffer for playback and release it for reuse after
                // playback has finished.
                self.playerNode.scheduleBuffer(audioBuffer) {
                    self.audioSemaphore.signal()
                    return
                }
                
                self.bufferIndex = (self.bufferIndex + 1) % self.audioBuffers.count
            }
        }
        
        playerNode.pan = 0.8
        playerNode.play()
    }

    @objc func audioEngineConfigurationChange(_ notification: Notification) -> Void {
        NSLog("Audio engine configuration change: \(notification)")
    }
}
