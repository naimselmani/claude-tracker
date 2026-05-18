import Foundation
import Combine
import CoreHaptics

// MARK: - PlayMode

enum PlayMode: Hashable {
    /// Motion-controlled: shake/tilt/swipe trigger notes automatically.
    case auto
    /// Manual: only chord/note button taps trigger notes.
    case manual
}

// MARK: - PlayViewModel

/// Mediates between the play screen UI, MotionEngine, and AudioEngine.
///
/// Lifecycle:
/// - Created when `PlayView` appears (via `@StateObject`).
/// - `onAppear()` starts motion detection and audio preloading.
/// - `onDisappear()` stops motion detection and releases Combine subscriptions.
/// - Destroyed when `PlayView` is popped from the navigation stack.
@MainActor
final class PlayViewModel: ObservableObject {

    // MARK: - Published State

    @Published var playMode: PlayMode = .auto
    @Published var selectedChordId: String = ""
    @Published var selectedScaleId: String = ""
    @Published var lastShakeIntensity: Double = 0
    @Published var currentTiltAngle: Double = 0
    @Published var showingTutorial: Bool = false
    @Published var motionAvailable: Bool = true

    // MARK: - Private

    private let instrument: InstrumentConfig
    private var cancellables = Set<AnyCancellable>()
    private var hapticEngine: CHHapticEngine?
    private var settings: AppSettings?

    // MARK: - Init

    init(instrument: InstrumentConfig) {
        self.instrument = instrument
        selectedChordId = instrument.chords?.first?.id ?? ""
        selectedScaleId = instrument.scalePresets?.first?.id ?? ""
    }

    // MARK: - Lifecycle

    func onAppear(settings: AppSettings) {
        self.settings = settings

        // Apply sensitivity multiplier to shake threshold
        var config = instrument.motionProfile
        // Note: MotionProfile is a struct; we apply the multiplier inside MotionEngine.start()
        // by passing the adjusted config. For now we pass the raw config and let settings override below.
        MotionEngine.shared.start(config: config)

        // Apply sensitivity from settings
        let multiplier = settings.shakeThresholdMultiplier
        MotionEngine.shared.shakeThreshold = instrument.motionProfile.shakeThreshold * multiplier

        // Configure audio engine with instrument profile
        AudioEngine.shared.configure(audioProfile: instrument.audioProfile)

        // Apply user reverb override if set
        if settings.reverbLevel >= 0 {
            AudioEngine.shared.setReverbLevel(settings.reverbLevel)
        }

        // Preload samples (asynchronously but called on main; AVAudioFile reads are fast for bundled files)
        AudioEngine.shared.preloadSamples(for: instrument)

        // Haptics
        if settings.hapticsEnabled {
            setupHaptics()
        }

        // Subscribe to motion gestures
        subscribeToGestures()

        // Check motion availability
        motionAvailable = CMMotionManager().isAccelerometerAvailable

        // Tutorial
        checkTutorialVisibility(settings: settings)
    }

    func onDisappear() {
        MotionEngine.shared.stop()
        cancellables.removeAll()
        teardownHaptics()
    }

    // MARK: - Tutorial

    private func checkTutorialVisibility(settings: AppSettings) {
        if !settings.tutorialCompleted(for: instrument.id) {
            showingTutorial = true
        }
    }

    func dismissTutorial(instrumentId: String) {
        withAnimation(.easeOut(duration: 0.2)) {
            showingTutorial = false
        }
        settings?.markTutorialCompleted(for: instrumentId)
    }

    // MARK: - Gesture Subscription

