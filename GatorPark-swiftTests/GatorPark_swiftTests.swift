//
//  GatorPark_swiftTests.swift
//  GatorPark-swiftTests
//
//  Created by APPLE on 02/08/2025.
//

import Testing
import MapKit
@testable import GatorPark_swift

struct GatorPark_swiftTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }

    @Test func defaultCapacityIs100() async throws {
        let coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let garage = ViewController.Garage(name: "Test", coordinate: coordinate, currentCount: 0)
        #expect(garage.capacity == 100)
    }

}
