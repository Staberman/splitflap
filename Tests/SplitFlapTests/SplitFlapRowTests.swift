import XCTest
@testable import SplitFlap

/// The row's geometry and text handling are pure functions, so they can be
/// checked without rendering anything.
final class SplitFlapRowTests: XCTestCase {

    // MARK: - cells(for:columns:)

    func testTextIsUpperCased() {
        XCTAssertEqual(SplitFlapRow.cells(for: "ok", columns: 2), ["O", "K"])
    }

    func testShortTextIsPaddedWithBlanksSoTheRowStillLinesUp() {
        XCTAssertEqual(SplitFlapRow.cells(for: "AB", columns: 4), ["A", "B", " ", " "])
    }

    func testLongTextIsCutToTheColumnsAvailable() {
        XCTAssertEqual(SplitFlapRow.cells(for: "ABCDE", columns: 3), ["A", "B", "C"])
    }

    func testAnEmptyRowIsAllBlanks() {
        XCTAssertEqual(SplitFlapRow.cells(for: "", columns: 3), [" ", " ", " "])
    }

    func testZeroColumnsProducesNoCellsRatherThanCrashing() {
        XCTAssertEqual(SplitFlapRow.cells(for: "ABC", columns: 0), [])
    }

    func testAlwaysReturnsExactlyOneCellPerColumn() {
        for columns in 0...20 {
            for text in ["", "A", "AB", "HELLO", "A VERY LONG DESTINATION NAME"] {
                XCTAssertEqual(
                    SplitFlapRow.cells(for: text, columns: columns).count,
                    columns,
                    "\(columns) columns showing \(text.debugDescription)"
                )
            }
        }
    }

    // MARK: - geometry

    func testTilesAreTallerThanTheyAreWideAsRealFlapsAre() {
        XCTAssertLessThan(SplitFlapRow.tileWidth(for: 100), 100)
    }

    func testSpacingNeverCollapsesBelowTwoPointsOnTinyTiles() {
        XCTAssertGreaterThanOrEqual(SplitFlapRow.spacing(for: 1), 2)
    }

    func testWidthCountsTheGapsBetweenTilesButNotAroundThem() {
        let height: CGFloat = 34
        let expected = 3 * SplitFlapRow.tileWidth(for: height) + 2 * SplitFlapRow.spacing(for: height)
        XCTAssertEqual(SplitFlapRow.width(columns: 3, tileHeight: height), expected)
    }

    func testASingleTileHasNoGaps() {
        XCTAssertEqual(
            SplitFlapRow.width(columns: 1, tileHeight: 34),
            SplitFlapRow.tileWidth(for: 34)
        )
    }

    // MARK: - tileHeight(fitting:in:max:)

    func testTheFittedRowActuallyFitsTheWidthItWasGiven() {
        let available: CGFloat = 200
        let height = SplitFlapRow.tileHeight(fitting: 8, in: available)
        XCTAssertLessThanOrEqual(SplitFlapRow.width(columns: 8, tileHeight: height), available)
    }

    func testAGenerousWidthKeepsTheCapRatherThanGrowingPastIt() {
        XCTAssertEqual(SplitFlapRow.tileHeight(fitting: 2, in: 10_000, max: 34), 34)
    }

    func testAnImpossibleWidthStopsAtTheFloorInsteadOfLooping() {
        XCTAssertEqual(SplitFlapRow.tileHeight(fitting: 40, in: 1), 14)
    }

    // MARK: - themes

    func testBundledThemesHaveUniqueIdentifiers() {
        let ids = SplitFlapTheme.all.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count)
    }
}
