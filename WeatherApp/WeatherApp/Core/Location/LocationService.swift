//
//  LocationService.swift
//  WeatherApp
//
//  Created by Ravi Kiran on 20/10/26.
//

import CoreLocation

enum LocationError: Error {
    case permissionDenied
    case servicesDisabled
    case unavailable
}

@MainActor
protocol LocationService {
    func currentLocation() async throws -> CLLocationCoordinate2D
}

@MainActor
final class CoreLocationService: NSObject, LocationService {
    private let manager = CLLocationManager()
    private var authorizationContinuation: CheckedContinuation<CLAuthorizationStatus, Never>?
    private var locationContinuation: CheckedContinuation<CLLocationCoordinate2D, Error>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func currentLocation() async throws -> CLLocationCoordinate2D {
        var status = manager.authorizationStatus
        if status == .notDetermined {
            status = await requestAuthorization()
        }

        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            break
        case .denied:
            // CoreLocation reports `.denied` both when the user declined and when
            // Location Services are off system-wide; only the latter needs a different message.
            throw await Self.servicesEnabled() ? LocationError.permissionDenied : LocationError.servicesDisabled
        default:
            throw LocationError.permissionDenied
        }

        guard locationContinuation == nil else {
            throw LocationError.unavailable
        }
        return try await withCheckedThrowingContinuation { continuation in
            locationContinuation = continuation
            manager.requestLocation()
        }
    }

    private func requestAuthorization() async -> CLAuthorizationStatus {
        await withCheckedContinuation { continuation in
            authorizationContinuation = continuation
            manager.requestWhenInUseAuthorization()
        }
    }

    // Apple warns this can block, so keep it off the main thread.
    private static func servicesEnabled() async -> Bool {
        await Task.detached { CLLocationManager.locationServicesEnabled() }.value
    }

    private func finishLocationRequest(with result: Result<CLLocationCoordinate2D, Error>) {
        locationContinuation?.resume(with: result)
        locationContinuation = nil
    }
}

// CLLocationManager calls its delegate on the thread it was created on, which is main here.
extension CoreLocationService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        MainActor.assumeIsolated {
            guard status != .notDetermined, let continuation = authorizationContinuation else { return }
            authorizationContinuation = nil
            continuation.resume(returning: status)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = locations.last?.coordinate else { return }
        MainActor.assumeIsolated {
            finishLocationRequest(with: .success(coordinate))
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let locationError: LocationError = (error as? CLError)?.code == .denied ? .permissionDenied : .unavailable
        MainActor.assumeIsolated {
            finishLocationRequest(with: .failure(locationError))
        }
    }
}
