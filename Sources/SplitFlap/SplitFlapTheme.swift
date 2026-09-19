import SwiftUI

/// The two colours a flap board needs: the card the tile is cut from, and the
/// type printed on it. Everything else a board might want — a backdrop, an
/// accent — belongs to the app around it, not here.
public struct SplitFlapTheme: Identifiable, Hashable, Sendable {
    public let id: String
    /// The face of the tile.
    public let card: Color
    /// The character printed on it.
    public let digit: Color

    public init(id: String, card: Color, digit: Color) {
        self.id = id
        self.card = card
        self.digit = digit
    }
}

public extension SplitFlapTheme {
    /// Black cards, bone-white type — the airport board everyone pictures.
    static let classic = SplitFlapTheme(
        id: "classic",
        card: Color(white: 0.105),
        digit: Color(white: 0.96)
    )

    /// Ivory cards and dark type, for a light room.
    static let daylight = SplitFlapTheme(
        id: "daylight",
        card: Color(white: 0.97),
        digit: .black
    )

    /// Deep blue, easy on the eyes after dark.
    static let midnight = SplitFlapTheme(
        id: "midnight",
        card: Color(red: 0.055, green: 0.105, blue: 0.22),
        digit: Color(red: 0.55, green: 0.70, blue: 1)
    )

    /// Warm seventies card stock.
    static let retro = SplitFlapTheme(
        id: "retro",
        card: Color(red: 0.88, green: 0.82, blue: 0.66),
        digit: Color(red: 0.17, green: 0.12, blue: 0.07)
    )

    /// The bundled themes, in no particular order.
    static let all: [SplitFlapTheme] = [.classic, .daylight, .midnight, .retro]
}
