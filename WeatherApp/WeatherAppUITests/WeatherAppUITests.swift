//
//  WeatherAppUITests.swift
//  WeatherAppUITests
//
//  Created by Ravi Kiran on 20/10/26.
//

import XCTest

final class WeatherAppUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting"]
        app.launch()
    }

    func testLaunchShowsSearchPromptWhenLocationIsUnavailable() {
        XCTAssertTrue(app.staticTexts["Search for a City"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Open Settings"].exists)
    }

    func testSearchingForCityShowsItsWeather() {
        search(for: "Austin")

        let locationName = app.staticTexts["locationName"]
        XCTAssertTrue(locationName.waitForExistence(timeout: 5))
        XCTAssertEqual(locationName.label, "Austin, Texas")
        XCTAssertTrue(app.staticTexts["Clouds"].exists)
    }

    func testSearchingForUnknownCityShowsError() {
        search(for: "Nowhereville")

        XCTAssertTrue(app.staticTexts["Couldn't Load Weather"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["errorMessage"].exists)
    }

    private func search(for city: String) {
        let searchField = app.textFields["searchField"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        searchField.typeText(city)
        app.buttons["searchButton"].tap()
    }
}
