import CoreMotion
import Combine
import Foundation

// MARK: - Gesture Types

enum GestureState {
    case idle
    case detecting
    case triggered
    case cooldown
}

enum MotionGesture {
    case shake(intensity: Double, direction: SIMD3<Double>)
    case swipe(direction: SwipeDirection, speed: Double)
    case tilt(angle: Double)
}

enum SwipeDirection {
    case up
    case down
    case left
    case right
}

// MARK: - MotionEngine

/// Converts raw CoreMotion sensor data into high-level musical gesture events.
///
/// Usage:
/// 1. Call `start(config:)` when a play screen appears.
/// 2. Subscribe to `gesturePublisher` to receive `MotionGesture` events.
/// 3. Call `stop()` when the play screen disappears.
///
/// All published events are dispatched on the main queue.
final class MotionEngine: ObservableObject {

    // MARK: Singleton

    static let shared = MotionEngine()

    // MARK: Public Configuration

    /// Minimum accelerometer magnitude (in g) required to register a shake.
    var shakeThreshold: Double = 1.5

    /// Minimum swipe delta magnitude (in g) over a 5-sample window to register a swipe.
    var swipeThreshold: Double = 0.8

    /// Scales how much tilt angle affects the published tilt value (0.0–1.0).
    var tiltSensitivity: Double = 0.6

    /// Time to wait after a gesture before accepting new gestures.
    var cooldownDuration: TimeInterval = 0.15

    /// Number of consecutive samples above threshold required to confirm a shake gesture.
    var requiredConsecutiveSamples: Int = 3

    // MARK: Published State

    /// Publishes recognized gestures. Subscribe on main thread.
    let gesturePublisher = PassthroughSubject<MotionGesture, Never>()

    // MARK: Private State

    private let motionManager = CMMotionManager()
    private var gestureState: GestureState = .idle
    private var consecutiveSamplesAboveThreshold: Int = 0

    // Exponential moving average state (α = 0.3)
    private let smoothingAlpha: Double = 0.3
    private var smoothedAcceleration: SIMD3<Double> = .zero

    // Swipe detection: circular buffer of last 5 smoothed vectors
    private var swipeHistory: [SIMD3<Double>] = []
    private let swipeHistoryLength: Int = 5

    // MARK: Init

    private init() {}

    // MARK: - Lifecycle

    /// Start motion detection with the given instrument configuration.
    /// - Parameter config: The `MotionProfile` from the selected instrument's JSON config.
    func start(config: MotionProfile) {
        applyConfig(config)
        startAccelerometer()
        startDeviceMotion()
    }

    /// Stop all motion updates and reset state.
    func stop() {
        motionManager.stopAccelerometerUpdates()
        motionManager.stopDeviceMotionUpdates()
        resetState()
    }

    // MARK: - Private Setup

    private func applyConfig(_ config: MotionProfile) {
        shakeThreshold = config.shakeThreshold
        swipeThreshold = config.swipeThreshold
        tiltSensitivity = config.tiltSensitivity
        cooldownDuration = Double(config.cooldownMs) / 1000.0
        requiredConsecutiveSamples = config.consecutiveSamplesRequired
    }

