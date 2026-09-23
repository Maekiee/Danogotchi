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
