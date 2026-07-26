import Foundation

enum PartOfSpeech: String, CaseIterable {
    case verb
    case noun
    case adj
    case adv

    var title: String {
        switch self {
        case .verb:
            return "Verb"
        case .noun:
            return "Noun"
        case .adj:
            return "Adj."
        case .adv:
            return "Adv."
        }
    }
}
