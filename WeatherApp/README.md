# WeatherApp

A simple iOS weather app using the OpenWeatherMap API. Users can search for a US city or view weather based on their current location.

## Requirements

- Xcode 16+
- iOS 17+
- No third-party dependencies

## Getting Started

1. Open `WeatherApp.xcodeproj`.
2. Select the `WeatherApp` scheme.
3. Choose a simulator and run.

Add your OpenWeatherMap API key in:

`WeatherApp/App/Constants.swift`

For location testing in Simulator, use **Features → Location**.

## Features

- Search weather by US city
- Current location weather
- Temperature, feels-like, condition, humidity and wind speed
- Weather icons with `NSCache`
- Saves and restores the last searched city
- Location permission and error handling
- iPhone/iPad and portrait/landscape support
- Dynamic Type and VoiceOver support

## Architecture

The app follows **MVVM-C**.

- **UIKit** – App setup and navigation
- **SwiftUI** – Weather UI
- **ViewModel** – Screen state and business logic
- **Services** – Networking, location and persistence
- **NSCache** – Image caching
- **Dependency Injection** – Keeps services testable

## API

City searches use the OpenWeatherMap Geocoding API to get coordinates, followed by the Current Weather API.

Weather is displayed using imperial units (°F and mph).

## Testing

Includes unit tests for:

- WeatherViewModel
- OpenWeatherService
- ImageLoader
- LastSearchStore

UI tests cover basic launch, search and error scenarios.

Run tests with **⌘U**.

## Future Improvements

- Show multiple results for ambiguous cities
- Move the API key to a secure configuration
- Add weather forecast
- Add pull-to-refresh

The implementation is intentionally kept simple and focused on the assignment requirements.
