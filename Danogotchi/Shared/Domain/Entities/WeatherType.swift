import Foundation

enum WeatherType {
    case thunderstorm
    case drizzle
    case rain
    case snow
    case atmosphere
    case clear
    case clouds

    init(id: Int) {
        switch id {
        case 200...232: self = .thunderstorm
        case 300...321: self = .drizzle
        case 500...531: self = .rain
        case 600...622: self = .snow
        case 700...781: self = .atmosphere
        case 800:       self = .clear
        case 801...804: self = .clouds
        default:        self = .clear  
        }
    }
}
