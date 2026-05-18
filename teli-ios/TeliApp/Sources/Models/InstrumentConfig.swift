import Foundation

// MARK: - Top-Level Container

/// Root model decoded from `instruments.json`.
struct InstrumentListConfig: Codable {
    let instruments: [InstrumentConfig]
}

// MARK: - InstrumentConfig

/// Complete configuration for a single instrument.
/// Loaded from `instruments.json` at app launch; never mutated at runtime.
struct InstrumentConfig: Codable, Identifiable {

    /// Unique machine-readable identifier. Used as the sample prefix and UserDefaults key prefix.
    let id: String

    /// Human-readable instrument name shown in the UI (may include special characters, e.g., "Çiftelija").
    let displayName: String

    /// Broad instrument family: "string", "bowed", "wind", etc.
    let category: String

    /// Whether the instrument is accessible without an in-app purchase.
    let isUnlocked: Bool

    /// Motion sensor parameters for this instrument.
    let motionProfile: MotionProfile

    /// Audio engine parameters for this instrument.
    let audioProfile: AudioProfile

    /// Ordered list of playable notes in scientific pitch notation.
    /// Use "s" in place of "#" (e.g., "Fs4" for F#4, "Bb4" for B-flat 4).
    let notes: [String]

    /// Identifier for the haptic pattern to use on trigger ("strum", "pluck", "bow").
    let hapticPattern: String

    /// Steps for the first-launch tutorial overlay.
    let tutorialSteps: [TutorialStep]

    /// Chord definitions. Present for chord-based instruments (e.g., Guitar).
    /// Absent for scale-based or single-note instruments.
    var chords: [ChordConfig]?

    /// Scale preset definitions. Present for scale-based instruments (e.g., Çiftelija).
    var scalePresets: [ScalePreset]?
}

// MARK: - MotionProfile

/// Per-instrument parameters for the MotionEngine.
struct MotionProfile: Codable {

    /// Minimum accelerometer magnitude (in g) to register a shake gesture.
    let shakeThreshold: Double

    /// Minimum delta magnitude (in g) over a 5-sample window to register a swipe gesture.
    let swipeThreshold: Double

    /// Multiplier applied to the raw tilt angle before publishing (0.0–1.0).
    let tiltSensitivity: Double

    /// Time (in milliseconds) to ignore new gestures after a gesture fires.
    let cooldownMs: Int

    /// Number of consecutive samples above `shakeThreshold` required to confirm a shake.
    let consecutiveSamplesRequired: Int
}

// MARK: - AudioProfile

/// Per-instrument parameters for the AudioEngine.
struct AudioProfile: Codable {

    /// Minimum time (in milliseconds) between successive triggers of the same note.
    let debounceMs: Int

    /// Names of the velocity layers present for this instrument's samples.
    /// Should match `VelocityLayer.rawValue` values: ["soft", "medium", "hard"].
    let velocityLayers: [String]

    /// Whether reverb is applied to this instrument.
    let reverbEnabled: Bool

    /// Reverb wet/dry mix as a fraction [0.0, 1.0].
    /// Converted to AVAudioUnitReverb.wetDryMix (0–100) by multiplying × 100.
    let reverbWetMix: Double

    /// Prefix used when constructing sample file names.
    /// Sample file format: `{samplePrefix}_{note}_{velocity}.wav`
    let samplePrefix: String
}

// MARK: - ChordConfig

/// A named chord with a set of simultaneous notes.
struct ChordConfig: Codable, Identifiable {

    /// Machine-readable chord identifier (e.g., "Am", "G").
    let id: String

    /// Display name shown on the chord button (may differ from `id` for localization).
    let displayName: String

    /// Notes in this chord, in scientific pitch notation.
    let notes: [String]
}

// MARK: - ScalePreset

/// A named scale or mode as an ordered sequence of notes.
struct ScalePreset: Codable, Identifiable {

    /// Machine-readable scale identifier (e.g., "phrygian", "major").
    let id: String

    /// Display name shown on the scale button.
    let displayName: String

    /// Notes in ascending order, in scientific pitch notation.
    let notes: [String]
}

