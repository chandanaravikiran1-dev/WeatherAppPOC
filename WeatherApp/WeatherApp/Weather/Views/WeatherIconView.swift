//
//  WeatherIconView.swift
//  WeatherApp
//
//  Created by Ravi Kiran on 20/10/26.
//

import SwiftUI

struct WeatherIconView: View {
    let url: URL?
    let accessibilityLabel: String
    let imageLoader: ImageLoading

    @State private var image: UIImage?
    @ScaledMetric private var size = 100

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "cloud.sun")
                    .font(.system(size: size / 2))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement()
        .accessibilityLabel(accessibilityLabel)
        .task(id: url) {
            image = nil
            guard let url else { return }
            // The icon is decorative next to the text condition, so a failed download just keeps the placeholder.
            image = try? await imageLoader.image(for: url)
        }
    }
}
