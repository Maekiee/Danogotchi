import Foundation
import XCTest
@testable import Danogotchi

final class CurrentWeatherDTOTests: XCTestCase {
    func test_decodesSnakeCaseAndMapsFirstConditionToEntity() throws {
        let json = """
        {"name":"Seoul",
         "weather":[{"id":501,"main":"Rain","description":"moderate rain","icon":"10d"},
                    {"id":800,"main":"Clear","description":"clear sky","icon":"01d"}],
         "main":{"temp":21.5,"feels_like":20.1,"humidity":64}}
        """
        let dto = try JSONDecoder().decode(CurrentWeatherDTO.self, from: Data(json.utf8))
        XCTAssertEqual(dto.main.feelsLike, 20.1)

        let weather = dto.toEntity()
        XCTAssertEqual(weather.cityName, "Seoul")
        XCTAssertEqual(weather.temperature, 21.5)
        XCTAssertEqual(weather.feelsLike, 20.1)
        XCTAssertEqual(weather.humidity, 64)
        XCTAssertEqual(weather.weatherType, .rain)
        XCTAssertEqual(weather.description, "moderate rain")
        XCTAssertEqual(weather.iconCode, "10d")
    }

    func test_missingConditionFallsBackToClearAndEmptyStrings() throws {
        let json = #"{"name":"Nowhere","weather":[],"main":{"temp":0,"feels_like":-1,"humidity":10}}"#
        let weather = try JSONDecoder().decode(CurrentWeatherDTO.self, from: Data(json.utf8)).toEntity()
        XCTAssertEqual(weather.weatherType, .clear)
        XCTAssertEqual(weather.description, "")
        XCTAssertEqual(weather.iconCode, "")
    }

    func test_weatherTypeMapsOpenWeatherIdRanges() {
        let expectations: [(Int, WeatherType)] = [
            (199, .clear), (200, .thunderstorm), (232, .thunderstorm), (233, .clear),
            (300, .drizzle), (321, .drizzle), (400, .clear),
            (500, .rain), (531, .rain), (532, .clear),
            (600, .snow), (622, .snow), (623, .clear),
            (700, .atmosphere), (781, .atmosphere), (782, .clear),
            (800, .clear), (801, .clouds), (804, .clouds), (805, .clear),
        ]
        for (id, type) in expectations {
            XCTAssertEqual(WeatherType(id: id), type, "id \(id)")
        }
    }
}
