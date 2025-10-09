import UIKit

enum AlertUtils {
    static func showActionSheet(
        on viewController: UIViewController,
        title: String? = nil,
        message: String? = nil,
        editAction: (() -> Void)? = nil,
        deleteAction: (() -> Void)? = nil
    ) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .actionSheet
        )
        
        // 수정하기
        if let editAction = editAction {
            let edit = UIAlertAction(title: "수정하기", style: .default) { _ in
                editAction()
            }
            alert.addAction(edit)
        }
        
        // 지우기
        if let deleteAction = deleteAction {
            let delete = UIAlertAction(title: "지우기", style: .destructive) { _ in
                deleteAction()
            }
            alert.addAction(delete)
        }
        
        // 취소
        let cancel = UIAlertAction(title: "취소", style: .cancel)
        alert.addAction(cancel)
        
        viewController.present(alert, animated: true)
    }
    
    static func showAlert(
        on viewController: UIViewController,
        title: String,
        message: String,
        confirmTitle: String = "확인",
        cancelTitle: String = "취소",
        confirmAction: (() -> Void)?
    ) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        
        let cancel = UIAlertAction(title: cancelTitle, style: .cancel)
        
        let confirm = UIAlertAction(title: confirmTitle, style: .destructive) { _ in
            confirmAction?()
        }
        
        alert.addAction(cancel)
        alert.addAction(confirm)
        
        viewController.present(alert, animated: true)
    }
}

