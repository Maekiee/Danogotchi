import Foundation

struct SearchPhotoEntity {
    let total: Int
    let total_pages: Int
    let results: [PhotoEntity]
}

struct PhotoEntity {
    let id: String
    let width: Int
    let height: Int
    let urls: ImageURLEntity
}

struct ImageURLEntity {
    let raw: String
    let small: String
    let full: String
    let regular: String
    let thumb: String
}
