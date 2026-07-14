import Foundation

enum BookTopic: CaseIterable, Hashable {
    case myBook
    case travel
    case emotion
    case life
    case business
    
    var title: String {
        switch self {
        case .myBook:
            return "My Vocabulary"
        case .travel:
            return "Travel"
        case .emotion:
            return "Emotion"
        case .life:
            return "Life"
        case .business:
            return "Business"
        }
    }

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
    
    var recommendBookId: String? {
        switch self {
        case .myBook: return nil
        case .travel: return "rec_travel_001"
        case .emotion: return "rec_emotion_003"
        case .life: return "rec_life_004"
        case .business: return "rec_business_002"
        }
    }
}
