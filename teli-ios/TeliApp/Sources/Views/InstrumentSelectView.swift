import SwiftUI

// MARK: - InstrumentSelectView

/// The app's home screen. Displays all available instruments as selectable cards.
/// Locked instruments (future IAP) are shown but disabled.
struct InstrumentSelectView: View {

    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            ZStack {
                // Full-screen dark background
                Color(hex: "0D0D0D")
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    headerSection
                    instrumentList
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                            .foregroundColor(Color(hex: "C8963E"))
                            .accessibilityLabel("Settings")
                    }
                }
            }
        }
    }

    // MARK: - Subviews

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Teli")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "C8963E"), Color(hex: "F0C060")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .accessibilityAddTraits(.isHeader)

            Text("Play with Motion")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.55))
        }
        .padding(.top, 48)
        .padding(.bottom, 32)
    }

    private var instrumentList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(appState.instruments) { instrument in
                    if instrument.isUnlocked {
                        NavigationLink(destination: PlayView(instrument: instrument)) {
                            InstrumentCard(instrument: instrument, isLocked: false)
                        }
                        .accessibilityLabel("\(instrument.displayName), \(instrument.category) instrument")
                        .accessibilityHint("Double tap to open \(instrument.displayName) play screen")
                    } else {
                        InstrumentCard(instrument: instrument, isLocked: true)
                            .accessibilityLabel("\(instrument.displayName), locked")
                            .accessibilityHint("Purchase required to unlock this instrument")
                    }
                }

                // Expansion slot placeholder
                ExpansionSlotCard()
                    .padding(.top, 8)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - InstrumentCard

struct InstrumentCard: View {

    let instrument: InstrumentConfig
    let isLocked: Bool

    var body: some View {
        HStack(spacing: 16) {
            // Instrument thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "C8963E").opacity(isLocked ? 0.1 : 0.2))
                    .frame(width: 64, height: 64)

                Image(instrument.id)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)
                    .opacity(isLocked ? 0.4 : 1.0)
            }

            // Instrument info
            VStack(alignment: .leading, spacing: 4) {
                Text(instrument.displayName)
                    .font(.title3.bold())
                    .foregroundColor(isLocked ? .white.opacity(0.4) : .white)

                Text(instrument.category.capitalized)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.4))
            }

            Spacer()

            // Right icon
            if isLocked {
                Image(systemName: "lock.fill")
                    .foregroundColor(.white.opacity(0.3))
                    .font(.body)
            } else {
                Image(systemName: "chevron.right")
                    .foregroundColor(Color(hex: "C8963E"))
                    .font(.body.weight(.semibold))
            }
        }
        .padding(20)
        .frame(minHeight: 80)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    Color(hex: "C8963E").opacity(isLocked ? 0.1 : 0.3),
                    lineWidth: 1
                )
        )
        .contentShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - ExpansionSlotCard

struct ExpansionSlotCard: View {

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 64, height: 64)

                Image(systemName: "plus.circle.dashed")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.25))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("More Instruments")
                    .font(.title3.bold())
                    .foregroundColor(.white.opacity(0.3))

                Text("Coming soon")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.2))
            }

            Spacer()
        }
        .padding(20)
        .frame(minHeight: 80)
        .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
        )
        .accessibilityLabel("More instruments coming soon")
        .accessibilityAddTraits(.isStaticText)
    }
}

// MARK: - Color Extension

extension Color {
    /// Initialize from a 6-character hex string (without `#`).
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)

        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}
