//
//  OpenWeatherServiceTests.swift
//  WeatherAppTests
//
//  Created by Ravi Kiran on 20/10/26.
//

import Foundation
import Testing
@testable import WeatherApp

extension StubbedNetworkTests {
    @Suite struct OpenWeatherServiceTests {
        private let service = OpenWeatherService(apiKey: "test-key", client: StubURLProtocol.makeClient())

        @Test func decodesCurrentWeather() async throws {
            StubURLProtocol.respond(json: Fixtures.currentWeather)

            let weather = try await service.weather(latitude: 30.27, longitude: -97.74)

            #expect(weather == Weather(
                locationName: "Austin",
                temperature: 88.5,
                feelsLike: 92.1,
                condition: "Clouds",
                conditionDescription: "scattered clouds",
                humidity: 54,
                windSpeed: 9.2,
                iconURL: URL(string: "https://openweathermap.org/img/wn/03d@2x.png")
            ))
        }

        @Test func sendsCoordinatesUnitsAndKey() async throws {
            var capturedURL: URL?
            StubURLProtocol.handler = { request in
                capturedURL = request.url
                return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!,
                        Data(Fixtures.currentWeather.utf8))
            }

            _ = try await service.weather(latitude: 30.27, longitude: -97.74)

            let items = try #require(capturedURL.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false)?.queryItems })
            #expect(items.contains(URLQueryItem(name: "lat", value: "30.27")))
            #expect(items.contains(URLQueryItem(name: "lon", value: "-97.74")))
            #expect(items.contains(URLQueryItem(name: "units", value: "imperial")))
            #expect(items.contains(URLQueryItem(name: "appid", value: "test-key")))
        }

        @Test func emptyConditionsIsInvalidResponse() async {
            StubURLProtocol.respond(json: Fixtures.currentWeatherWithoutConditions)

            await #expect {
                try await service.weather(latitude: 0, longitude: 0)
            } throws: { error in
                guard case NetworkError.invalidResponse = error else { return false }
                return true
            }
        }

        @Test func malformedJSONIsDecodingError() async {
            StubURLProtocol.respond(json: #"{"name": "Austin"}"#)

            await #expect {
                try await service.weather(latitude: 0, longitude: 0)
            } throws: { error in
                guard case NetworkError.decoding = error else { return false }
                return true
            }
        }

        @Test func unauthorizedIsHTTPError() async {
            StubURLProtocol.respond(status: 401, json: #"{"cod": 401, "message": "Invalid API key"}"#)

            await #expect {
                try await service.weather(latitude: 0, longitude: 0)
            } throws: { error in
                guard case NetworkError.httpStatus(401) = error else { return false }
                return true
            }
        }

        @Test func geocodingPicksFirstUSResult() async throws {
            StubURLProtocol.respond(json: Fixtures.geocodingMixedCountries)

            let location = try await service.location(matching: "Paris")

            #expect(location == GeocodedLocation(name: "Paris", state: "Texas", latitude: 33.66, longitude: -95.55))
        }

        @Test func geocodingWithNoResultsIsCityNotFound() async {
            StubURLProtocol.respond(json: "[]")

            await #expect(throws: WeatherError.cityNotFound) {
                try await service.location(matching: "Nowhereville")
            }
        }
    }
}

private enum Fixtures {
    static let currentWeather = """
    {
      "coord": { "lon": -97.74, "lat": 30.27 },
      "weather": [{ "id": 802, "main": "Clouds", "description": "scattered clouds", "icon": "03d" }],
      "main": { "temp": 88.5, "feels_like": 92.1, "temp_min": 86, "temp_max": 90, "pressure": 1012, "humidity": 54 },
      "wind": { "speed": 9.2, "deg": 160 },
      "name": "Austin",
      "cod": 200
    }
    """

    static let currentWeatherWithoutConditions = """
    {
      "weather": [],
      "main": { "temp": 70, "feels_like": 70, "humidity": 40 },
      "wind": { "speed": 1 },
      "name": "Austin"
    }
    """

    static let geocodingMixedCountries = """
    [
      { "name": "Paris", "lat": 48.85, "lon": 2.35, "country": "FR" },
      { "name": "Paris", "lat": 33.66, "lon": -95.55, "country": "US", "state": "Texas" }
    ]
    """
}
