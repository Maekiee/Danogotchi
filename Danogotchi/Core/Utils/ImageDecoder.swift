import ImageIO
import UniformTypeIdentifiers
import UIKit

/// ImageIO 기반 이미지 디코딩. 파일 확장자가 아니라 내용으로 포맷을 판별하므로
/// HEIC·WebP·JPEG 어느 것이 저장돼 있든 같은 경로로 동작한다.
enum ImageDecoder {
    static func decode(fileURL: URL, maxPixelSize: Int) -> UIImage? {
        guard let source = CGImageSourceCreateWithURL(fileURL as CFURL, nil),
              let cgImage = makeThumbnail(from: source, maxPixelSize: maxPixelSize) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    static func validate(_ data: Data) -> String? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let uti = CGImageSourceGetType(source),
              let fileExtension = UTType(uti as String)?.preferredFilenameExtension else { return nil }

        guard makeThumbnail(from: source, maxPixelSize: 64) != nil else { return nil }

        return fileExtension
    }

    private static func makeThumbnail(from source: CGImageSource, maxPixelSize: Int) -> CGImage? {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }
}
