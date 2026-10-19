import Foundation

struct SearchPhotoEntity {
    let total: Int
    let totalPages: Int
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
