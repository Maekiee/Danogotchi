import Foundation

protocol CardDisplayable {
    var cardThumbnail: String? { get }
    var cardTitle: String { get }
    var cardSubtitle: String { get }
    var cardChipText: Int? { get }
}
