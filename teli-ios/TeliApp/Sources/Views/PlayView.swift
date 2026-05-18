import SwiftUI
import CoreHaptics

// MARK: - PlayView

/// The main instrument play screen. Divided into:
/// - Top 40%: Instrument visual area (animated instrument image + tilt indicator)
/// - Bottom 60%: Control panel (chord/scale buttons, mode picker)
struct PlayView: View {

    let instrument: InstrumentConfig

    @StateObject private var viewModel: PlayViewModel
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    init(instrument: InstrumentConfig) {
        self.instrument = instrument
        _viewModel = StateObject(wrappedValue: PlayViewModel(instrument: instrument))
    }

    var body: some View {
        ZStack {
            // Background
            Color(hex: "0D0D0D")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Instrument Visual Area (top 40%) ──────────────────────────
                InstrumentVisualView(
                    instrumentId: instrument.id,
                    shakeIntensity: viewModel.lastShakeIntensity,
                    tiltAngle: viewModel.currentTiltAngle,
                    reduceMotion: appState.settings.reduceMotion
                )
                .frame(maxHeight: .infinity)

                // ── Separator ──────────────────────────────────────────────────
                Rectangle()
                    .fill(Color(hex: "C8963E").opacity(0.3))
                    .frame(height: 1)

                // ── Control Panel (bottom 60%) ─────────────────────────────────
                ControlPanelView(instrument: instrument, viewModel: viewModel)
                    .frame(maxHeight: .infinity)
            }

            // ── Tutorial Overlay ───────────────────────────────────────────────
            if viewModel.showingTutorial {
                TutorialOverlayView(
                    steps: instrument.tutorialSteps,
                    onDismiss: {
                        viewModel.dismissTutorial(instrumentId: instrument.id)
                    }
                )
                .transition(.opacity)
                .zIndex(10)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Instruments")
                            .font(.body)
                    }
                    .foregroundColor(Color(hex: "C8963E"))
                }
                .accessibilityLabel("Back to instrument selection")
            }

            ToolbarItem(placement: .principal) {
                Text(instrument.displayName)
                    .font(.headline)
                    .foregroundColor(.white)
                    .accessibilityAddTraits(.isHeader)
            }
        }
        .onAppear { viewModel.onAppear(settings: appState.settings) }
        .onDisappear { viewModel.onDisappear() }
    }
}

// MARK: - InstrumentVisualView

/// Displays the instrument image with animations that react to shake and tilt gestures.
struct InstrumentVisualView: View {

    let instrumentId: String
    let shakeIntensity: Double
    let tiltAngle: Double
    let reduceMotion: Bool

    @State private var isAnimating: Bool = false

    var body: some View {
        ZStack {
            // Radial gradient background for depth
            RadialGradient(
                colors: [Color(hex: "C8963E").opacity(0.08), Color.clear],
                center: .center,
                startRadius: 40,
                endRadius: 200
            )

            Image(instrumentId)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 280)
                .scaleEffect(reduceMotion ? 1.0 : (isAnimating ? 1.0 + (shakeIntensity * 0.10) : 1.0))
                .rotationEffect(
                    reduceMotion ? .zero : .degrees(tiltAngle * 3.0),
                    anchor: .center
                )
                .animation(reduceMotion ? nil : .spring(response: 0.15, dampingFraction: 0.6), value: isAnimating)
                .onChange(of: shakeIntensity) { _, newValue in
                    guard !reduceMotion, newValue > 0 else { return }
                    isAnimating = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        isAnimating = false
                    }
                }
                .accessibilityLabel("\(instrumentId.capitalized) instrument illustration")
                .accessibilityAddTraits(.isImage)
        }
        .padding(24)
    }
}

// MARK: - ControlPanelView

/// Bottom control panel: mode picker, chord/scale buttons, tilt indicator.
struct ControlPanelView: View {

    let instrument: InstrumentConfig
    @ObservedObject var viewModel: PlayViewModel

    var body: some View {
        VStack(spacing: 24) {
            // ── Mode Picker ────────────────────────────────────────────────────
            Picker("Play Mode", selection: $viewModel.playMode) {
                Text("Auto").tag(PlayMode.auto)
                Text("Manual").tag(PlayMode.manual)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
            .accessibilityLabel("Play mode selector")

            // ── Chord / Scale Buttons ──────────────────────────────────────────
            if let chords = instrument.chords {
                ChordButtonsView(
                    chords: chords,
                    selectedId: $viewModel.selectedChordId
                )
            } else if let scales = instrument.scalePresets {
                ScaleButtonsView(
                    scales: scales,
                    selectedId: $viewModel.selectedScaleId
                )
            } else {
                // Instruments with no chord/scale mode (e.g., Lahuta with tilt-only pitch)
                TiltOnlyHint()
            }

            // ── Tilt Indicator ─────────────────────────────────────────────────
            TiltIndicatorView(angle: viewModel.currentTiltAngle)
                .padding(.horizontal, 20)

            Spacer()
        }
        .padding(.top, 24)
    }
}

// MARK: - ChordButtonsView

struct ChordButtonsView: View {

