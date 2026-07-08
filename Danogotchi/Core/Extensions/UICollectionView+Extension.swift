import UIKit

extension UICollectionView {
    func setView(title: String) {
        let titleLabel: UILabel = {
            let label = UILabel()
            label.text = title
            label.textAlignment = .center
            label.textColor = AppColor.textPrimary
            label.font = AppFont.footnote
            return label
        }()
        self.backgroundView = titleLabel
    }
    
    func restore() {
        self.backgroundView = nil
    }
}
