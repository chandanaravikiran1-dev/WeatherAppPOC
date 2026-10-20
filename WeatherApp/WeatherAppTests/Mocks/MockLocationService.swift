//
//  MockLocationService.swift
//  WeatherAppTests
//
//  Created by Ravi Kiran on 20/10/26.
//

import CoreLocation
@testable import WeatherApp

@MainActor
final class MockLocationService: LocationService {
    var result: Result<CLLocationCoordinate2D, Error> = .failure(LocationError.permissionDenied)

    func currentLocation() async throws -> CLLocationCoordinate2D {
        try result.get()
    }
}
