import Foundation


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
    let raw: String // 원본 이미지 링크
    let small: String // 작은 이미지 링크
}
