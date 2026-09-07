import XCTest
@testable import Danogotchi

@MainActor
final class WeatherUseCaseTests: XCTestCase {
    func test_coordinatesArePassedToWeatherRepository() async throws {
        let location = TestLocationProvider()
        let repository = TestWeatherRepository()
        let useCase = DefaultFetchCurrentWeatherUseCase(locationProvider: location, weatherRepository: repository)
        let weather = try await useCase.getWeather()
        let coordinates = await repository.coordinates
        XCTAssertEqual(coordinates?.latitude, 37.5)
        XCTAssertEqual(coordinates?.longitude, 127)
        XCTAssertEqual(weather.cityName, "Test City")
    }

    func test_locationFailureStopsBeforeWeatherRequest() async {
        let location = TestLocationProvider()
        location.denied = true
        let repository = TestWeatherRepository()
        let useCase = DefaultFetchCurrentWeatherUseCase(locationProvider: location, weatherRepository: repository)
        do {
            _ = try await useCase.getWeather()
            XCTFail("Expected location error")
        } catch LocationError.permissionDenied { }
        catch { XCTFail("Unexpected error: \(error)") }
        let coordinates = await repository.coordinates
        XCTAssertNil(coordinates)
    }

    func test_weatherFailureIsPropagated() async {
        let repository = TestWeatherRepository(fails: true)
        let useCase = DefaultFetchCurrentWeatherUseCase(locationProvider: TestLocationProvider(), weatherRepository: repository)
        do {
            _ = try await useCase.getWeather()
            XCTFail("Expected network error")
        } catch let error as URLError {
            XCTAssertEqual(error.code, .timedOut)
        } catch { XCTFail("Unexpected error: \(error)") }
    }
}

@MainActor
private final class TestLocationProvider: LocationProviding {
    var denied = false
    func currentCoordinate() async throws -> Coordinate {
        if denied { throw LocationError.permissionDenied }
        return Coordinate(latitude: 37.5, longitude: 127)
    }
}

private actor TestWeatherRepository: WeatherRepository {
    let fails: Bool
    private(set) var coordinates: Coordinate?
    init(fails: Bool = false) { self.fails = fails }
    func fetchCurrentWeather(lat: Double, lon: Double) async throws -> CurrentWeather {
        coordinates = Coordinate(latitude: lat, longitude: lon)
        if fails { throw URLError(.timedOut) }
        return CurrentWeather(cityName: "Test City", temperature: 20, feelsLike: 19, humidity: 50,
                              weatherType: .clear, description: "clear", iconCode: "01d")
    }
}
