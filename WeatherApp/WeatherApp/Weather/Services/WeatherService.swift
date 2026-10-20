//
//  WeatherService.swift
//  WeatherApp
//
//  Created by Ravi Kiran on 20/10/26.
//

import Foundation

enum WeatherError: Error {
    case cityNotFound
}

protocol WeatherService: Sendable {
    func location(matching query: String) async throws -> GeocodedLocation
    func weather(latitude: Double, longitude: Double) async throws -> Weather
}

struct OpenWeatherService: WeatherService {
    private let apiKey: String
    private let client: HTTPClient

    init(apiKey: String, client: HTTPClient = HTTPClient()) {
        self.apiKey = apiKey
        self.client = client
    }

    func location(matching query: String) async throws -> GeocodedLocation {
        // Asking for a few results and filtering ourselves, because the geocoder
        // can still return non-US matches for loosely formatted queries.
        let url = try makeURL(path: Constants.OpenWeather.geocodingPath, queryItems: [
            URLQueryItem(name: "q", value: "\(query),US"),
            URLQueryItem(name: "limit", value: "5"),
        ])
        let results = try await client.get([GeocodingResult].self, from: url)

        guard let match = results.first(where: { $0.country == "US" }) else {
            throw WeatherError.cityNotFound
        }
        return GeocodedLocation(name: match.name, state: match.state, latitude: match.lat, longitude: match.lon)
    }

    func weather(latitude: Double, longitude: Double) async throws -> Weather {
        let url = try makeURL(path: Constants.OpenWeather.currentWeatherPath, queryItems: [
            URLQueryItem(name: "lat", value: String(latitude)),
            URLQueryItem(name: "lon", value: String(longitude)),
            URLQueryItem(name: "units", value: "imperial"),
        ])
        let response = try await client.get(CurrentWeatherResponse.self, from: url)

        guard let condition = response.weather.first else {
            throw NetworkError.invalidResponse
        }
        return Weather(
            locationName: response.name,
            temperature: response.main.temp,
            feelsLike: response.main.feelsLike,
            condition: condition.main,
            conditionDescription: condition.description,
            humidity: response.main.humidity,
            windSpeed: response.wind.speed,
            iconURL: Constants.OpenWeather.iconBaseURL.appendingPathComponent("\(condition.icon)@2x.png")
        )
    }

    private func makeURL(path: String, queryItems: [URLQueryItem]) throws -> URL {
        var components = URLComponents(url: Constants.OpenWeather.baseURL, resolvingAgainstBaseURL: false)
        components?.path = path
        components?.queryItems = queryItems + [URLQueryItem(name: "appid", value: apiKey)]
        guard let url = components?.url else {
            throw NetworkError.invalidURL
        }
        return url
    }
}