    private func subscribeToGestures() {
        MotionEngine.shared.gesturePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] gesture in
                self?.handleGesture(gesture)
            }
            .store(in: &cancellables)
    }

    private func handleGesture(_ gesture: MotionGesture) {
        switch gesture {
        case .shake(let intensity, _):
            guard playMode == .auto else { return }
            lastShakeIntensity = intensity
            triggerCurrentSelection(intensity: intensity)
            if settings?.hapticsEnabled == true {
                triggerHaptic(pattern: instrument.hapticPattern, intensity: intensity)
            }

        case .tilt(let angle):
            currentTiltAngle = angle
            // For Lahuta: tilt drives note selection
            if instrument.id == "lahuta" {
                handleLahutaTilt(angle: angle)
            }

        case .swipe(let direction, let speed):
            guard playMode == .auto else { return }
            handleSwipe(direction: direction, speed: speed)
        }
    }

    // MARK: - Note Triggering

    /// Trigger from gesture (auto mode) or from a manual button tap.
    func triggerCurrentSelection(intensity: Double) {
        let notes = currentNotes()
        for note in notes {
            AudioEngine.shared.triggerNote(
                prefix: instrument.audioProfile.samplePrefix,
                note: note,
                intensity: intensity
            )
        }
    }

    /// Trigger a specific note (used for swipe or manual play).
    func triggerNote(_ note: String, intensity: Double) {
        AudioEngine.shared.triggerNote(
            prefix: instrument.audioProfile.samplePrefix,
            note: note,
            intensity: intensity
        )
    }

    private func currentNotes() -> [String] {
        if let chords = instrument.chords, !selectedChordId.isEmpty {
            return chords.first(where: { $0.id == selectedChordId })?.notes ?? []
        }
        if let scales = instrument.scalePresets, !selectedScaleId.isEmpty {
            // For scale-based instruments: play the first note of the selected scale
            // (swipe gesture will traverse the scale)
            return scales.first(where: { $0.id == selectedScaleId })?.notes.prefix(1).map { $0 } ?? []
        }
        return instrument.notes.prefix(1).map { $0 }
    }

    // MARK: - Instrument-Specific Gesture Handlers

    private func handleSwipe(direction: SwipeDirection, speed: Double) {
        let intensity = min(speed / 10.0, 1.0) // normalize speed to intensity

        guard let scales = instrument.scalePresets,
              let scale = scales.first(where: { $0.id == selectedScaleId }) else {
            // Chord instrument: swipe triggers current chord at swipe speed
            triggerCurrentSelection(intensity: intensity)
            return
        }

        // Scale instrument: swipe traverses notes in the direction of the swipe
        let notes: [String]
        switch direction {
        case .right, .up:
            notes = Array(scale.notes.prefix(4)) // ascending run
        case .left, .down:
            notes = Array(scale.notes.reversed().prefix(4)) // descending run
        }

        // Stagger note triggers slightly for a melodic run effect
        for (index, note) in notes.enumerated() {
            let delay = Double(index) * 0.04 // 40ms between notes
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.triggerNote(note, intensity: intensity)
            }
        }
    }

    private func handleLahutaTilt(angle: Double) {
        // Map tilt angle [-1, 1] to a note index in instrument.notes
        let notes = instrument.notes
        guard !notes.isEmpty else { return }

        let normalizedAngle = (angle + 1.0) / 2.0 // [0, 1]
        let index = Int(normalizedAngle * Double(notes.count - 1))
        let clampedIndex = min(max(index, 0), notes.count - 1)

        // Tilt for Lahuta selects the active note but does not trigger audio directly
        // (bowing gesture triggers audio; tilt only changes which note is "fretted")
        selectedScaleId = notes[clampedIndex] // reusing selectedScaleId as "current note" for Lahuta
    }

    // MARK: - Haptics

    private func setupHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            hapticEngine = try CHHapticEngine()
            hapticEngine?.isAutoShutdownEnabled = true
            try hapticEngine?.start()
        } catch {
            hapticEngine = nil
        }
    }

    private func teardownHaptics() {
        hapticEngine?.stop(completionHandler: nil)
        hapticEngine = nil
    }

    private func triggerHaptic(pattern: String, intensity: Double) {
        guard let engine = hapticEngine else { return }

        let hapticIntensity = CHHapticEventParameter(
            parameterID: .hapticIntensity,
            value: Float(min(max(intensity, 0.1), 1.0))
        )
        let sharpness = CHHapticEventParameter(
            parameterID: .hapticSharpness,
            value: pattern == "bow" ? 0.2 : (pattern == "strum" ? 0.6 : 0.8)
        )

        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [hapticIntensity, sharpness],
            relativeTime: 0
        )

        do {
            let hapticPattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: hapticPattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            // Haptic failure is non-critical; silent fallback
        }
    }
}
