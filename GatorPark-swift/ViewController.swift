//
//  ViewController.swift
//  GatorPark-swift
//
//  Created by APPLE on 02/08/2025.
//

import UIKit
import MapKit

class ViewController: UIViewController {

    let mapView = MKMapView()

    struct Garage {
        let name: String
        let coordinate: CLLocationCoordinate2D
        let isBusy: Bool
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupMap()
        addGaragePins()
    }

    func setupMap() {
        mapView.frame = view.bounds
        view.addSubview(mapView)

        let gainesville = CLLocationCoordinate2D(latitude: 29.6516, longitude: -82.3248)
        let region = MKCoordinateRegion(
            center: gainesville,
            span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
        )
        mapView.setRegion(region, animated: true)
        mapView.delegate = self
    }

    func addGaragePins() {
        let garages = [
            Garage(name: "Garage A", coordinate: CLLocationCoordinate2D(latitude: 29.649, longitude: -82.341), isBusy: true),
            Garage(name: "Garage B", coordinate: CLLocationCoordinate2D(latitude: 29.655, longitude: -82.330), isBusy: false),
            Garage(name: "Garage C", coordinate: CLLocationCoordinate2D(latitude: 29.653, longitude: -82.325), isBusy: true)
        ]

        for garage in garages {
            let annotation = MKPointAnnotation()
            annotation.coordinate = garage.coordinate
            annotation.title = garage.name
            annotation.subtitle = garage.isBusy ? "Busy" : "Available"
            mapView.addAnnotation(annotation)
        }
    }
}

extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !(annotation is MKUserLocation) else { return nil }

        let identifier = "GarageCircle"

        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            
            // Create a custom circle view
            let size: CGFloat = 20
            let circleView = UIView(frame: CGRect(x: 0, y: 0, width: size, height: size))
            circleView.layer.cornerRadius = size / 2
            circleView.layer.borderColor = UIColor.white.cgColor
            circleView.layer.borderWidth = 2
            circleView.clipsToBounds = true
            
            // Set color based on garage status
            if let title = annotation.title ?? "" {
                let busyGarages = ["Garage A", "Garage C"]
                circleView.backgroundColor = busyGarages.contains(title) ? .red : .blue
            }

            UIGraphicsBeginImageContextWithOptions(circleView.bounds.size, false, 0)
            circleView.layer.render(in: UIGraphicsGetCurrentContext()!)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            annotationView?.image = image
            annotationView?.canShowCallout = true
        } else {
            annotationView?.annotation = annotation
        }

        return annotationView
    }
}
