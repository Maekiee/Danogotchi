import Foundation

struct SearchPhotoDTO: Decodable {
    let total: Int
    let totalPages: Int
    let results: [PhotoDTO]

    enum CodingKeys: String, CodingKey {
        case total, results
        case totalPages = "total_pages"
    }
}

extension SearchPhotoDTO {
    func toEntity() -> SearchPhotoEntity {
        return SearchPhotoEntity(
            total: total,
            totalPages: totalPages,
            results: results.map { $0.toEntity() }
        )
    }
}

