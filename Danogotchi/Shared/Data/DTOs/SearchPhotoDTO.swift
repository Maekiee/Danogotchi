import Foundation

struct SearchPhotoDTO: Decodable {
    let total: Int
    let total_pages: Int
    let results: [PhotoDTO]
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

