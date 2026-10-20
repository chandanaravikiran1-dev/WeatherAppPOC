//
//  GeocodedLocation.swift
//  WeatherApp
//
//  Created by Ravi Kiran on 20/10/26.
//

import Foundation

struct GeocodedLocation: Codable, Equatable {
    let name: String
    let state: String?
    let latitude: Double
    let longitude: Double

    var displayName: String {
        guard let state, !state.isEmpty else { return name }
        return "\(name), \(state)"
    }
}
