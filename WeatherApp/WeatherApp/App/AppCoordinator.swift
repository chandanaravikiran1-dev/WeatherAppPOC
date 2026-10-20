//
//  AppCoordinator.swift
//  WeatherApp
//
//  Created by Ravi Kiran on 20/10/26.
//

import SwiftUI
import UIKit

@MainActor
final class AppCoordinator {
    private let window: UIWindow
    private let navigationController = UINavigationController()

    private let weatherService: WeatherService
    private let locationService: LocationService
    private let lastSearchStore: LastSearchStore
    private let imageLoader: ImageLoading = ImageLoader()

    init(window: UIWindow) {
        self.window = window

        if UITestSupport.isEnabled {
            weatherService = UITestSupport.StubWeatherService()
            locationService = UITestSupport.DeniedLocationService()
            lastSearchStore = LastSearchStore(defaults: UITestSupport.makeCleanDefaults())
        } else {
            weatherService = OpenWeatherService(apiKey: Constants.OpenWeather.apiKey)
            locationService = CoreLocationService()
            lastSearchStore = LastSearchStore()
        }
    }

    func start() {
        navigationController.navigationBar.prefersLargeTitles = true
        navigationController.setViewControllers([makeWeatherViewController()], animated: false)
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }

    private func makeWeatherViewController() -> UIViewController {
        let viewModel = WeatherViewModel(
            weatherService: weatherService,
            locationService: locationService,
            store: lastSearchStore,
            onOpenSettings: { [weak self] in self?.openAppSettings() }
        )
        let viewController = UIHostingController(rootView: WeatherScreen(viewModel: viewModel, imageLoader: imageLoader))
        viewController.title = String(localized: "Weather")
        return viewController
    }

    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
