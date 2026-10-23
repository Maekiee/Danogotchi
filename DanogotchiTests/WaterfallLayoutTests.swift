import UIKit
import XCTest
@testable import Danogotchi

@MainActor
final class WaterfallLayoutTests: XCTestCase {
    private final class GridSource: NSObject, UICollectionViewDataSource, WaterfallLayoutDelegate {
        var heights: [CGFloat]
        private(set) var requestedWidths: [CGFloat] = []

        init(heights: [CGFloat]) { self.heights = heights }

        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { heights.count }

        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        }

        func collectionView(_ collectionView: UICollectionView, heightForItemAt indexPath: IndexPath, width: CGFloat) -> CGFloat {
            requestedWidths.append(width)
            return heights[indexPath.item]
        }
    }

    private struct Fixture {
        let layout: WaterfallLayout
        let collectionView: UICollectionView
        let source: GridSource

        func frame(_ item: Int) -> CGRect? {
            layout.layoutAttributesForItem(at: IndexPath(item: item, section: 0))?.frame
        }
    }

    /// 폭 200 → 열 폭 100, 셀 패딩 8
    private func makeFixture(heights: [CGFloat], usesDelegate: Bool = true) -> Fixture {
        let layout = WaterfallLayout()
        let collectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: 200, height: 600), collectionViewLayout: layout)
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        let source = GridSource(heights: heights)
        collectionView.dataSource = source
        layout.delegate = usesDelegate ? source : nil
        collectionView.reloadData()
        collectionView.layoutIfNeeded()
        layout.prepare()
        return Fixture(layout: layout, collectionView: collectionView, source: source)
    }

    func test_itemsFillTwoColumnsAndEachGoesToShortestColumn() {
        let fixture = makeFixture(heights: [100, 50, 30])

        // 첫 항목은 0열, 둘째는 비어 있는 1열, 셋째는 더 짧은 1열 아래로
        XCTAssertEqual(fixture.frame(0), CGRect(x: 8, y: 8, width: 84, height: 100))
        XCTAssertEqual(fixture.frame(1), CGRect(x: 108, y: 8, width: 84, height: 50))
        XCTAssertEqual(fixture.frame(2), CGRect(x: 108, y: 74, width: 84, height: 30))
        // 0열 116(100+패딩16) vs 1열 66+46=112 — 긴 열이 콘텐츠 높이다
        XCTAssertEqual(fixture.layout.collectionViewContentSize, CGSize(width: 200, height: 116))
        XCTAssertEqual(Set(fixture.source.requestedWidths), [84])
    }

    func test_tallFirstColumnKeepsReceivingItemsOnlyWhenShorter() {
        let fixture = makeFixture(heights: [20, 300, 20, 20])

        XCTAssertEqual(fixture.frame(0)?.origin.x, 8)
        XCTAssertEqual(fixture.frame(1)?.origin.x, 108)
        XCTAssertEqual(fixture.frame(2)?.origin, CGPoint(x: 8, y: 44))
        XCTAssertEqual(fixture.frame(3)?.origin, CGPoint(x: 8, y: 80))
        XCTAssertEqual(fixture.layout.collectionViewContentSize.height, 316)
    }

    func test_missingDelegateFallsBackToDefaultHeight() {
        let fixture = makeFixture(heights: [10, 10], usesDelegate: false)

        XCTAssertEqual(fixture.frame(0)?.height, 200)
        XCTAssertEqual(fixture.frame(1)?.height, 200)
        XCTAssertTrue(fixture.source.requestedWidths.isEmpty)
    }

    func test_visibleRectReturnsOnlyIntersectingItems() {
        let fixture = makeFixture(heights: [100, 100, 500, 500])

        let visible = fixture.layout.layoutAttributesForElements(in: CGRect(x: 0, y: 0, width: 200, height: 100))
        XCTAssertEqual(visible?.map(\.indexPath.item).sorted(), [0, 1])

        let lower = fixture.layout.layoutAttributesForElements(in: CGRect(x: 0, y: 500, width: 200, height: 100))
        XCTAssertEqual(lower?.map(\.indexPath.item).sorted(), [2, 3])
    }

    func test_invalidateLayoutRecomputesWithNewHeights() {
        let fixture = makeFixture(heights: [100, 50])
        XCTAssertEqual(fixture.frame(1)?.height, 50)

        fixture.source.heights = [100, 250]
        fixture.layout.invalidateLayout()
        fixture.layout.prepare()

        XCTAssertEqual(fixture.frame(1)?.height, 250)
        XCTAssertEqual(fixture.layout.collectionViewContentSize.height, 266)
    }
}
