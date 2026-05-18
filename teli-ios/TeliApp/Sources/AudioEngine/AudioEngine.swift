import AVFoundation
import Foundation

// MARK: - Velocity Layer

enum VelocityLayer: String, CaseIterable {
    case soft
    case medium
    case hard
}

// MARK: - AudioEngine

/// Manages sample preloading, AVAudioEngine graph setup, and note triggering.
///
/// Architecture:
/// - One `AVAudioPlayerNode` per (note, velocityLayer) combination.
/// - All player nodes route through an `AVAudioUnitReverb` for room acoustics.
/// - A DynamicsProcessor limiter sits after reverb to prevent digital clipping.
/// - All samples are preloaded into `AVAudioPCMBuffer` at instrument load time.
///
/// Thread safety:
/// - `setupEngine()` and `preloadSamples()` are called on the main thread.
/// - `triggerNote()` is called on the main thread from the ViewModel.
/// - AVAudioEngine's render thread is managed by the system; no shared mutable
///   state is accessed from the render thread.
final class AudioEngine: ObservableObject {

    // MARK: Singleton

    static let shared = AudioEngine()

    // MARK: Private Audio Graph

    private let engine = AVAudioEngine()
    private let reverb = AVAudioUnitReverb()
    private let limiter = AVAudioUnitEffect(audioComponentDescription: AudioComponentDescription(
        componentType: kAudioUnitType_Effect,
        componentSubType: kAudioUnitSubType_DynamicsProcessor,
        componentManufacturer: kAudioUnitManufacturer_Apple,
        componentFlags: 0,
        componentFlagsMask: 0
    ))

    // MARK: Playback State

    /// Keyed by `"{prefix}_{note}_{velocity}"` e.g. "guitar_A3_soft"
    private var playerNodes: [String: AVAudioPlayerNode] = [:]

    /// Keyed by `"{prefix}_{note}_{velocity}"` — holds the preloaded PCM buffer
    private var sampleBuffers: [String: AVAudioPCMBuffer] = [:]

    /// Keyed by `"{prefix}_{note}"` — tracks last trigger time for debounce
    private var lastTriggerTimes: [String: Date] = [:]

    // MARK: Configuration

    private var debounceInterval: TimeInterval = 0.08
    private var isEngineRunning: Bool = false

    // MARK: Init

    private init() {}

    // MARK: - Engine Setup

