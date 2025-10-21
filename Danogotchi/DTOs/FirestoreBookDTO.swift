import Foundation


struct FirestoreBookDTO: Decodable {
    let title: String
    let wordList: [WordItemDTO]
}
