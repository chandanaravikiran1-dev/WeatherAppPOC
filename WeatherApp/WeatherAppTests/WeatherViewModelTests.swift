//
//  WeatherViewModelTests.swift
//  WeatherAppTests
//
//  Created by Ravi Kiran on 20/10/26.
//

import CoreLocation
import Foundation
import Testing
@testable import WeatherApp

@MainActor
struct WeatherViewModelTests {
    private let weatherService = MockWeatherService()
    private let locationService = MockLocationService()
    private let store = LastSearchStore(defaults: UserDefaults(suiteName: UUID().uuidString)!)

    private func makeViewModel() -> WeatherViewModel {
        WeatherViewModel(weatherService: weatherService, locationService: locationService, store: store)
    }

    // MARK: - Search

    @Test func searchLoadsWeatherNamedAfterGeocodedCity() async {
        let viewModel = makeViewModel()
        viewModel.searchText = "  Austin  "

        await viewModel.search()

        var expected = Weather.sample
        expected.locationName = "Austin, Texas"
        #expect(viewModel.state == .loaded(expected))
        #expect(weatherService.searchedQueries == ["Austin"])
        #expect(weatherService.requestedCoordinates == [.init(latitude: 30.27, longitude: -97.74)])
    }

    @Test func searchShowsLoadingWhileRequestIsInFlight() async {
        let viewModel = makeViewModel()
        viewModel.searchText = "Austin"
        var stateDuringRequest: WeatherViewModel.State?
        weatherService.onWeatherRequest = { stateDuringRequest = viewModel.state }

        await viewModel.search()

        #expect(stateDuringRequest == .loading)
        #expect(!viewModel.isLoading)
    }

    @Test func unknownCityShowsErrorAndIsNotSaved() async {
        weatherService.locationResult = .failure(WeatherError.cityNotFound)
        let viewModel = makeViewModel()
        viewModel.searchText = "Nowhereville"

        await viewModel.search()

        guard case .failed(let message) = viewModel.state else {
            Issue.record("Expected failed state, got \(viewModel.state)")
            return
        }
        #expect(message.contains("couldn't find that city"))
        #expect(store.load() == nil)
        #expect(weatherService.requestedCoordinates.isEmpty)
    }

    @Test func apiFailureShowsFriendlyMessageWithoutTechnicalDetails() async {
        weatherService.weatherResult = .failure(NetworkError.httpStatus(500))
        let viewModel = makeViewModel()
        viewModel.searchText = "Austin"

        await viewModel.search()

        guard case .failed(let message) = viewModel.state else {
            Issue.record("Expected failed state, got \(viewModel.state)")
            return
        }
        #expect(!message.contains("500"))
        #expect(store.load() == nil)
    }

    @Test func offlineErrorGetsSpecificMessage() async {
        weatherService.weatherResult = .failure(NetworkError.transport(URLError(.notConnectedToInternet)))
        let viewModel = makeViewModel()
        viewModel.searchText = "Austin"

        await viewModel.search()

        #expect(viewModel.state == .failed(message: "You appear to be offline. Check your connection and try again."))
    }

    @Test func blankSearchDoesNothing() async {
        let viewModel = makeViewModel()
        viewModel.searchText = "   "

        await viewModel.search()

        #expect(viewModel.state == .idle(notice: nil))
        #expect(weatherService.searchedQueries.isEmpty)
    }

    @Test func successfulSearchIsSaved() async {
        let viewModel = makeViewModel()
        viewModel.searchText = "Austin"

        await viewModel.search()

        #expect(store.load() == .austin)
    }

    // MARK: - Launch

    @Test func launchPrefersCurrentLocationOverLastSearch() async {
        store.save(.denver)
        locationService.result = .success(CLLocationCoordinate2D(latitude: 37.33, longitude: -122.01))
        let viewModel = makeViewModel()

        await viewModel.loadInitialWeather()

        #expect(viewModel.state == .loaded(.sample))
        #expect(weatherService.requestedCoordinates == [.init(latitude: 37.33, longitude: -122.01)])
    }

    @Test func launchRestoresLastSearchedCityWhenLocationIsDenied() async {
        store.save(.denver)
        locationService.result = .failure(LocationError.permissionDenied)
        let viewModel = makeViewModel()

        await viewModel.loadInitialWeather()

        var expected = Weather.sample
        expected.locationName = "Denver, Colorado"
        #expect(viewModel.state == .loaded(expected))
        #expect(weatherService.requestedCoordinates == [.init(latitude: 39.74, longitude: -104.99)])
    }

    @Test func launchWithoutLocationOrHistoryExplainsWhy() async {
        locationService.result = .failure(LocationError.permissionDenied)
        let viewModel = makeViewModel()

        await viewModel.loadInitialWeather()

        guard case .idle(let notice?) = viewModel.state else {
            Issue.record("Expected idle state with a notice, got \(viewModel.state)")
            return
        }
        #expect(notice.contains("Settings"))
        #expect(viewModel.needsLocationPermission)
    }

    @Test func launchDoesNotFallBackWhenWeatherRequestFails() async {
        store.save(.denver)
        locationService.result = .success(CLLocationCoordinate2D(latitude: 37.33, longitude: -122.01))
        weatherService.weatherResult = .failure(NetworkError.invalidResponse)
        let viewModel = makeViewModel()

        await viewModel.loadInitialWeather()

        guard case .failed = viewModel.state else {
            Issue.record("Expected failed state, got \(viewModel.state)")
            return
        }
        #expect(weatherService.requestedCoordinates.count == 1)
    }

    // MARK: - Current location

    @Test func currentLocationWithoutStationNameUsesFallbackTitle() async {
        var unnamed = Weather.sample
        unnamed.locationName = ""
        weatherService.weatherResult = .success(unnamed)
        locationService.result = .success(CLLocationCoordinate2D(latitude: 0, longitude: 0))
        let viewModel = makeViewModel()

        await viewModel.useCurrentLocation()

        guard case .loaded(let weather) = viewModel.state else {
            Issue.record("Expected loaded state, got \(viewModel.state)")
            return
        }
        #expect(weather.locationName == "Current Location")
    }

    @Test func settingsPromptClearsAfterUnrelatedError() async {
        let viewModel = makeViewModel()
        await viewModel.useCurrentLocation()
        #expect(viewModel.needsLocationPermission)

        weatherService.locationResult = .failure(WeatherError.cityNotFound)
        viewModel.searchText = "Nowhereville"
        await viewModel.search()

        #expect(!viewModel.needsLocationPermission)
    }
}
