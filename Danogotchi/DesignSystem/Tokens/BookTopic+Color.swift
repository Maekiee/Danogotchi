import UIKit

extension BookTopic {
    var color: UIColor {
        switch self {
        case .myBook:
            return AppColor.lavender
        case .travel:
            return AppColor.sky
        case .emotion:
            return AppColor.coral
        case .life:
            return AppColor.butter
        case .business:
            return AppColor.sage
        }
    }
}
