import SwiftUI

/// A line of split-flap tiles, one per character, the way a departure board
/// spells a destination. The text is upper-cased and padded or cut to
/// `columns`, so every row lines up whatever it says.
///
/// When the text changes the tiles flip left to right, each column a beat
/// after the one before. A row that `cascadesOnAppear` starts blank and
/// spells itself out the same way.
///
/// ```swift
/// SplitFlapRow(text: "BUENOS AIRES", theme: .classic, columns: 14)
/// ```
public struct SplitFlapRow: View {
    private let text: String
    private let theme: SplitFlapTheme
    private let tint: Color?
    private let columns: Int
    private let tileHeight: CGFloat
    private let cascadesOnAppear: Bool
    /// How long a row that cascades on appear waits before it starts, so a
    /// board can spell its rows one after the other.
    private let cascadeDelay: TimeInterval
    /// Called once per line change, not once per tile — a board clacks once.
    private let onFlip: (@MainActor () -> Void)?

    /// The stagger between neighbouring columns.
    public static let stagger: TimeInterval = 0.045
    /// The stagger between column groups of one row, when a board lays out
    /// several rows side by side.
    public static let groupStagger: TimeInterval = 0.12

    @State private var shown: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        text: String,
        theme: SplitFlapTheme,
        tint: Color? = nil,
        columns: Int,
        tileHeight: CGFloat = 34,
        cascadesOnAppear: Bool = false,
        cascadeDelay: TimeInterval = 0,
        onFlip: (@MainActor () -> Void)? = nil
    ) {
        self.text = text
        self.theme = theme
        self.tint = tint
        self.columns = columns
        self.tileHeight = tileHeight
        self.cascadesOnAppear = cascadesOnAppear
        self.cascadeDelay = cascadeDelay
        self.onFlip = onFlip
        _shown = State(initialValue: cascadesOnAppear ? "" : text)
    }

    private var cells: [String] {
        Self.cells(for: shown, columns: columns)
    }

    /// The characters a row shows: upper-cased, cut to `columns`, then padded
    /// with blanks so a short word still fills the line.
    public static func cells(for text: String, columns: Int) -> [String] {
        let characters = Array(text.uppercased().prefix(columns)).map(String.init)
        return characters + Array(repeating: " ", count: max(0, columns - characters.count))
    }

    public var body: some View {
        HStack(spacing: Self.spacing(for: tileHeight)) {
            ForEach(Array(cells.enumerated()), id: \.offset) { index, cell in
                SplitFlapTile(
                    value: cell,
                    theme: theme,
                    tint: tint,
                    flipDelay: reduceMotion ? 0 : Double(index) * Self.stagger
                )
                .frame(width: Self.tileWidth(for: tileHeight), height: tileHeight)
            }
        }
        // The row reads as one label; the tiles are decoration.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
        .onAppear {
            guard shown != text else { return }
            // One frame of blank tiles, then the letters run in; a later row
            // waits its turn. Reduce Motion skips the wait.
            let delay = reduceMotion ? 0 : cascadeDelay
            Task { @MainActor in
                if delay > 0 { try? await Task.sleep(for: .milliseconds(Int(delay * 1000))) }
                // The text may have moved on while the row waited; the change
                // handler has spelled it already in that case.
                guard shown.isEmpty else { return }
                shown = text
            }
        }
        .onChange(of: text) { _, newValue in shown = newValue }
        .onChange(of: shown) { old, new in
            guard Self.cells(for: old, columns: columns) != Self.cells(for: new, columns: columns) else { return }
            onFlip?()
        }
    }

    /// Tiles are slightly taller than they are wide, as real flaps are.
    public static func tileWidth(for height: CGFloat) -> CGFloat { (height * 0.74).rounded() }
    public static func spacing(for height: CGFloat) -> CGFloat { max(2, (height * 0.09).rounded()) }

    /// The width a row of `columns` tiles takes at a given height.
    public static func width(columns: Int, tileHeight: CGFloat) -> CGFloat {
        CGFloat(columns) * tileWidth(for: tileHeight) + CGFloat(max(0, columns - 1)) * spacing(for: tileHeight)
    }

    /// The tallest tile that lets `columns` tiles fit in `width`, capped.
    public static func tileHeight(fitting columns: Int, in width: CGFloat, max cap: CGFloat = 34) -> CGFloat {
        var height = cap
        while height > 14, Self.width(columns: columns, tileHeight: height) > width { height -= 1 }
        return height
    }
}
