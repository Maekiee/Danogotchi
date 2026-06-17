import Foundation

protocol CardDisplayable {
    var cardTitle: String { get }
    var cardSubtitle: String { get }
    var cardChipText: Int? { get }
    var cardAccuracy: Double? { get }
}
