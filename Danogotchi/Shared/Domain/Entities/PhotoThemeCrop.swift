import CoreGraphics

/// 회전 보정된 원본 기준 정규화 미리보기 영역 — 0...1 밖은 검은 여백이다.
/// 저장할 수 없는 영역은 아예 만들어지지 않아 화면과 저장이 같은 규칙을 공유한다.
struct PhotoThemeCrop: Equatable {
    let rect: CGRect

    /// 유한하지 않거나, 면적이 없거나, 원본과 겹치지 않으면 만들 수 없다
    init?(_ rect: CGRect) {
        guard [rect.origin.x, rect.origin.y, rect.size.width, rect.size.height,
               rect.maxX, rect.maxY].allSatisfy({ $0.isFinite }),
              rect.size.width > 0, rect.size.height > 0,
              rect.minX < 1, rect.maxX > 0,
              rect.minY < 1, rect.maxY > 0 else { return nil }
        self.rect = rect
    }
}
