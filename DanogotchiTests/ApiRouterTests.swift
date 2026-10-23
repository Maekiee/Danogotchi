import Foundation
import XCTest
@testable import Danogotchi

final class ApiRouterTests: XCTestCase {
    func test_weatherRouterBuildsCurrentWeatherQuery() throws {
        let router = WeatherApiRouter.currentWeather(lat: 37.5665, lon: 126.978)

        XCTAssertEqual(router.baseURL, APIConfig.Weather.baseURL)
        XCTAssertEqual(router.path, "/weather")
        XCTAssertEqual(router.method, .get)
        XCTAssertNil(router.body)

        let query = try queryDictionary(router.queryItems)
        XCTAssertEqual(query["lat"], "37.5665")
        XCTAssertEqual(query["lon"], "126.978")
        XCTAssertEqual(query["units"], "metric")
        XCTAssertEqual(query["lang"], "kr")
        XCTAssertEqual(query["appid"], APIConfig.Weather.apiKey)
        XCTAssertEqual(query.count, 5)
    }

    func test_unsplashRouterBuildsSearchQueryAndAuthHeader() throws {
        let router = UnsplashApiRouter.searchPhoto(query: "sea & sky", page: 3)

        XCTAssertEqual(router.baseURL, APIConfig.Unsplash.baseURL)
        XCTAssertEqual(router.path, "/search/photos")
        XCTAssertEqual(router.method, .get)

        let query = try queryDictionary(router.queryItems)
        XCTAssertEqual(query["query"], "sea & sky")
        XCTAssertEqual(query["page"], "3")
        XCTAssertEqual(query["per_page"], "20")
        XCTAssertEqual(query["order_by"], "relevant")
        XCTAssertEqual(query.count, 4)

        XCTAssertEqual(router.headers["Content-Type"], "application/json")
        XCTAssertEqual(router.headers["Authorization"]?.hasPrefix("Client-ID "), true)
    }

    func test_routersProduceValidURLsWithEncodedQuery() throws {
        let router = UnsplashApiRouter.searchPhoto(query: "cat & dog 한글", page: 1)
        var components = try XCTUnwrap(URLComponents(string: router.baseURL + router.path))
        components.queryItems = router.queryItems
        let url = try XCTUnwrap(components.url)

        // 도메인은 Secrets에서 오므로 값 자체는 보지 않고 host·path가 라우터 구성대로 이어졌는지만 본다
        XCTAssertEqual(url.host, URL(string: router.baseURL)?.host)
        XCTAssertTrue(url.path.hasSuffix(router.path), url.path)
        XCTAssertEqual(URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?.first { $0.name == "query" }?.value, "cat & dog 한글")
    }

    private func queryDictionary(_ items: [URLQueryItem]?) throws -> [String: String] {
        let items = try XCTUnwrap(items)
        return Dictionary(uniqueKeysWithValues: items.map { ($0.name, $0.value ?? "") })
    }
}
