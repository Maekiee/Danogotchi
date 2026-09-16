import Foundation

enum PhotoThemeError: Error {
    /// 사진첩에서 바이트를 못 가져왔다 (iCloud 원본 다운로드 실패 포함)
    case transferFailed
    /// ImageIO가 디코딩하지 못하는 포맷
    case unsupportedFormat
}
