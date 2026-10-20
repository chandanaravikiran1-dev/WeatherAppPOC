//
//  ImageLoaderTests.swift
//  WeatherAppTests
//
//  Created by Ravi Kiran on 20/10/26.
//

import Testing
import UIKit
@testable import WeatherApp

extension StubbedNetworkTests {
    @Suite struct ImageLoaderTests {
        private let url = URL(string: "https://openweathermap.org/img/wn/01d@2x.png")!
        private let loader = ImageLoader(client: StubURLProtocol.makeClient())

        init() {
            StubURLProtocol.requestCount = 0
            let pngData = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1)).pngData { context in
                UIColor.red.setFill()
                context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
            }
            StubURLProtocol.handler = { request in
                (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, pngData)
            }
        }

        @Test func secondRequestIsServedFromCache() async throws {
            _ = try await loader.image(for: url)
            _ = try await loader.image(for: url)

            #expect(StubURLProtocol.requestCount == 1)
        }

        @Test func concurrentRequestsShareOneDownload() async throws {
            async let first = loader.image(for: url)
            async let second = loader.image(for: url)
            _ = try await (first, second)

            #expect(StubURLProtocol.requestCount == 1)
        }

        @Test func nonImageDataThrows() async {
            StubURLProtocol.respond(json: "not an image")

            await #expect(throws: NetworkError.self) {
                try await loader.image(for: url)
            }
        }
    }
}
