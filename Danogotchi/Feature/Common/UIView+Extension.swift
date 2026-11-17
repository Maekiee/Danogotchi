import UIKit

extension UIView {
    /// 테두리(선 두께/색)와 선택적으로 모서리 곡률을 한 번에 적용한다.
    /// layer.borderColor는 CGColor라 라이트/다크 전환 때 다시 칠한다 — 뷰마다 한 번만 호출
    func applyBorder(width: CGFloat, color: UIColor, radius: CGFloat? = nil) {
        layer.borderWidth = width
        layer.borderColor = color.resolvedColor(with: traitCollection).cgColor
        if let radius {
            layer.cornerRadius = radius
        }
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: UIView, _: UITraitCollection) in
            view.layer.borderColor = color.resolvedColor(with: view.traitCollection).cgColor
        }
    }
}
