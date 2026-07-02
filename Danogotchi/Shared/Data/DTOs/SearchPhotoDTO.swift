import Foundation

//
struct SearchPhotoDTO: Decodable {
    let total: Int
    let total_pages: Int
    let results: [PhotoDTO]
}

struct PhotoDTO: Decodable {
    let id: String
    let width: Int
    let height: Int
    let urls: ImageURLDTO
    
}

struct ImageURLDTO: Decodable {
    let raw: String
    let small: String
    let full: String
    let regular: String
    let thumb: String
}

extension SearchPhotoDTO {
    func toEntity() -> SearchPhotoEntity {
        return SearchPhotoEntity(
            total: total,
            total_pages: total_pages,
            results: results.map { $0.toEntity() }
        )
    }
}


extension PhotoDTO {
    func toEntity() -> PhotoEntity {
        return PhotoEntity(
            id: id,
            width: width,
            height: height,
            urls: urls.toEntity()
        )
    }
}

extension ImageURLDTO {
    func toEntity() -> ImageURLEntity {
        return ImageURLEntity(
            raw: raw,
            small: small,
            full: full,
            regular: regular,
            thumb: thumb
        )
    }
}