    let chords: [ChordConfig]
    @Binding var selectedId: String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(chords) { chord in
                    ChordButton(
                        label: chord.displayName,
                        isSelected: selectedId == chord.id
                    ) {
                        selectedId = chord.id
                    }
                    .accessibilityLabel("\(chord.displayName) chord")
                    .accessibilityAddTraits(selectedId == chord.id ? [.isSelected] : [])
                    .accessibilityHint("Double tap to select \(chord.displayName) chord")
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - ScaleButtonsView

struct ScaleButtonsView: View {

    let scales: [ScalePreset]
    @Binding var selectedId: String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(scales) { scale in
                    ChordButton(
                        label: scale.displayName,
                        isSelected: selectedId == scale.id
                    ) {
                        selectedId = scale.id
                    }
                    .accessibilityLabel(scale.displayName)
                    .accessibilityAddTraits(selectedId == scale.id ? [.isSelected] : [])
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - ChordButton

struct ChordButton: View {

    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(isSelected ? Color(hex: "0D0D0D") : .white.opacity(0.85))
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .frame(minWidth: 72, minHeight: 56)
                .background(
                    isSelected
                        ? AnyShapeStyle(Color(hex: "C8963E"))
                        : AnyShapeStyle(.ultraThinMaterial)
                )
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(
                            isSelected
                                ? Color.clear
                                : Color(hex: "C8963E").opacity(0.3),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - TiltIndicatorView

struct TiltIndicatorView: View {

    let angle: Double // -1.0 to 1.0

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .fill(Color.white.opacity(0.15))
                    .frame(height: 4)

                // Dot
                let range = geo.size.width - 16 // account for dot diameter
                let offset = (angle + 1.0) / 2.0 * range  // map [-1,1] → [0, range]
                Circle()
                    .fill(Color(hex: "C8963E"))
                    .frame(width: 16, height: 16)
                    .offset(x: min(max(offset - 8, 0), range))
                    .animation(.interpolatingSpring(stiffness: 120, damping: 15), value: angle)
            }
        }
        .frame(height: 16)
        .accessibilityLabel("Tilt indicator")
        .accessibilityValue("\(Int(angle * 100)) percent")
    }
}

// MARK: - TiltOnlyHint

struct TiltOnlyHint: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "iphone.gen3.landscape")
                .font(.system(size: 32))
                .foregroundColor(Color(hex: "C8963E").opacity(0.7))

            Text("Tilt to change pitch")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - TutorialOverlayView

struct TutorialOverlayView: View {

    let steps: [TutorialStep]
    let onDismiss: () -> Void

    @State private var currentStep: Int = 0

    private var step: TutorialStep? { steps.first(where: { $0.step == currentStep + 1 }) }

    var body: some View {
        ZStack {
            // Dim background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 24) {
                Spacer()

                if let step {
                    VStack(spacing: 20) {
                        // Step indicator dots
                        HStack(spacing: 8) {
                            ForEach(0..<steps.count, id: \.self) { index in
                                Circle()
                                    .fill(index == currentStep
                                          ? Color(hex: "C8963E")
                                          : Color.white.opacity(0.3))
                                    .frame(width: 8, height: 8)
                            }
                        }

                        Text(step.instruction)
                            .font(.title3.bold())
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)

                        Button(action: advance) {
                            Text(currentStep < steps.count - 1 ? "Next" : "Start Playing")
                                .font(.body.bold())
                                .foregroundColor(Color(hex: "0D0D0D"))
                                .padding(.horizontal, 32)
                                .padding(.vertical, 14)
                                .background(Color(hex: "C8963E"))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(32)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color(hex: "C8963E").opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
                    .transition(.scale.combined(with: .opacity))
                }

                Spacer()
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func advance() {
        if currentStep < steps.count - 1 {
            withAnimation(.easeInOut(duration: 0.2)) {
                currentStep += 1
            }
        } else {
            onDismiss()
        }
    }
}

// MARK: - Scale Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
