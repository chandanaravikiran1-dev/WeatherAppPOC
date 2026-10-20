//
//  LastSearchStoreTests.swift
//  WeatherAppTests
//
//  Created by Ravi Kiran on 20/10/26.
//

import Foundation
import Testing
@testable import WeatherApp

struct LastSearchStoreTests {
    @Test func savedLocationSurvivesNewStoreInstance() throws {
        let defaults = try #require(UserDefaults(suiteName: #function))
        defaults.removePersistentDomain(forName: #function)
        let location = GeocodedLocation(name: "Denver", state: "Colorado", latitude: 39.74, longitude: -104.99)

        LastSearchStore(defaults: defaults).save(location)

        #expect(LastSearchStore(defaults: defaults).load() == location)
    }
}
