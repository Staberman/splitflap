import SwiftUI

/// A line of flap tiles that never flips, drawn in one pass.
///
/// On a large board most rows never change — filler lines, closed rows, values
/// restored from disk. As `SplitFlapRow`s each of their characters is a
/// `SplitFlapTile` with its own layers, walked on every scroll frame and
/// diffed whenever anything flips elsewhere. One `Canvas` per line is one
/// layer, and on a board of a few hundred tiles that is the difference between
/// a dropped frame and a still one.
///
/// The look mirrors a resting `SplitFlapTile` tile for tile: shape, shadow,
/// the two half gradients, the type, the hairline and the stroke. Keep the two
/// in step when either changes.
public struct SplitFlapStaticRow: View {
    private let text: String
    private let theme: SplitFlapTheme
    private let tint: Color?
    private let columns: Int
    private let tileHeight: CGFloat

    public init(
        text: String,
        theme: SplitFlapTheme,
        tint: Color? = nil,
        columns: Int,
        tileHeight: CGFloat = 34
    ) {
        self.text = text
        self.theme = theme
        self.tint = tint
        self.columns = columns
        self.tileHeight = tileHeight
    }

    public var body: some View {
        Canvas { context, size in
            let width = SplitFlapRow.tileWidth(for: tileHeight)
            let pitch = width + SplitFlapRow.spacing(for: tileHeight)
            for (index, cell) in SplitFlapRow.cells(for: text, columns: columns).enumerated() {
                let tile = CGRect(x: CGFloat(index) * pitch, y: 0, width: width, height: size.height)
                draw(cell, in: tile, context: context)
            }
        }
        .frame(width: SplitFlapRow.width(columns: columns, tileHeight: tileHeight), height: tileHeight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
    }

    private func draw(_ cell: String, in tile: CGRect, context: GraphicsContext) {
        let height = tile.height
        let shape = RoundedRectangle(cornerRadius: min(38, tile.width * 0.08), style: .continuous).path(in: tile)

        // The card with its shadow first, then the face clipped to the card,
        // the way SplitFlapTile lays its background under its clipped halves.
        context.drawLayer { layer in
            layer.addFilter(.shadow(
                color: .black.opacity(0.65),
                radius: min(18, height * 0.15),
                y: min(12, height * 0.10)
            ))
            layer.fill(shape, with: .color(theme.card))
        }
        context.drawLayer { layer in
            layer.clip(to: shape)
            let top = CGRect(x: tile.minX, y: tile.minY, width: tile.width, height: height / 2)
            let bottom = CGRect(x: tile.minX, y: tile.midY, width: tile.width, height: height / 2)
            layer.fill(Path(top), with: .linearGradient(
                Gradient(colors: [.white.opacity(0.035), .black.opacity(0.08)]),
                startPoint: CGPoint(x: tile.midX, y: top.minY), endPoint: CGPoint(x: tile.midX, y: top.maxY)
            ))
            layer.fill(Path(bottom), with: .linearGradient(
                Gradient(colors: [.black.opacity(0.16), .clear]),
                startPoint: CGPoint(x: tile.midX, y: bottom.minY), endPoint: CGPoint(x: tile.midX, y: bottom.maxY)
            ))
            if cell != " " {
                layer.draw(glyph(cell, fitting: tile.width, height: height, in: layer), at: CGPoint(x: tile.midX, y: tile.midY))
            }
            // A hairline on small tiles, or the split swallows the middle of a letter.
            let hairline = max(height < 60 ? 1 : 2, height * 0.009)
            layer.fill(
                Path(CGRect(x: tile.minX, y: tile.midY - hairline / 2, width: tile.width, height: hairline)),
                with: .color(.black.opacity(0.7))
            )
        }
        context.stroke(shape, with: .color(.white.opacity(0.045)))
    }

    /// The character set as `SplitFlapTile` sets it, shrunk uniformly when
    /// wider than the tile, no further than 0.82, the way `minimumScaleFactor`
    /// does.
    private func glyph(_ cell: String, fitting width: CGFloat, height: CGFloat, in context: GraphicsContext) -> GraphicsContext.ResolvedText {
        func resolve(_ scale: CGFloat) -> GraphicsContext.ResolvedText {
            context.resolve(
                Text(cell)
                    .font(.system(size: height * 0.61 * scale, weight: .bold))
                    .fontWidth(.condensed)
                    .monospacedDigit()
                    .foregroundStyle(tint ?? theme.digit)
            )
        }
        let natural = resolve(1)
        let measured = natural.measure(in: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)).width
        guard measured > width else { return natural }
        return resolve(max(0.82, width / measured))
    }
}
