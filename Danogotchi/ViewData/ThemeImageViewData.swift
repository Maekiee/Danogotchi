import Foundation


struct ThemeImageViewData: Hashable {
    let id: String
    let thumbnailUrl: String
    let aspectRatio: CGFloat
    
    init(from entity: PhotoEntity) {
        self.id = entity.id
        self.thumbnailUrl = entity.urls.thumb
        self.aspectRatio = CGFloat(entity.height) / CGFloat(entity.width)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ThemeImageViewData, rhs: ThemeImageViewData) -> Bool {
        lhs.id == rhs.id
    }
}
