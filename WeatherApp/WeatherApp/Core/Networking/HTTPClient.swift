//
//  HTTPClient.swift
//  WeatherApp
//
//  Created by Ravi Kiran on 20/10/26.
//

import Foundation

struct HTTPClient: Sendable {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func data(from url: URL) async throws -> Data {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(from: url)
        } catch {
            throw NetworkError.transport(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw NetworkError.httpStatus(httpResponse.statusCode)
        }
        guard !data.isEmpty else {
            throw NetworkError.invalidResponse
        }
        return data
    }

    func get<T: Decodable>(_ type: T.Type, from url: URL) async throws -> T {
        let data = try await data(from: url)
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw NetworkError.decoding(error)
        }
    }
}
