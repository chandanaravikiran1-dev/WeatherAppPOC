//
//  WeatherViewModel.swift
//  WeatherApp
//
//  Created by Ravi Kiran on 20/10/26.
//

import Foundation
import Observation
import OSLog

@MainActor
@Observable
final class WeatherViewModel {
    enum State: Equatable {
        case idle(notice: String?)
        case loading
        case loaded(Weather)
        case failed(message: String)
    }

    private(set) var state: State = .idle(notice: nil)
    private(set) var needsLocationPermission = false
    var searchText = ""

    var isLoading: Bool { state == .loading }

    private let weatherService: WeatherService
    private let locationService: LocationService
    private let store: LastSearchStore
    private let onOpenSettings: () -> Void
    private let logger = Logger(subsystem: "com.example.WeatherApp", category: "Weather")

    init(
        weatherService: WeatherService,
        locationService: LocationService,
        store: LastSearchStore,
        onOpenSettings: @escaping () -> Void = {}
    ) {
        self.weatherService = weatherService
        self.locationService = locationService
        self.store = store
        self.onOpenSettings = onOpenSettings
    }

    /// Current location first; if location isn't available, fall back to the last searched city.
    func loadInitialWeather() async {
        state = .loading
        do {
            try await loadCurrentLocationWeather()
        } catch let error as LocationError {
            logger.info("Location unavailable on launch: \(String(describing: error))")
            if let lastLocation = store.load() {
                await loadWeather(for: lastLocation)
            } else {
                needsLocationPermission = error == .permissionDenied
                state = .idle(notice: message(for: error))
            }
        } catch {
            show(error)
        }
    }

    func search() async {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty, !isLoading else { return }

        state = .loading
        do {
            let location = try await weatherService.location(matching: query)
            await loadWeather(for: location)
        } catch {
            show(error)
        }
    }

    func useCurrentLocation() async {
        guard !isLoading else { return }

        state = .loading
        do {
            try await loadCurrentLocationWeather()
        } catch {
            show(error)
        }
    }

    func openSettings() {
        onOpenSettings()
    }

    private func loadCurrentLocationWeather() async throws {
        let coordinate = try await locationService.currentLocation()
        var weather = try await weatherService.weather(latitude: coordinate.latitude, longitude: coordinate.longitude)
        if weather.locationName.isEmpty {
            weather.locationName = String(localized: "Current Location")
        }
        state = .loaded(weather)
    }

    private func loadWeather(for location: GeocodedLocation) async {
        do {
            var weather = try await weatherService.weather(latitude: location.latitude, longitude: location.longitude)
            // The weather endpoint names the nearest station area, which often differs from the city searched for.
            weather.locationName = location.displayName
            store.save(location)
            state = .loaded(weather)
        } catch {
            show(error)
        }
    }

    private func show(_ error: Error) {
        logger.error("Weather request failed: \(String(describing: error))")
        needsLocationPermission = (error as? LocationError) == .permissionDenied
        state = .failed(message: message(for: error))
    }

    private func message(for error: Error) -> String {
        switch error {
        case WeatherError.cityNotFound:
            return String(localized: "We couldn't find that city. Check the spelling, or try adding the state, like \"Springfield, IL\".")
        case LocationError.permissionDenied:
            return String(localized: "Location access is turned off for this app. Turn it on in Settings, or search for a city.")
        case LocationError.servicesDisabled:
            return String(localized: "Location Services are turned off. Turn them on in Settings > Privacy & Security, or search for a city.")
        case LocationError.unavailable:
            return String(localized: "We couldn't determine your location right now. Try again, or search for a city.")
        case NetworkError.transport(let underlying as URLError) where underlying.code == .notConnectedToInternet:
            return String(localized: "You appear to be offline. Check your connection and try again.")
        default:
            return String(localized: "Something went wrong while loading the weather. Please try again.")
        }
    }
}
