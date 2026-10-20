//
//  LastSearchStore.swift
//  WeatherApp
//
//  Created by Ravi Kiran on 20/10/26.
//

import Foundation

struct LastSearchStore {
    private let defaults: UserDefaults
    private let key = "lastSearchedLocation"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> GeocodedLocation? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(GeocodedLocation.self, from: data)
    }

    func save(_ location: GeocodedLocation) {
        guard let data = try? JSONEncoder().encode(location) else { return }
        defaults.set(data, forKey: key)
    }
}
