//
//  WeatherScreen.swift
//  WeatherApp
//
//  Created by Ravi Kiran on 20/10/26.
//

import SwiftUI

struct WeatherScreen: View {
    @Bindable var viewModel: WeatherViewModel
    let imageLoader: ImageLoading

    var body: some View {
        VStack(spacing: 0) {
            searchBar
                .padding()
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .task {
            await viewModel.loadInitialWeather()
        }
    }

    private var searchBar: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                searchField
                searchButton
                locationButton
            }
            VStack(spacing: 12) {
                searchField
                HStack(spacing: 12) {
                    searchButton
                    locationButton
                }
            }
        }
        .disabled(viewModel.isLoading)
    }

    private var searchField: some View {
        TextField("City, e.g. Austin, TX", text: $viewModel.searchText)
            .textFieldStyle(.roundedBorder)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .submitLabel(.search)
            .onSubmit(search)
            .accessibilityLabel("US city")
            .accessibilityIdentifier("searchField")
    }

    private var searchButton: some View {
        Button("Search", action: search)
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("searchButton")
    }

    private var locationButton: some View {
        Button {
            Task { await viewModel.useCurrentLocation() }
        } label: {
            Label("Use My Location", systemImage: "location.fill")
                .labelStyle(.iconOnly)
        }
        .buttonStyle(.bordered)
        .accessibilityIdentifier("locationButton")
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle(let notice):
            ContentUnavailableView {
                Label("Search for a City", systemImage: "magnifyingglass")
            } description: {
                if let notice {
                    Text(notice)
                } else {
                    Text("Enter a US city to see its current weather.")
                }
            } actions: {
                settingsButton
            }

        case .loading:
            ProgressView("Loading weather...")

        case .loaded(let weather):
            ScrollView {
                WeatherDetailView(weather: weather, imageLoader: imageLoader)
                    .padding()
                    .frame(maxWidth: .infinity)
            }

        case .failed(let message):
            ContentUnavailableView {
                Label("Couldn't Load Weather", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
                    .accessibilityIdentifier("errorMessage")
            } actions: {
                settingsButton
            }
        }
    }

    @ViewBuilder
    private var settingsButton: some View {
        if viewModel.needsLocationPermission {
            Button("Open Settings", action: viewModel.openSettings)
                .buttonStyle(.bordered)
        }
    }

    private func search() {
        Task { await viewModel.search() }
    }
}
