import UIKit

extension UIView {
    /// 테두리(선 두께/색)와 선택적으로 모서리 곡률을 한 번에 적용한다.
    func applyBorder(width: CGFloat, color: UIColor, radius: CGFloat? = nil) {
        layer.borderWidth = width
        layer.borderColor = color.cgColor
        if let radius {
            layer.cornerRadius = radius
        }
    }
}
