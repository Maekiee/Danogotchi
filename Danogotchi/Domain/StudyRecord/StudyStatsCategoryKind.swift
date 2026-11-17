import Foundation

enum StudyStatsCategoryKind: Sendable {
    case topic, partOfSpeech

    // 화면 표시 순서 고정, 모르는 값은 unknown으로 모은다
    var identifiers: [String] {
        switch self {
        case .topic: return [BookTopic.travel, .business, .emotion, .life].map(\.rawValue) + ["unknown"]
        case .partOfSpeech: return [PartOfSpeech.noun, .verb, .adj, .adv].map(\.rawValue) + ["unknown"]
        }
    }

    func identifier(_ rawValue: String?) -> String {
        guard let rawValue, identifiers.contains(rawValue) else { return "unknown" }
        return rawValue
    }
}
