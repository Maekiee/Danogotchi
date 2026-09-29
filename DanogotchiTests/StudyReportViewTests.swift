import SwiftUI
import XCTest
@testable import Danogotchi

@MainActor
final class StudyReportViewTests: XCTestCase {
    func test_answerBarEmptyAndSingleOutcomeRenderAtCompactHeight() throws {
        let empty = try renderBar(total: 0, wrong: 0)
        let correct = try renderBar(total: 10, wrong: 0)
        let wrong = try renderBar(total: 10, wrong: 10)
        for image in [empty, correct, wrong] {
            XCTAssertEqual(image.size.height, 20)
        }
        XCTAssertTrue(try matchesPixel(correct, x: 30, color: AppColor.appGreen))
        XCTAssertTrue(try matchesPixel(wrong, x: 30, color: AppColor.appRed))
        XCTAssertFalse(try matchesPixel(empty, x: 30, color: AppColor.appGreen))
        XCTAssertFalse(try matchesPixel(empty, x: 30, color: AppColor.appRed))
    }

    func test_answerBarMixedOutcomesKeepTheirProportion() throws {
        let image = try renderBar(total: 342, wrong: 75)
        XCTAssertTrue(try matchesPixel(image, x: 230, color: AppColor.appGreen))
        XCTAssertTrue(try matchesPixel(image, x: 270, color: AppColor.appRed))
    }

    func test_answerBarRareOutcomesDoNotExaggerateTheirShare() throws {
        let almostCorrect = try renderBar(total: 1000, wrong: 1)
        let almostWrong = try renderBar(total: 1000, wrong: 999)
        XCTAssertTrue(try matchesPixel(almostCorrect, x: 275, color: AppColor.appGreen),
                      "오답 0.1%인데 막대의 86% 지점이 빨간색으로 표시됨")
        XCTAssertTrue(try matchesPixel(almostWrong, x: 40, color: AppColor.appRed),
                      "정답 0.1%인데 막대의 12.5% 지점까지 초록색으로 표시됨")
    }

    private func renderBar(total: Int, wrong: Int) throws -> UIImage {
        let renderer = ImageRenderer(content: StudyReportAnswerBar(total: total, wrong: wrong)
            .frame(width: 320)
            .environment(\.colorScheme, .light))
        renderer.scale = 1
        let image = try XCTUnwrap(renderer.uiImage)
        let attachment = XCTAttachment(image: image)
        attachment.name = "answer-bar-\(total)-\(wrong)"
        attachment.lifetime = .keepAlways
        add(attachment)
        return image
    }

    private func matchesPixel(_ image: UIImage, x: Int, color: UIColor) throws -> Bool {
        let cgImage = try XCTUnwrap(image.cgImage)
        let width = cgImage.width
        let height = cgImage.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        try pixels.withUnsafeMutableBytes { buffer in
            let context = try XCTUnwrap(CGContext(
                data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ))
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        }
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
            .getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let offset = (height / 2 * width + x) * 4
        return zip(pixels[offset..<(offset + 3)], [red, green, blue])
            .allSatisfy { abs(CGFloat($0.0) / 255 - $0.1) < 0.03 }
    }
}