    private func startAccelerometer() {
        guard motionManager.isAccelerometerAvailable else {
            // Graceful degradation: motion detection unavailable.
            // The PlayViewModel will observe this and offer manual-play mode.
            return
        }
        motionManager.accelerometerUpdateInterval = 0.01 // 100 Hz
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let self, let data else { return }
            self.processAccelerometer(data.acceleration)
        }
    }

    private func startDeviceMotion() {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 0.01 // 100 Hz
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }
            self.processTilt(motion.attitude)
        }
    }

    private func resetState() {
        gestureState = .idle
        consecutiveSamplesAboveThreshold = 0
        smoothedAcceleration = .zero
        swipeHistory.removeAll()
    }

    // MARK: - Accelerometer Processing

    private func processAccelerometer(_ accel: CMAcceleration) {
        // Step 1: Apply exponential moving average smoothing (α = 0.3)
        let raw = SIMD3<Double>(accel.x, accel.y, accel.z)
        smoothedAcceleration = smoothingAlpha * raw + (1.0 - smoothingAlpha) * smoothedAcceleration

        let magnitude = simd_length(smoothedAcceleration)

        // Step 2: Update swipe history and check for swipe gesture
        updateSwipeHistory(smoothedAcceleration)
        if gestureState == .idle {
            checkForSwipe()
        }

        // Step 3: Run shake state machine
        switch gestureState {
        case .idle, .detecting:
            if magnitude > shakeThreshold {
                consecutiveSamplesAboveThreshold += 1
                gestureState = .detecting

                if consecutiveSamplesAboveThreshold >= requiredConsecutiveSamples {
                    triggerShake(magnitude: magnitude, vector: smoothedAcceleration)
                }
            } else {
                // Magnitude dropped below threshold — reset counter
                consecutiveSamplesAboveThreshold = 0
                if gestureState == .detecting {
                    gestureState = .idle
                }
            }

        case .triggered:
            // Immediately transition to cooldown (triggered is a momentary state)
            enterCooldown()

        case .cooldown:
            // Ignore all samples during cooldown
            break
        }
    }

    private func triggerShake(magnitude: Double, vector: SIMD3<Double>) {
        gestureState = .triggered
        consecutiveSamplesAboveThreshold = 0

        let intensity = mapIntensityToVelocity(magnitude: magnitude)
        let normalizedDirection = magnitude > 0 ? vector / magnitude : .zero

        gesturePublisher.send(.shake(intensity: intensity, direction: normalizedDirection))
        enterCooldown()
    }

    // MARK: - Cooldown

    private func enterCooldown() {
        gestureState = .cooldown
        DispatchQueue.main.asyncAfter(deadline: .now() + cooldownDuration) { [weak self] in
            guard let self else { return }
            self.gestureState = .idle
            self.consecutiveSamplesAboveThreshold = 0
        }
    }

    // MARK: - Intensity Mapping

    /// Maps raw accelerometer magnitude to a normalized velocity value [0.0, 1.0].
    ///
    /// - Linear mapping from [threshold, 3×threshold] → [0.0, 1.0]
    /// - Values below threshold map to 0.0
    /// - Values above 3× threshold clamp to 1.0
    private func mapIntensityToVelocity(magnitude: Double) -> Double {
        let lowerBound = shakeThreshold
        let upperBound = shakeThreshold * 3.0
        let clamped = min(max(magnitude, lowerBound), upperBound)
        return (clamped - lowerBound) / (upperBound - lowerBound)
    }

    // MARK: - Tilt Detection

    private func processTilt(_ attitude: CMAttitude) {
        // pitch: radians, -π/2 (face down) to +π/2 (face up / vertical)
        let pitch = attitude.pitch
        let normalizedAngle = (pitch / (.pi / 2)) * tiltSensitivity
        let clampedAngle = min(max(normalizedAngle, -1.0), 1.0)
        gesturePublisher.send(.tilt(angle: clampedAngle))
    }

    // MARK: - Swipe Detection

    private func updateSwipeHistory(_ sample: SIMD3<Double>) {
        swipeHistory.append(sample)
        if swipeHistory.count > swipeHistoryLength {
            swipeHistory.removeFirst()
        }
    }

    private func checkForSwipe() {
        guard swipeHistory.count == swipeHistoryLength else { return }

        let oldest = swipeHistory.first!
        let current = swipeHistory.last!
        let delta = current - oldest
        let deltaMagnitude = simd_length(delta)

        guard deltaMagnitude > swipeThreshold else { return }

        // Determine dominant axis (X or Y; Z-axis swipe not used)
        let absX = abs(delta.x)
        let absY = abs(delta.y)

        let direction: SwipeDirection
        if absX >= absY {
            direction = delta.x > 0 ? .right : .left
        } else {
            direction = delta.y > 0 ? .up : .down
        }

        // Calculate speed in g/s
        let intervalSeconds = Double(swipeHistoryLength) * motionManager.accelerometerUpdateInterval
        let speed = deltaMagnitude / max(intervalSeconds, 0.001)

        gesturePublisher.send(.swipe(direction: direction, speed: speed))

        // Clear history to avoid repeated swipe events from the same motion arc
        swipeHistory.removeAll()
    }
}
