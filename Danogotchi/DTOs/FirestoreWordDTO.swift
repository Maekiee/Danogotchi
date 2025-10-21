import Foundation


struct WordItemDTO: Decodable {
    let meaning: String
    let thumbnailUrl: String?
    let word: String
}
