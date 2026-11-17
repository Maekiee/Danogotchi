import ImageIO
import UniformTypeIdentifiers
import UIKit

/// 선택 영역을 화면 규격의 불투명 이미지로 합성해 저장용 바이트를 만든다.
/// 영역이 원본을 벗어난 만큼은 검은 여백이고, 원본 픽셀이 모자라면 캔버스 전체를 줄여 업스케일하지 않는다.
///
/// 선택 영역의 픽셀 종횡비가 targetPixelSize의 종횡비와 같아야 한다 — 다르면 사진이 늘어난다.
enum ThemeImageRenderer {
    /// HEIC부터 시도하고 인코딩이 실패하면 JPEG로 넘어간다
    private static let formats: [(type: UTType, fileExtension: String)] = [(.heic, "heic"), (.jpeg, "jpg")]
    private static let compressionQuality = 0.85

    static func render(
        data: Data,
        crop: PhotoThemeCrop,
        targetPixelSize: CGSize
    ) throws -> (data: Data, fileExtension: String) {
        guard targetPixelSize.width >= 1, targetPixelSize.height >= 1 else {
            throw PhotoThemeError.invalidCrop
        }
        let cropRect = crop.rect
        let options = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, options),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? NSNumber,
              let height = properties[kCGImagePropertyPixelHeight] as? NSNumber,
              width.doubleValue > 0, height.doubleValue > 0 else {
            throw PhotoThemeError.unsupportedFormat
        }

        var sourceSize = CGSize(width: width.doubleValue, height: height.doubleValue)
        let orientation = properties[kCGImagePropertyOrientation] as? Int ?? 1
        if (5...8).contains(orientation) {
            sourceSize = CGSize(width: sourceSize.height, height: sourceSize.width)
        }
        let selectedSize = CGSize(width: sourceSize.width * cropRect.width, height: sourceSize.height * cropRect.height)
        guard selectedSize.width.isFinite, selectedSize.height.isFinite else {
            throw PhotoThemeError.invalidCrop
        }
        // ponytail: 선택 영역이 화면보다 작으면 원본 전체 디코딩(48MP ≈ 195MB), 문제 되면 디코딩 긴 변 상한 + 캔버스 축소를 썸네일 픽셀 기준으로
        let thumbnailScale = min(1, max(targetPixelSize.width / selectedSize.width, targetPixelSize.height / selectedSize.height))
        let maxPixelSize = Int(ceil(max(sourceSize.width, sourceSize.height) * thumbnailScale))
        guard let thumbnail = ImageDecoder.makeThumbnail(from: source, maxPixelSize: maxPixelSize) else {
            throw PhotoThemeError.unsupportedFormat
        }

        // 원본 픽셀이 부족하면 여백과 사진의 비율을 유지한 채 캔버스 전체 축소
        let outputScale = min(1, min(selectedSize.width / targetPixelSize.width, selectedSize.height / targetPixelSize.height))
        let outputSize = CGSize(width: max(1, floor(targetPixelSize.width * outputScale)),
                                height: max(1, floor(targetPixelSize.height * outputScale)))
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        format.preferredRange = .standard
        let rendered = UIGraphicsImageRenderer(size: outputSize, format: format).image { context in
            UIColor.black.setFill()
            context.fill(CGRect(origin: .zero, size: outputSize))
            UIImage(cgImage: thumbnail).draw(in: CGRect(
                x: -cropRect.minX * outputSize.width / cropRect.width,
                y: -cropRect.minY * outputSize.height / cropRect.height,
                width: outputSize.width / cropRect.width,
                height: outputSize.height / cropRect.height
            ))
        }
        guard let image = rendered.cgImage else { throw PhotoThemeError.encodingFailed }

        for (type, fileExtension) in formats {
            let output = NSMutableData()
            guard let destination = CGImageDestinationCreateWithData(output, type.identifier as CFString, 1, nil) else {
                continue
            }
            let encodingOptions: [CFString: Any] = [kCGImageDestinationLossyCompressionQuality: compressionQuality]
            CGImageDestinationAddImage(destination, image, encodingOptions as CFDictionary)
            if CGImageDestinationFinalize(destination) {
                return (output as Data, fileExtension)
            }
        }

        throw PhotoThemeError.encodingFailed
    }
}
