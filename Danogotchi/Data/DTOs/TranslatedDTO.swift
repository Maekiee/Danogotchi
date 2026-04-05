import Foundation

struct TranslatedDTO: Decodable {
    let translations:[TranslatedWord]
}

struct TranslatedWord: Decodable {
    let detected_source_language: String
    let text: String
}
