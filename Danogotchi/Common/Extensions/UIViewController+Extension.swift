import UIKit

extension UIViewController {
    func showActionSheet(
        title: String? = nil,
        message: String? = nil,
        editAction: (() -> Void)? = nil,
        deleteAction: (() -> Void)? = nil
    ) {
        AlertUtils.showActionSheet(
            on: self,
            title: title,
            message: message,
            editAction: editAction,
            deleteAction: deleteAction
        )
    }
}
