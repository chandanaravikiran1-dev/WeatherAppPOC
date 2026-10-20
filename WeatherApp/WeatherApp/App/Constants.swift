//
//  Constants.swift
//  WeatherApp
//
//  Created by Ravi Kiran on 20/10/26.
//

import Foundation

enum Constants {
    enum OpenWeather {
        static let apiKey = "0bf63db5cb2c17d2c1cbeb6fea2ca60f"
        static let baseURL = URL(string: "https://api.openweathermap.org")!
        static let iconBaseURL = URL(string: "https://openweathermap.org/img/wn")!
        static let geocodingPath = "/geo/1.0/direct"
        static let currentWeatherPath = "/data/2.5/weather"
    }
}
