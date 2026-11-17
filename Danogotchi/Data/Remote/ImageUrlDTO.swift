import Foundation

struct ImageURLDTO: Decodable {
    let raw: String
    let small: String
    let full: String
    let regular: String
    let thumb: String
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
