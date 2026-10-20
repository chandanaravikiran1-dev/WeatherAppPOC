//
//  UITestSupport.swift
//  WeatherApp
//
//  Created by Ravi Kiran on 20/10/26.
//

import CoreLocation
import Foundation

/// Deterministic dependencies for UI tests, so they never hit the network or the location prompt.
enum UITestSupport {
    static var isEnabled: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("-uiTesting")
        #else
        false
        #endif
    }

    static func makeCleanDefaults() -> UserDefaults {
        let suiteName = "WeatherAppUITests"
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    struct StubWeatherService: WeatherService {
        func location(matching query: String) async throws -> GeocodedLocation {
            guard query.lowercased().hasPrefix("austin") else { throw WeatherError.cityNotFound }
            return GeocodedLocation(name: "Austin", state: "Texas", latitude: 30.27, longitude: -97.74)
        }

        func weather(latitude: Double, longitude: Double) async throws -> Weather {
            Weather(
                locationName: "Austin",
                temperature: 88,
                feelsLike: 92,
                condition: "Clouds",
                conditionDescription: "scattered clouds",
                humidity: 54,
                windSpeed: 9,
                iconURL: nil
            )
        }
    }

    @MainActor
    struct DeniedLocationService: LocationService {
        func currentLocation() async throws -> CLLocationCoordinate2D {
            throw LocationError.permissionDenied
        }
    }
}
