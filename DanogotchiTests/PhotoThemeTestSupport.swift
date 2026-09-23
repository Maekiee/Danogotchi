import Combine
import UIKit
import XCTest
@testable import Danogotchi

final class ControlledSavePhotoThemeUseCase: SavePhotoThemeUseCase {
    private(set) var datas: [Data] = []
    private(set) var crops: [CGRect] = []
    private var pending: PassthroughSubject<Void, Error>?

    func execute(imageData: Data, crop: PhotoThemeCrop) -> AnyPublisher<Void, Error> {
        datas.append(imageData)
        crops.append(crop.rect)
        XCTAssertNil(pending, "A pending save must not be replaced by another confirm")
        // 완료된 subject는 재사용할 수 없어 호출마다 새로 만든다 — 재시도 테스트가 필요로 한다
        let subject = PassthroughSubject<Void, Error>()
        pending = subject
        return subject.eraseToAnyPublisher()
    }

    func complete(_ result: Result<Void, Error>) {
        guard let subject = pending else {
            XCTFail("No pending save")
            return
        }
        pending = nil

        switch result {
        case .success:
            subject.send(())
            subject.send(completion: .finished)
        case .failure(let error):
            subject.send(completion: .failure(error))
        }
    }
}

/// 단색 8×8 PNG — 사진첩에서 받은 바이트와 디코딩된 미리보기 한 쌍
func solidImage(color: UIColor, file: StaticString = #filePath, line: UInt = #line) throws -> (data: Data, image: UIImage) {
    let data = UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8)).pngData { context in
        color.setFill()
        context.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
    }
    return (data, try XCTUnwrap(UIImage(data: data), file: file, line: line))
}
