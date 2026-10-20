//
//  ImageLoader.swift
//  WeatherApp
//
//  Created by Ravi Kiran on 20/10/26.
//

import UIKit

protocol ImageLoading: Sendable {
    func image(for url: URL) async throws -> UIImage
}

actor ImageLoader: ImageLoading {
    private let client: HTTPClient
    private let cache = NSCache<NSURL, UIImage>()
    private var inFlightTasks: [URL: Task<UIImage, Error>] = [:]

    init(client: HTTPClient = HTTPClient()) {
        self.client = client
    }

    func image(for url: URL) async throws -> UIImage {
        if let cached = cache.object(forKey: url as NSURL) {
            return cached
        }
        if let existingTask = inFlightTasks[url] {
            return try await existingTask.value
        }

        let task = Task { [client] in
            let data = try await client.data(from: url)
            guard let image = UIImage(data: data) else {
                throw NetworkError.invalidResponse
            }
            return image
        }
        inFlightTasks[url] = task
        defer { inFlightTasks[url] = nil }

        let image = try await task.value
        cache.setObject(image, forKey: url as NSURL)
        return image
    }
}
