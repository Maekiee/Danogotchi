import Foundation

enum PhotoThemeError: Error {
    /// 사진첩에서 바이트를 못 가져왔다 (iCloud 원본 다운로드 실패 포함)
    case transferFailed
    /// ImageIO가 디코딩하지 못하는 포맷
    case unsupportedFormat
    /// 다운샘플링한 이미지의 파일 인코딩 실패
    case encodingFailed
    /// 화면 규격과 조합해 캔버스를 계산할 수 없는 영역
    case invalidCrop
}

// MARK: - Crashlytics 이슈 묶음 — code는 case 순서와 무관한 고정 값
extension PhotoThemeError: CustomNSError {
    static var errorDomain: String { "danogotchi.photo_theme" }

    var errorCode: Int {
        switch self {
        case .transferFailed: return 1
        case .unsupportedFormat: return 2
        case .encodingFailed: return 3
        case .invalidCrop: return 4
        }
    }
}