    /// Configures the AVAudioSession and starts the AVAudioEngine.
    /// Call this once at app launch from `TeliApp` or `AppState`.
    func setupEngine() {
        configureAudioSession()
        buildAudioGraph()
        startEngine()
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setPreferredIOBufferDuration(0.005) // 5ms target
            try session.setPreferredSampleRate(44100)
            try session.setActive(true)
        } catch {
            // Graceful degradation: audio may have higher latency or not play.
            // Do not crash — continue so the app remains usable.
            #if DEBUG
            print("[AudioEngine] AVAudioSession configuration failed: \(error)")
            #endif
        }
    }

    private func buildAudioGraph() {
        let mainMixer = engine.mainMixerNode

        // Configure reverb
        reverb.loadFactoryPreset(.mediumHall)
        reverb.wetDryMix = 15 // Default 15%; overridden per-instrument by configure()

        // Attach nodes
        engine.attach(reverb)
        engine.attach(limiter)

        // Connect: reverb → limiter → main mixer
        engine.connect(reverb, to: limiter, format: nil)
        engine.connect(limiter, to: mainMixer, format: nil)
    }

    private func startEngine() {
        do {
            try engine.start()
            isEngineRunning = true
        } catch {
            isEngineRunning = false
            #if DEBUG
            print("[AudioEngine] Failed to start AVAudioEngine: \(error)")
            #endif
        }
    }

    // MARK: - Instrument Configuration

    /// Apply per-instrument audio settings.
    /// Call when a new instrument is selected, before preloading samples.
    func configure(audioProfile: AudioProfile) {
        debounceInterval = Double(audioProfile.debounceMs) / 1000.0

        if audioProfile.reverbEnabled {
            reverb.wetDryMix = Float(audioProfile.reverbWetMix * 100.0)
        } else {
            reverb.wetDryMix = 0
        }
    }

    /// Override the reverb wet mix from user settings (0.0–1.0 range).
    func setReverbLevel(_ level: Double) {
        reverb.wetDryMix = Float(min(max(level, 0.0), 1.0) * 100.0)
    }

    // MARK: - Sample Preloading

    /// Preloads all (note × velocityLayer) samples for the given instrument into memory.
    ///
    /// This is called when the user selects an instrument, before the play screen appears.
    /// Missing sample files are silently skipped — the note simply won't sound.
    func preloadSamples(for instrument: InstrumentConfig) {
        guard isEngineRunning else { return }

        for note in instrument.notes {
            for layer in VelocityLayer.allCases {
                let fileName = "\(instrument.audioProfile.samplePrefix)_\(note)_\(layer.rawValue)"
                let key = sampleKey(prefix: instrument.audioProfile.samplePrefix, note: note, layer: layer)
                loadSampleIfNeeded(named: fileName, key: key)
            }
        }

        // Also preload chord/scale notes that may not be in the base notes array
        let allNotes = allNotesForInstrument(instrument)
        for note in allNotes where !instrument.notes.contains(note) {
            for layer in VelocityLayer.allCases {
                let fileName = "\(instrument.audioProfile.samplePrefix)_\(note)_\(layer.rawValue)"
                let key = sampleKey(prefix: instrument.audioProfile.samplePrefix, note: note, layer: layer)
                loadSampleIfNeeded(named: fileName, key: key)
            }
        }
    }

    private func allNotesForInstrument(_ instrument: InstrumentConfig) -> [String] {
        var notes = Set(instrument.notes)
        instrument.chords?.forEach { chord in notes.formUnion(chord.notes) }
        instrument.scalePresets?.forEach { scale in notes.formUnion(scale.notes) }
        return Array(notes)
    }

    private func loadSampleIfNeeded(named name: String, key: String) {
        guard sampleBuffers[key] == nil else { return } // already loaded

        guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else {
            #if DEBUG
            print("[AudioEngine] Sample not found: \(name).wav")
            #endif
            return
        }

        guard let file = try? AVAudioFile(forReading: url) else { return }

        let format = file.processingFormat
        let frameCount = UInt32(file.length)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }

        do {
            try file.read(into: buffer)
            sampleBuffers[key] = buffer
        } catch {
            #if DEBUG
            print("[AudioEngine] Failed to read sample \(name): \(error)")
            #endif
        }
    }

    // MARK: - Note Triggering

    /// Trigger a note with the given intensity.
    ///
    /// - Parameters:
    ///   - prefix: The instrument sample prefix (e.g., "guitar").
    ///   - note: Scientific pitch notation (e.g., "A3"). Use "s" for sharp (e.g., "Fs4" for F#4).
    ///   - intensity: Normalized intensity in [0.0, 1.0], from the motion engine.
    func triggerNote(prefix: String, note: String, intensity: Double) {
        let dKey = debounceKey(prefix: prefix, note: note)
        guard passesDebounce(key: dKey) else { return }

        let layer = selectVelocityLayer(intensity: intensity)
        let sKey = sampleKey(prefix: prefix, note: note, layer: layer)

        guard let buffer = sampleBuffers[sKey] else { return }

        let player = playerNodes[sKey] ?? makePlayerNode(key: sKey, format: buffer.format)
        schedulePlayback(player: player, buffer: buffer, intensity: intensity)

        lastTriggerTimes[dKey] = Date()
    }

    private func schedulePlayback(player: AVAudioPlayerNode, buffer: AVAudioPCMBuffer, intensity: Double) {
        player.stop()
        player.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)

        // Map intensity [0.0, 1.0] → volume [0.3, 1.0]
        let volume = Float(0.3 + intensity * 0.7)
        player.volume = min(max(volume, 0.0), 1.0)

        if !player.isPlaying {
            player.play()
        }
    }

    // MARK: - Velocity Layer Selection

    /// Select the appropriate velocity layer based on normalized intensity.
    ///
    /// - soft:   [0.00, 0.33)
    /// - medium: [0.33, 0.66)
    /// - hard:   [0.66, 1.00]
    func selectVelocityLayer(intensity: Double) -> VelocityLayer {
        switch intensity {
        case ..<0.33:
            return .soft
        case 0.33..<0.66:
            return .medium
        default:
            return .hard
        }
    }

    // MARK: - Debounce

    private func passesDebounce(key: String) -> Bool {
        guard let last = lastTriggerTimes[key] else { return true }
        return Date().timeIntervalSince(last) >= debounceInterval
    }

    // MARK: - Key Helpers

    private func sampleKey(prefix: String, note: String, layer: VelocityLayer) -> String {
        "\(prefix)_\(note)_\(layer.rawValue)"
    }

    private func debounceKey(prefix: String, note: String) -> String {
        "\(prefix)_\(note)"
    }

    // MARK: - Player Node Management

    private func makePlayerNode(key: String, format: AVAudioFormat) -> AVAudioPlayerNode {
        let node = AVAudioPlayerNode()
        engine.attach(node)
        engine.connect(node, to: reverb, format: format)
        playerNodes[key] = node
        return node
    }

    // MARK: - Audio Session Interruption Handling

    /// Call this when the app returns to foreground after an audio interruption.
    func handleInterruptionEnd() {
        guard !engine.isRunning else { return }
        do {
            try AVAudioSession.sharedInstance().setActive(true)
            try engine.start()
            isEngineRunning = true
        } catch {
            #if DEBUG
            print("[AudioEngine] Failed to restart after interruption: \(error)")
            #endif
        }
    }

    // MARK: - Cleanup

    /// Release preloaded samples for a specific instrument prefix to free memory.
    /// Call when an instrument is deselected if memory pressure is a concern.
    func unloadSamples(prefix: String) {
        let keysToRemove = sampleBuffers.keys.filter { $0.hasPrefix(prefix) }
        keysToRemove.forEach { key in
            sampleBuffers.removeValue(forKey: key)
            if let node = playerNodes[key] {
                node.stop()
                engine.detach(node)
                playerNodes.removeValue(forKey: key)
            }
        }
    }
}
