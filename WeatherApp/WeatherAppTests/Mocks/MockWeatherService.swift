//
//  MockWeatherService.swift
//  WeatherAppTests
//
//  Created by Ravi Kiran on 20/10/26.
//

import Foundation
@testable import WeatherApp

final class MockWeatherService: WeatherService, @unchecked Sendable {
    var locationResult: Result<GeocodedLocation, Error> = .success(.austin)
    var weatherResult: Result<Weather, Error> = .success(.sample)
    /// Runs while the weather request is "in flight", so tests can inspect intermediate state.
    var onWeatherRequest: (@MainActor () -> Void)?

    private(set) var searchedQueries: [String] = []
    private(set) var requestedCoordinates: [Coordinate] = []

    struct Coordinate: Equatable {
        let latitude: Double
        let longitude: Double
    }

    func location(matching query: String) async throws -> GeocodedLocation {
        searchedQueries.append(query)
        return try locationResult.get()
    }

    func weather(latitude: Double, longitude: Double) async throws -> Weather {
        requestedCoordinates.append(Coordinate(latitude: latitude, longitude: longitude))
        await onWeatherRequest?()
        return try weatherResult.get()
    }
}

extension GeocodedLocation {
    static let austin = GeocodedLocation(name: "Austin", state: "Texas", latitude: 30.27, longitude: -97.74)
    static let denver = GeocodedLocation(name: "Denver", state: "Colorado", latitude: 39.74, longitude: -104.99)
}

extension Weather {
    static let sample = Weather(
        locationName: "Station Name",
        temperature: 88,
        feelsLike: 92,
        condition: "Clouds",
        conditionDescription: "scattered clouds",
        humidity: 54,
        windSpeed: 9,
        iconURL: nil
    )
}
