import SwiftUI

/// A single split-flap tile. It shows one character, and when that character
/// changes the top half falls away to reveal the next one, the way the leaf
/// of a mechanical departure board does.
///
/// Give it a frame — the tile fills whatever it is handed:
///
/// ```swift
/// SplitFlapTile(value: "7", theme: .classic)
///     .frame(width: 44, height: 60)
/// ```
public struct SplitFlapTile: View {
    private let value: String
    private let theme: SplitFlapTheme
    /// Replaces the theme's digit colour, for tiles whose colour carries meaning.
    private let tint: Color?
    /// How long the flip waits before it starts. A row hands each tile its own
    /// delay, so the letters run across the board left to right.
    private let flipDelay: TimeInterval
    /// Called on the main actor each time this tile begins a flip. Hook a
    /// clack, a haptic, or nothing at all — the tile has no opinion.
    private let onFlip: (@MainActor () -> Void)?

    @State private var previous: String
    @State private var topAngle = 0.0
    @State private var bottomAngle = 90.0
    @State private var resetTask: Task<Void, Never>?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        value: String,
        theme: SplitFlapTheme,
        tint: Color? = nil,
        flipDelay: TimeInterval = 0,
        onFlip: (@MainActor () -> Void)? = nil
    ) {
        self.value = value
        self.theme = theme
        self.tint = tint
        self.flipDelay = flipDelay
        self.onFlip = onFlip
        // Seeded, not set in onAppear: a placeholder would make every tile on
        // the board write state and lay out a second time on its first frame.
        _previous = State(initialValue: value)
    }

    /// A tile that is not mid-flip. Both rotated halves are then redundant:
    /// the top one is a pixel-identical copy of the face already drawn, and
    /// the bottom one stands at 90°, edge on, so it covers nothing. Most of
    /// a board is in this state, and blank filler tiles never leave it.
    private var isResting: Bool {
        previous == value && topAngle == 0 && bottomAngle == 90
    }

    public var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let shape = RoundedRectangle(cornerRadius: min(38, size.width * 0.08), style: .continuous)
            ZStack {
                half(value, .top, size)
                half(previous, .bottom, size)
                if !isResting {
                    half(previous, .top, size)
                        .rotation3DEffect(.degrees(topAngle), axis: (1, 0, 0), anchor: .bottom, perspective: 0.65)
                        .zIndex(topAngle > -88 ? 3 : 0)
                    half(value, .bottom, size)
                        .rotation3DEffect(.degrees(bottomAngle), axis: (1, 0, 0), anchor: .top, perspective: 0.65)
                        .zIndex(bottomAngle < 72 ? 4 : 1)
                }
                // A hairline on small tiles, or the split swallows the middle of a letter.
                Rectangle()
                    .fill(.black.opacity(0.7))
                    .frame(height: max(size.height < 60 ? 1 : 2, size.height * 0.009))
                    .zIndex(8)
            }
            .frame(width: size.width, height: size.height)
            // Clip first, then lay the shadow on the shape behind it. A shadow
            // on the composited tile has to be blurred off screen every frame;
            // one on a filled shape does not. The radius follows the tile, so a
            // 23pt board tile stops wearing the 18pt blur meant for a big clock.
            .clipShape(shape)
            .background(
                shape.fill(
                    theme.card.shadow(
                        .drop(
                            color: .black.opacity(0.65),
                            radius: min(18, size.height * 0.15),
                            y: min(12, size.height * 0.10)
                        )
                    )
                )
            )
            .overlay(shape.stroke(.white.opacity(0.045)))
        }
        .onChange(of: value) { _, newValue in animate(to: newValue) }
        .accessibilityLabel(value)
    }

    private enum Half { case top, bottom }

    private func half(_ text: String, _ half: Half, _ size: CGSize) -> some View {
        ZStack {
            theme.card
            LinearGradient(
                colors: half == .top
                    ? [.white.opacity(0.035), .black.opacity(0.08)]
                    : [.black.opacity(0.16), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            Text(text)
                .font(.system(size: size.height * 0.61, weight: .bold, design: .default))
                .fontWidth(.condensed)
                .monospacedDigit()
                .minimumScaleFactor(0.82)
                .foregroundStyle(tint ?? theme.digit)
                .frame(width: size.width, height: size.height)
                .offset(y: half == .top ? size.height / 4 : -size.height / 4)
        }
        .frame(width: size.width, height: size.height / 2)
        .clipped()
        .offset(y: half == .top ? -size.height / 4 : size.height / 4)
    }

    private func animate(to newValue: String) {
        guard newValue != previous else {
            // The value went out and came back inside one flip. The face is
            // already right; settle the angles too, or the tile would sit
            // mid-flip for good and keep paying for both rotated halves.
            resetTask?.cancel()
            topAngle = 0
            bottomAngle = 90
            return
        }
        onFlip?()
        resetTask?.cancel()

        guard !reduceMotion else {
            previous = newValue
            topAngle = 0
            bottomAngle = 90
            return
        }

        topAngle = 0
        bottomAngle = 90
        withAnimation(.timingCurve(0.42, 0, 0.68, 1, duration: 0.17).delay(flipDelay)) {
            topAngle = -90
        }
        withAnimation(.interpolatingSpring(stiffness: 345, damping: 27).delay(0.145 + flipDelay)) {
            bottomAngle = 0
        }

        resetTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(430 + Int(flipDelay * 1000)))
            guard !Task.isCancelled else { return }
            previous = newValue
            topAngle = 0
            bottomAngle = 90
        }
    }
}
