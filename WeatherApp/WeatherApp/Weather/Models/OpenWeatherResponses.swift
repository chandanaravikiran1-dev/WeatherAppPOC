//
//  OpenWeatherResponses.swift
//  WeatherApp
//
//  Created by Ravi Kiran on 20/10/26.
//

import Foundation

struct GeocodingResult: Decodable {
    let name: String
    let lat: Double
    let lon: Double
    let country: String
    let state: String?
}

struct CurrentWeatherResponse: Decodable {
    struct Condition: Decodable {
        let main: String
        let description: String
        let icon: String
    }

    struct Main: Decodable {
        let temp: Double
        let feelsLike: Double
        let humidity: Int

        enum CodingKeys: String, CodingKey {
            case temp, humidity
            case feelsLike = "feels_like"
        }
    }

    struct Wind: Decodable {
        let speed: Double
    }

    let name: String
    let weather: [Condition]
    let main: Main
    let wind: Wind
}
