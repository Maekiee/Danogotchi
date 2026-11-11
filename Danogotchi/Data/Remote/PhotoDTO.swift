import Foundation

struct PhotoDTO: Decodable {
    let id: String
    let width: Int
    let height: Int
    let urls: ImageURLDTO
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
