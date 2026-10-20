//
//  WeatherDetailView.swift
//  WeatherApp
//
//  Created by Ravi Kiran on 20/10/26.
//

import SwiftUI

struct WeatherDetailView: View {
    let weather: Weather
    let imageLoader: ImageLoading

    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @ScaledMetric(relativeTo: .largeTitle) private var temperatureSize = 64

    var body: some View {
        // Side by side in landscape and on iPad, stacked when space (or Dynamic Type) doesn't allow it.
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: 32) {
                summary
                details.frame(minWidth: 280)
            }
            VStack(spacing: 24) {
                summary
                details
            }
        }
        .frame(maxWidth: 720)
    }

    private var summary: some View {
        VStack(spacing: 8) {
            Text(weather.locationName)
                .font(.title.bold())
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("locationName")

            // Landscape iPhone has little height to spare, so put the icon beside the temperature there.
            if verticalSizeClass == .compact {
                HStack(spacing: 16) {
                    icon
                    temperature
                }
            } else {
                icon
                temperature
            }

            Text(weather.condition)
                .font(.title3)
            Text(weather.conditionDescription.capitalized)
                .foregroundStyle(.secondary)
        }
    }

    private var icon: some View {
        WeatherIconView(url: weather.iconURL, accessibilityLabel: weather.conditionDescription, imageLoader: imageLoader)
    }

    private var temperature: some View {
        Text(formattedTemperature(weather.temperature))
            .font(.system(size: temperatureSize, weight: .light, design: .rounded))
            .accessibilityLabel("Current temperature \(formattedTemperature(weather.temperature))")
    }

    private var details: some View {
        VStack(spacing: 0) {
            DetailRow(title: "Feels Like", value: formattedTemperature(weather.feelsLike), systemImage: "thermometer.medium")
            Divider()
            DetailRow(title: "Humidity", value: (Double(weather.humidity) / 100).formatted(.percent), systemImage: "humidity")
            Divider()
            DetailRow(title: "Wind", value: formattedWindSpeed(weather.windSpeed), systemImage: "wind")
        }
        .padding(.horizontal)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 16))
    }

    private func formattedTemperature(_ fahrenheit: Double) -> String {
        Measurement(value: fahrenheit, unit: UnitTemperature.fahrenheit)
            .formatted(.measurement(width: .abbreviated, usage: .asProvided, numberFormatStyle: .number.precision(.fractionLength(0))))
    }

    private func formattedWindSpeed(_ milesPerHour: Double) -> String {
        Measurement(value: milesPerHour, unit: UnitSpeed.milesPerHour)
            .formatted(.measurement(width: .abbreviated, usage: .asProvided, numberFormatStyle: .number.precision(.fractionLength(0))))
    }
}

private struct DetailRow: View {
    let title: LocalizedStringKey
    let value: String
    let systemImage: String

    var body: some View {
        HStack {
            Label(title, systemImage: systemImage)
            Spacer()
            Text(value)
                .bold()
        }
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }
}
