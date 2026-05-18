import SwiftUI

// MARK: - App Entry Point

@main
struct TeliApp: App {

    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(appState.settings)
                .onReceive(
                    NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)
                ) { notification in
                    handleAudioInterruption(notification)
                }
        }
    }

    private func handleAudioInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else { return }

        switch type {
        case .ended:
            // Re-activate audio session after an interruption (phone call, Siri, etc.)
            AudioEngine.shared.handleInterruptionEnd()
        case .began:
            // System handles audio session deactivation automatically
            break
        @unknown default:
            break
        }
    }
}

// MARK: - ContentView

/// Root view. Shows onboarding on first launch, then the instrument select screen.
struct ContentView: View {

    @EnvironmentObject var appState: AppState

    var body: some View {
        if appState.settings.onboardingComplete {
            InstrumentSelectView()
        } else {
            OnboardingView {
                appState.settings.onboardingComplete = true
            }
        }
    }
}

// MARK: - AppState

/// Top-level application state container.
/// Owns the instrument list (loaded from JSON) and shared settings.
final class AppState: ObservableObject {

    @Published var instruments: [InstrumentConfig] = []
    let settings = AppSettings()

    init() {
        loadInstruments()
        AudioEngine.shared.setupEngine()
    }

    private func loadInstruments() {
        guard let url = Bundle.main.url(forResource: "instruments", withExtension: "json") else {
            // instruments.json missing — critical error, app cannot function
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let config = try JSONDecoder().decode(InstrumentListConfig.self, from: data)
            instruments = config.instruments
        } catch {
            // JSON decode failure — show error state via empty instruments array
            #if DEBUG
            print("[AppState] Failed to decode instruments.json: \(error)")
            #endif
        }
    }
}

// MARK: - OnboardingView

/// Three-screen onboarding flow shown on first launch.
/// Completion is stored in AppSettings.onboardingComplete.
struct OnboardingView: View {

    let onComplete: () -> Void

    @State private var page: Int = 0

    private let pages: [(title: String, subtitle: String, systemImage: String)] = [
        (
            "Welcome to Teli",
            "Play music with the motion of your hands.",
            "music.note"
        ),
        (
            "Shake to Play",
            "Shake your phone to strum, pluck, or bow a virtual instrument.",
            "hand.raised.fill"
        ),
        (
            "Choose Your Instrument",
            "Guitar, Çiftelija, Lahuta — and more coming soon.",
            "guitars.fill"
        )
    ]

    var body: some View {
        ZStack {
            Color(hex: "0D0D0D").ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Page content
                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { index in
                        OnboardingPage(
                            title: pages[index].title,
                            subtitle: pages[index].subtitle,
                            systemImage: pages[index].systemImage
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                .frame(height: 400)

                // Actions
                VStack(spacing: 16) {
                    Button(action: advance) {
                        Text(page < pages.count - 1 ? "Next" : "Get Started")
                            .font(.body.bold())
                            .foregroundColor(Color(hex: "0D0D0D"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(hex: "C8963E"))
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal, 32)

                    if page < pages.count - 1 {
                        Button("Skip") {
                            onComplete()
                        }
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.4))
                    }
                }

                Spacer()
            }
        }
    }

    private func advance() {
        if page < pages.count - 1 {
            withAnimation { page += 1 }
        } else {
            onComplete()
        }
    }
}

// MARK: - OnboardingPage

struct OnboardingPage: View {

    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: systemImage)
                .font(.system(size: 72))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "C8963E"), Color(hex: "F0C060")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            VStack(spacing: 12) {
                Text(title)
                    .font(.title.bold())
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - SettingsView (stub)

/// Settings screen — full implementation is in SettingsView.swift.
/// This stub allows TeliApp.swift to compile as a standalone unit during early development.
struct SettingsView: View {

    @EnvironmentObject var settings: AppSettings

    var body: some View {
        ZStack {
            Color(hex: "0D0D0D").ignoresSafeArea()

            List {
                Section("Playback") {
                    Toggle("Haptic Feedback", isOn: $settings.hapticsEnabled)
                    HStack {
                        Text("Reverb Level")
                        Slider(value: Binding(
                            get: { max(settings.reverbLevel, 0) },
                            set: { settings.reverbLevel = $0 }
                        ), in: 0...1)
                    }
                }

                Section("Motion") {
                    Picker("Sensitivity", selection: $settings.motionSensitivity) {
                        Text("Low").tag(0)
                        Text("Medium").tag(1)
                        Text("High").tag(2)
                    }
                    .pickerStyle(.segmented)
                }

                Section("Display") {
                    Toggle("Left-Handed Mode", isOn: $settings.leftHandedMode)
                    Toggle("Reduce Motion", isOn: $settings.reduceMotion)
                }

                Section("About") {
                    NavigationLink("Credits & Licenses") {
                        CreditsView()
                    }
                    Button("Restore Purchases") {
                        // Phase 6: StoreKit restore
                    }
                    .foregroundColor(Color(hex: "C8963E"))
                    Button("Privacy Policy") {
                        UIApplication.shared.open(URL(string: "https://teliapp.com/privacy")!)
                    }
                    .foregroundColor(Color(hex: "C8963E"))
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - CreditsView (stub)

struct CreditsView: View {

    var body: some View {
        ZStack {
            Color(hex: "0D0D0D").ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Group {
                        creditSection(
                            title: "App",
                            content: "Teli v1.0.0\nDeveloped with Swift and SwiftUI."
                        )

                        creditSection(
                            title: "Audio Samples",
                            content: "All audio samples are original recordings or licensed under royalty-free terms. See /legal/sample_licenses/ for full documentation."
                        )

                        creditSection(
                            title: "Icons",
                            content: "System icons provided by SF Symbols, Apple Inc. Used in accordance with the SF Symbols license."
                        )

                        creditSection(
                            title: "Open Source",
                            content: "This app uses no third-party open-source libraries. All functionality is built on Apple first-party frameworks."
                        )

                        creditSection(
                            title: "Legal",
                            content: "Teli is an independent application and is not affiliated with or endorsed by any cultural institution. Instrument names are used for descriptive purposes only."
                        )
                    }
                }
                .padding(24)
            }
            .navigationTitle("Credits & Licenses")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func creditSection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(Color(hex: "C8963E"))
            Text(content)
                .font(.body)
                .foregroundColor(.white.opacity(0.75))
        }
    }
}

// MARK: - AVFoundation import for notification name

import AVFoundation
