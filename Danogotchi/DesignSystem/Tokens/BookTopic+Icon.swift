import Foundation

extension BookTopic {
    var icon: String {
        switch self {
        case .myBook:
            return "book"
        case .travel:
            return "travel"
        case .emotion:
            return "emotional"
        case .life:
            return "life"
        case .business:
            return "business"
        }
    }
}
