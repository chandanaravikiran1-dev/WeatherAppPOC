//
//  NetworkError.swift
//  WeatherApp
//
//  Created by Ravi Kiran on 20/10/26.
//

import Foundation

enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case httpStatus(Int)
    case decoding(Error)
    case transport(Error)
}
