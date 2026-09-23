import SwiftUI
import UIKit

struct PhotoCropView: UIViewRepresentable {
    let image: UIImage
    let onCropChanged: (CGRect) -> Void

    func makeUIView(context: Context) -> PhotoCropScrollView {
        PhotoCropScrollView(frame: .zero)
    }

    func updateUIView(_ view: PhotoCropScrollView, context: Context) {
        view.isUserInteractionEnabled = context.environment.isEnabled
        view.onCropChanged = { rect in
            // UIKit 레이아웃 중 SwiftUI 상태 변경 방지
            DispatchQueue.main.async { onCropChanged(rect) }
        }
        view.setImage(image)
    }
}

final class PhotoCropScrollView: UIScrollView, UIScrollViewDelegate {
    var onCropChanged: ((CGRect) -> Void)?
    private let imageView = UIImageView()
    private var needsImageReset = false
    private var isConfiguring = false
    private var viewportSize = CGSize.zero
    private var fillZoomScale: CGFloat = 1
    private(set) var cropRect: CGRect?

    override var isUserInteractionEnabled: Bool {
        didSet {
            isScrollEnabled = isUserInteractionEnabled
            if !isUserInteractionEnabled {
                setContentOffset(contentOffset, animated: false)
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        delegate = self
        bounces = false
        bouncesZoom = false
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        contentInsetAdjustmentBehavior = .never
        backgroundColor = .black
        clipsToBounds = true
        addSubview(imageView)
        isAccessibilityElement = true
        accessibilityLabel = "배경 사진 영역"
        accessibilityHint = "확대하거나 선택 영역을 이동해 배경 구도를 조절하세요"
        accessibilityTraits = [.image, .adjustable]
        accessibilityCustomActions = [
            UIAccessibilityCustomAction(name: "확대", target: self, selector: #selector(zoomIn)),
            UIAccessibilityCustomAction(name: "축소", target: self, selector: #selector(zoomOut)),
            UIAccessibilityCustomAction(name: "선택 영역 왼쪽으로", target: self, selector: #selector(moveLeft)),
            UIAccessibilityCustomAction(name: "선택 영역 오른쪽으로", target: self, selector: #selector(moveRight)),
            UIAccessibilityCustomAction(name: "선택 영역 위로", target: self, selector: #selector(moveUp)),
            UIAccessibilityCustomAction(name: "선택 영역 아래로", target: self, selector: #selector(moveDown))
        ]
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setImage(_ image: UIImage) {
        guard imageView.image !== image else { return }
        imageView.image = image
        needsImageReset = true
        cropRect = nil
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard !isConfiguring, let image = imageView.image,
              image.size.width > 0, image.size.height > 0,
              bounds.width > 0, bounds.height > 0,
              needsImageReset || viewportSize != bounds.size else { return }

        let center = cropRect.map { CGPoint(x: $0.midX, y: $0.midY) } ?? CGPoint(x: 0.5, y: 0.5)
        let relativeZoom = needsImageReset ? 1 : zoomScale / fillZoomScale
        isConfiguring = true
        minimumZoomScale = 1
        maximumZoomScale = 1
        setZoomScale(1, animated: false)
        imageView.transform = .identity
        imageView.frame = CGRect(origin: .zero, size: image.size)
        contentSize = image.size

        fillZoomScale = max(bounds.width / image.size.width, bounds.height / image.size.height)
        let minimum = min(bounds.width / image.size.width, bounds.height / image.size.height) * 0.25
        minimumZoomScale = minimum
        maximumZoomScale = fillZoomScale * 4
        // 각 방향으로 사진 전체가 화면 밖에 나갈 수 있는 이동 여백
        contentInset = UIEdgeInsets(top: bounds.height, left: bounds.width,
                                   bottom: bounds.height, right: bounds.width)
        setZoomScale(min(maximumZoomScale, max(minimum, fillZoomScale * relativeZoom)), animated: false)
        contentSize = imageView.frame.size
        setContentOffset(clampedOffset(CGPoint(
            x: center.x * contentSize.width - bounds.width / 2,
            y: center.y * contentSize.height - bounds.height / 2
        )), animated: false)
        viewportSize = bounds.size
        needsImageReset = false
        isConfiguring = false
        reportCrop()
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? { imageView }
    func scrollViewDidZoom(_ scrollView: UIScrollView) { reportCrop() }
    func scrollViewDidScroll(_ scrollView: UIScrollView) { reportCrop() }

    private func clampedOffset(_ offset: CGPoint) -> CGPoint {
        CGPoint(x: min(max(-contentInset.left, offset.x), contentSize.width - bounds.width + contentInset.right),
                y: min(max(-contentInset.top, offset.y), contentSize.height - bounds.height + contentInset.bottom))
    }

    private func reportCrop() {
        guard !isConfiguring, !needsImageReset, viewportSize == bounds.size,
              imageView.bounds.width > 0, imageView.bounds.height > 0 else { return }
        let visible = imageView.convert(bounds, from: self)
        let rect = CGRect(x: visible.minX / imageView.bounds.width,
                          y: visible.minY / imageView.bounds.height,
                          width: visible.width / imageView.bounds.width,
                          height: visible.height / imageView.bounds.height)
        guard cropRect != rect else { return }
        cropRect = rect
        accessibilityValue = String(format: "%.2f배", zoomScale / fillZoomScale)
        onCropChanged?(rect)
    }

    private func changeZoom(by factor: CGFloat) {
        guard isUserInteractionEnabled, let cropRect else { return }
        isConfiguring = true
        setZoomScale(min(maximumZoomScale, max(minimumZoomScale, zoomScale * factor)), animated: false)
        contentSize = imageView.frame.size
        setContentOffset(clampedOffset(CGPoint(
            x: cropRect.midX * contentSize.width - bounds.width / 2,
            y: cropRect.midY * contentSize.height - bounds.height / 2
        )), animated: false)
        isConfiguring = false
        reportCrop()
    }

    private func moveSelection(x: CGFloat, y: CGFloat) -> Bool {
        guard isUserInteractionEnabled else { return false }
        setContentOffset(clampedOffset(CGPoint(x: contentOffset.x + bounds.width * x,
                                              y: contentOffset.y + bounds.height * y)), animated: false)
        return true
    }

    override func accessibilityIncrement() { changeZoom(by: 1.25) }
    override func accessibilityDecrement() { changeZoom(by: 0.8) }
    override func accessibilityScroll(_ direction: UIAccessibilityScrollDirection) -> Bool {
        switch direction {
        case .left: return moveSelection(x: -0.1, y: 0)
        case .right: return moveSelection(x: 0.1, y: 0)
        case .up: return moveSelection(x: 0, y: -0.1)
        case .down: return moveSelection(x: 0, y: 0.1)
        default: return false
        }
    }
    @objc private func zoomIn() -> Bool {
        guard isUserInteractionEnabled else { return false }
        accessibilityIncrement()
        return true
    }
    @objc private func zoomOut() -> Bool {
        guard isUserInteractionEnabled else { return false }
        accessibilityDecrement()
        return true
    }
    @objc private func moveLeft() -> Bool { moveSelection(x: -0.1, y: 0) }
    @objc private func moveRight() -> Bool { moveSelection(x: 0.1, y: 0) }
    @objc private func moveUp() -> Bool { moveSelection(x: 0, y: -0.1) }
    @objc private func moveDown() -> Bool { moveSelection(x: 0, y: 0.1) }
}
