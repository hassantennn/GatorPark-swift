//
//  GatorPark_swiftTests.swift
//  GatorPark-swiftTests
//
//  Created by APPLE on 02/08/2025.
//

import Testing
import UIKit
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

    @Test func annotationColorReflectsGarageCapacity() async throws {
        let vc = ViewController()
        let mapView = MKMapView()
        let coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)

        let fullGarage = ViewController.Garage(name: "Full", coordinate: coordinate, currentCount: 100, capacity: 100)
        let fullAnnotation = ViewController.GarageAnnotation(garage: fullGarage)
        let fullView = vc.mapView(mapView, viewFor: fullAnnotation)
        #expect(fullView?.backgroundColor == .systemRed)

        let openGarage = ViewController.Garage(name: "Open", coordinate: coordinate, currentCount: 50, capacity: 100)
        let openAnnotation = ViewController.GarageAnnotation(garage: openGarage)
        let openView = vc.mapView(mapView, viewFor: openAnnotation)
        #expect(openView?.backgroundColor == .systemBlue)
    }

}
