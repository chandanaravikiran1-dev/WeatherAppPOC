//
//  Weather.swift
//  WeatherApp
//
//  Created by Ravi Kiran on 20/10/26.
//

import Foundation

struct Weather: Equatable {
    var locationName: String
    let temperature: Double
    let feelsLike: Double
    let condition: String
    let conditionDescription: String
    let humidity: Int
    let windSpeed: Double
    let iconURL: URL?
}
