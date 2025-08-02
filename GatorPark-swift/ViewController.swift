import UIKit
import MapKit

class ViewController: UIViewController {

    let mapView = MKMapView()
    let recenterButton = UIButton(type: .system)

    struct Garage {
        let name: String
        let coordinate: CLLocationCoordinate2D
        let capacity: Int
        var currentCount: Int
        let hours: String
    }

    var garages: [Garage] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupMap()
        setupGarages()
        addGaragePins()
        addZoomButtons()
        addRecenterButton()
    }

    func setupMap() {
        mapView.frame = view.bounds
        view.addSubview(mapView)

        let center = CLLocationCoordinate2D(latitude: 29.6467, longitude: -82.3481)
        let region = MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: 0.035, longitudeDelta: 0.03)
        )
        mapView.setRegion(region, animated: true)

        let nwCorner = MKMapPoint(CLLocationCoordinate2D(latitude: 29.7050, longitude: -82.3900))
        let seCorner = MKMapPoint(CLLocationCoordinate2D(latitude: 29.6400, longitude: -82.2950))

        let width = abs(seCorner.x - nwCorner.x)
        let height = abs(seCorner.y - nwCorner.y)
        let boundaryRect = MKMapRect(x: nwCorner.x, y: seCorner.y, width: width, height: height)

        mapView.setCameraBoundary(MKMapView.CameraBoundary(mapRect: boundaryRect), animated: false)
        let zoomRange = MKMapView.CameraZoomRange(minCenterCoordinateDistance: 500, maxCenterCoordinateDistance: 7000)
        mapView.setCameraZoomRange(zoomRange, animated: false)

        mapView.delegate = self
        mapView.showsUserLocation = true
    }

    func setupGarages() {
        garages = [
            Garage(name: "Garage 5", coordinate: CLLocationCoordinate2D(latitude: 29.6485, longitude: -82.3460), capacity: 8, currentCount: 6, hours: "7 AM – 11 PM"),
            Garage(name: "Garage 7", coordinate: CLLocationCoordinate2D(latitude: 29.6478, longitude: -82.3432), capacity: 8, currentCount: 3, hours: "6 AM – 10 PM"),
            Garage(name: "Garage 9", coordinate: CLLocationCoordinate2D(latitude: 29.6513, longitude: -82.3419), capacity: 8, currentCount: 8, hours: "Open 24 hours"),
            Garage(name: "Garage 10", coordinate: CLLocationCoordinate2D(latitude: 29.6445, longitude: -82.3390), capacity: 8, currentCount: 8, hours: "7 AM – 9 PM"),
            Garage(name: "Garage 11", coordinate: CLLocationCoordinate2D(latitude: 29.6455, longitude: -82.3365), capacity: 8, currentCount: 5, hours: "6 AM – 11 PM"),
            Garage(name: "Garage 12 (Welcome Center)", coordinate: CLLocationCoordinate2D(latitude: 29.6467, longitude: -82.3481), capacity: 8, currentCount: 2, hours: "8 AM – 5 PM"),
            Garage(name: "Garage 13", coordinate: CLLocationCoordinate2D(latitude: 29.6525, longitude: -82.3485), capacity: 8, currentCount: 1, hours: "7 AM – 7 PM"),
            Garage(name: "Garage 14", coordinate: CLLocationCoordinate2D(latitude: 29.6455, longitude: -82.3470), capacity: 8, currentCount: 7, hours: "Open 24 hours"),
            Garage(name: "Library West Garage", coordinate: CLLocationCoordinate2D(latitude: 29.6519, longitude: -82.3432), capacity: 8, currentCount: 0, hours: "6 AM – Midnight")
        ]
    }

    func addGaragePins() {
        for garage in garages {
            let annotation = GarageAnnotation(garage: garage)
            mapView.addAnnotation(annotation)
        }
    }

    func addZoomButtons() {
        let zoomInButton = UIButton(frame: CGRect(x: view.bounds.width - 60, y: 100, width: 40, height: 40))
        zoomInButton.setTitle("+", for: .normal)
        zoomInButton.backgroundColor = .systemBlue
        zoomInButton.layer.cornerRadius = 8
        zoomInButton.addTarget(self, action: #selector(zoomIn), for: .touchUpInside)
        view.addSubview(zoomInButton)

        let zoomOutButton = UIButton(frame: CGRect(x: view.bounds.width - 60, y: 150, width: 40, height: 40))
        zoomOutButton.setTitle("-", for: .normal)
        zoomOutButton.backgroundColor = .systemBlue
        zoomOutButton.layer.cornerRadius = 8
        zoomOutButton.addTarget(self, action: #selector(zoomOut), for: .touchUpInside)
        view.addSubview(zoomOutButton)
    }

    func addRecenterButton() {
        recenterButton.setTitle("📍", for: .normal)
        recenterButton.backgroundColor = .systemGreen
        recenterButton.layer.cornerRadius = 20
        recenterButton.tintColor = .white
        recenterButton.frame = CGRect(x: view.bounds.width - 60, y: 210, width: 40, height: 40)
        recenterButton.addTarget(self, action: #selector(recenterMap), for: .touchUpInside)
        view.addSubview(recenterButton)
    }

    @objc func recenterMap() {
        if let userLocation = mapView.userLocation.location?.coordinate {
            let region = MKCoordinateRegion(center: userLocation, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            mapView.setRegion(region, animated: true)
        }
    }

    @objc func zoomIn() {
        var region = mapView.region
        region.span.latitudeDelta *= 0.5
        region.span.longitudeDelta *= 0.5
        mapView.setRegion(region, animated: true)
    }

    @objc func zoomOut() {
        var region = mapView.region
        region.span.latitudeDelta *= 2.0
        region.span.longitudeDelta *= 2.0
        mapView.setRegion(region, animated: true)
    }
}

class GarageAnnotation: MKPointAnnotation {
    let garage: ViewController.Garage

    init(garage: ViewController.Garage) {
        self.garage = garage
        super.init()
        self.coordinate = garage.coordinate
        self.title = garage.name
        self.subtitle = "\(garage.currentCount) / \(garage.capacity)"
    }
}

extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let garageAnnotation = annotation as? GarageAnnotation else { return nil }

        let identifier = "GarageCircle"

        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true

            let size: CGFloat = 20
            let circleView = UIView(frame: CGRect(x: -size/2, y: -size/2, width: size, height: size))
            circleView.tag = 100
            circleView.layer.cornerRadius = size / 2
            circleView.layer.borderColor = UIColor.white.cgColor
            circleView.layer.borderWidth = 2
            circleView.clipsToBounds = true
            let garage = garageAnnotation.garage
            let isFull = garage.currentCount >= garage.capacity
            circleView.backgroundColor = isFull ? .red : .blue

            let pulse = CABasicAnimation(keyPath: "transform.scale")
            pulse.fromValue = 1.0
            pulse.toValue = 1.2
            pulse.duration = 1.0
            pulse.autoreverses = true
            pulse.repeatCount = .infinity
            pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            circleView.layer.add(pulse, forKey: "pulse")

            annotationView?.addSubview(circleView)

            let infoButton = UIButton(type: .detailDisclosure)
            annotationView?.rightCalloutAccessoryView = infoButton
        } else {
            annotationView?.annotation = annotation
            if let circleView = annotationView?.viewWithTag(100) {
                let garage = garageAnnotation.garage
                let isFull = garage.currentCount >= garage.capacity
                circleView.backgroundColor = isFull ? .red : .blue
            }
        }

        return annotationView
    }

    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard let garageAnnotation = view.annotation as? GarageAnnotation else { return }

        let garage = garageAnnotation.garage
        let message = "Operating Hours: \(garage.hours)\nCapacity: \(garage.currentCount) / \(garage.capacity)"

        let alert = UIAlertController(
            title: garage.name,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Check In", style: .default, handler: { _ in
            if let index = self.garages.firstIndex(where: { $0.name == garage.name }) {
                if self.garages[index].currentCount < self.garages[index].capacity {
                    self.garages[index].currentCount += 1
                    let nonUserAnnotations = self.mapView.annotations.filter { !($0 is MKUserLocation) }
                    self.mapView.removeAnnotations(nonUserAnnotations)
                    self.addGaragePins()
                }
            }
        }))
        alert.addAction(UIAlertAction(title: "Check Out", style: .default, handler: { _ in
            if let index = self.garages.firstIndex(where: { $0.name == garage.name }) {
                if self.garages[index].currentCount > 0 {
                    self.garages[index].currentCount -= 1
                    let nonUserAnnotations = self.mapView.annotations.filter { !($0 is MKUserLocation) }
                    self.mapView.removeAnnotations(nonUserAnnotations)
                    self.addGaragePins()
                }
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}