// MARK: - TutorialStep

/// A single step in the first-launch tutorial overlay for an instrument.
struct TutorialStep: Codable {

    /// Step number (1-based). Used for display ("Step 1 of 3") and ordering.
    let step: Int

    /// User-facing instruction text displayed in the tutorial card.
    let instruction: String

    /// Identifier of the UI element to highlight during this step.
    /// Known values: "chordButtons", "scaleButtons", "instrumentImage",
    ///               "tiltIndicator", "playArea".
    let highlight: String
}

// MARK: - AppSettings

/// User-configurable settings persisted to UserDefaults.
/// All properties have safe defaults that work without any prior user interaction.
final class AppSettings: ObservableObject {

    private enum Keys {
        static let hapticsEnabled = "settings.hapticsEnabled"
        static let motionSensitivity = "settings.motionSensitivity"
        static let reverbLevel = "settings.reverbLevel"
        static let leftHandedMode = "settings.leftHandedMode"
        static let reduceMotion = "settings.reduceMotion"
        static let onboardingComplete = "onboardingComplete"
    }

    // MARK: Published Settings

    @Published var hapticsEnabled: Bool {
        didSet { UserDefaults.standard.set(hapticsEnabled, forKey: Keys.hapticsEnabled) }
    }

    /// 0 = Low (threshold × 1.5), 1 = Medium (threshold × 1.0), 2 = High (threshold × 0.75)
    @Published var motionSensitivity: Int {
        didSet { UserDefaults.standard.set(motionSensitivity, forKey: Keys.motionSensitivity) }
    }

    /// User-overridden reverb level [0.0, 1.0]. -1.0 means "use instrument default".
    @Published var reverbLevel: Double {
        didSet { UserDefaults.standard.set(reverbLevel, forKey: Keys.reverbLevel) }
    }

    @Published var leftHandedMode: Bool {
        didSet { UserDefaults.standard.set(leftHandedMode, forKey: Keys.leftHandedMode) }
    }

    @Published var reduceMotion: Bool {
        didSet { UserDefaults.standard.set(reduceMotion, forKey: Keys.reduceMotion) }
    }

    @Published var onboardingComplete: Bool {
        didSet { UserDefaults.standard.set(onboardingComplete, forKey: Keys.onboardingComplete) }
    }

    // MARK: Init

    init() {
        let defaults = UserDefaults.standard
        hapticsEnabled = defaults.object(forKey: Keys.hapticsEnabled) as? Bool ?? true
        motionSensitivity = defaults.object(forKey: Keys.motionSensitivity) as? Int ?? 1
        reverbLevel = defaults.object(forKey: Keys.reverbLevel) as? Double ?? -1.0
        leftHandedMode = defaults.object(forKey: Keys.leftHandedMode) as? Bool ?? false
        reduceMotion = defaults.object(forKey: Keys.reduceMotion) as? Bool ?? false
        onboardingComplete = defaults.bool(forKey: Keys.onboardingComplete)
    }

    // MARK: Computed

    /// Returns the shake threshold multiplier based on the current sensitivity setting.
    var shakeThresholdMultiplier: Double {
        switch motionSensitivity {
        case 0: return 1.5  // Low sensitivity — harder to trigger
        case 2: return 0.75 // High sensitivity — easier to trigger
        default: return 1.0 // Medium (default)
        }
    }

    /// Tutorial completion state per instrument.
    func tutorialCompleted(for instrumentId: String) -> Bool {
        UserDefaults.standard.bool(forKey: "tutorial.completed.\(instrumentId)")
    }

    func markTutorialCompleted(for instrumentId: String) {
        UserDefaults.standard.set(true, forKey: "tutorial.completed.\(instrumentId)")
    }

    func resetAllTutorials() {
        // Called from Settings → "Reset Tutorial"
        // Prefix-based reset requires iterating known instrument IDs
        let knownIds = ["guitar", "ciftelija", "lahuta"]
        knownIds.forEach {
            UserDefaults.standard.removeObject(forKey: "tutorial.completed.\($0)")
        }
    }
}
