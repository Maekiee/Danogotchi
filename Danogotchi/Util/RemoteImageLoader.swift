import UIKit

final class RemoteImageLoader {
    private let cache = NSCache<NSURL, UIImage>()
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// 메모리에 있으면 즉시 돌려준다. 셀이 재사용될 때 깜빡임을 막는 용도.
    func cachedImage(for url: URL) -> UIImage? {
        return cache.object(forKey: url as NSURL)
    }

    func load(url: URL) async -> UIImage? {
        if let cached = cachedImage(for: url) { return cached }

        guard let (data, response) = try? await session.data(from: url),
              let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode),
              let image = UIImage(data: data) else { return nil }

        cache.setObject(image, forKey: url as NSURL)
        return image
    }
}
