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

    @Test func defaultCapacityIsTwo() async throws {
        let coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let garage = ViewController.Garage(name: "Test", coordinate: coordinate, currentCount: 0)
        #expect(garage.capacity == 2)
    }

    @Test func annotationColorReflectsGarageCapacity() async throws {
        let vc = ViewController()
        let mapView = MKMapView()
        let coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)

        let fullGarage = ViewController.Garage(name: "Full", coordinate: coordinate, currentCount: 2, capacity: 2)
        let fullAnnotation = ViewController.GarageAnnotation(garage: fullGarage)
        let fullView = vc.mapView(mapView, viewFor: fullAnnotation)
        let fullDot = fullView?.viewWithTag(100)
        #expect((fullDot as? UIView)?.backgroundColor == .systemRed)

        let openGarage = ViewController.Garage(name: "Open", coordinate: coordinate, currentCount: 1, capacity: 2)
        let openAnnotation = ViewController.GarageAnnotation(garage: openGarage)
        let openView = vc.mapView(mapView, viewFor: openAnnotation)
        let openDot = openView?.viewWithTag(100)
        #expect((openDot as? UIView)?.backgroundColor == .systemBlue)
    }

    @Test func calloutUsesDynamicType() async throws {
        if #available(iOS 14.0, *) {
            let vc = ViewController()
            let mapView = MKMapView()
            let coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
            let garage = ViewController.Garage(name: "Test", coordinate: coordinate, currentCount: 1, capacity: 2)
            let annotation = ViewController.GarageAnnotation(garage: garage)
            let view = vc.mapView(mapView, viewFor: annotation)
            #expect(view?.detailCalloutAccessoryView is UIListContentView)
            if let contentView = view?.detailCalloutAccessoryView as? UIListContentView {
                let config = contentView.configuration
                #expect(config.text == "Test")
                #expect(config.secondaryText == "Spaces: 1/2")
            }
        }
    }

}
