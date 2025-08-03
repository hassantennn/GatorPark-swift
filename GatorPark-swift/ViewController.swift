import UIKit
import MapKit

class ViewController: UIViewController {

    let mapView = MKMapView()
    let recenterButton = UIButton(type: .system)

    struct Garage {
        let name: String
        let coordinate: CLLocationCoordinate2D
        var currentCount: Int
        var capacity: Int = 100
    }

    class GarageAnnotation: NSObject, MKAnnotation {
        let garage: Garage
        var coordinate: CLLocationCoordinate2D { garage.coordinate }
        var title: String? { garage.name }
        var subtitle: String? { "Spaces: \(garage.currentCount)/\(garage.capacity)" }
        var isFull: Bool { garage.currentCount == 0 }

        init(garage: Garage) {
            self.garage = garage
        }
    }

    // Data source: exact coordinates for each garage
    var garages: [Garage] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupMap()
        setupGarages()  // load coordinate data
        addGaragePins()  // drop pins
        addZoomButtons()
        addRecenterButton()
    }

    private func setupMap() {
        mapView.frame = view.bounds
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(mapView)

        // Dark, muted Apple Maps style
        if #available(iOS 13.0, *) {
            mapView.overrideUserInterfaceStyle = .dark
            let config = MKStandardMapConfiguration(elevationStyle: .realistic,
                                                    emphasisStyle: .muted)
            mapView.preferredConfiguration = config
        } else {
            mapView.mapType = .standard
        }

        // Initial region centered on campus
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 29.6467, longitude: -82.3481),
            span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
        )
        mapView.setRegion(region, animated: true)

        // Allow wide zoom range
        let boundaryPoints = [
            CLLocationCoordinate2D(latitude: 29.7050, longitude: -82.3900),
            CLLocationCoordinate2D(latitude: 29.6400, longitude: -82.2950)
        ]
        let mapPoints = boundaryPoints.map { MKMapPoint($0) }
        let xs = mapPoints.map { $0.x }
        let ys = mapPoints.map { $0.y }
        let boundaryRect = MKMapRect(
            x: xs.min()!,
            y: ys.min()!,
            width: xs.max()! - xs.min()!,
            height: ys.max()! - ys.min()!
        )
        mapView.setCameraBoundary(MKMapView.CameraBoundary(mapRect: boundaryRect), animated: false)
        mapView.setCameraZoomRange(
            MKMapView.CameraZoomRange(minCenterCoordinateDistance: 500,
                                      maxCenterCoordinateDistance: 200_000),
            animated: false
        )

        mapView.delegate = self
        mapView.showsUserLocation = true
    }

    private func setupGarages() {
        // Exact lat/lng from user
        garages = [
            Garage(name: "Rawlings", coordinate: CLLocationCoordinate2D(latitude: 29.645255, longitude: -82.342954), currentCount: 0),
            Garage(name: "Reitz Garage", coordinate: CLLocationCoordinate2D(latitude: 29.645568, longitude: -82.348437), currentCount: 0),
            Garage(name: "McCarty", coordinate: CLLocationCoordinate2D(latitude: 29.645974, longitude: -82.344066), currentCount: 0),
            Garage(name: "Garage 5", coordinate: CLLocationCoordinate2D(latitude: 29.643310, longitude: -82.351471), currentCount: 0),
            Garage(name: "Garage 14", coordinate: CLLocationCoordinate2D(latitude: 29.642376, longitude: -82.351335), currentCount: 0),
            Garage(name: "NPB", coordinate: CLLocationCoordinate2D(latitude: 29.641503, longitude: -82.351335), currentCount: 0),
            Garage(name: "Garage 13", coordinate: CLLocationCoordinate2D(latitude: 29.640541, longitude: -82.349703), currentCount: 0),
            Garage(name: "Garage 11", coordinate: CLLocationCoordinate2D(latitude: 29.636293, longitude: -82.368394), currentCount: 0),
            Garage(name: "Garage 3", coordinate: CLLocationCoordinate2D(latitude: 29.638681, longitude: -82.347755), currentCount: 0),
            Garage(name: "Garage 10", coordinate: CLLocationCoordinate2D(latitude: 29.640786, longitude: -82.341755), currentCount: 0),
            Garage(name: "Garage 1", coordinate: CLLocationCoordinate2D(latitude: 29.640989, longitude: -82.342083), currentCount: 0), // converted DMS to decimal
            Garage(name: "Health East", coordinate: CLLocationCoordinate2D(latitude: 29.640946, longitude: -82.340770), currentCount: 0),
            Garage(name: "Garage 2", coordinate: CLLocationCoordinate2D(latitude: 29.638830, longitude: -82.346726), currentCount: 0),
            Garage(name: "Southwest 1", coordinate: CLLocationCoordinate2D(latitude: 29.637171, longitude: -82.368639), currentCount: 0),
            Garage(name: "Southwest 2", coordinate: CLLocationCoordinate2D(latitude: 29.636731, longitude: -82.364778), currentCount: 0),
            Garage(name: "Maguire Parking", coordinate: CLLocationCoordinate2D(latitude: 29.640755, longitude: -82.368668), currentCount: 0),
            Garage(name: "Southwest Tennis", coordinate: CLLocationCoordinate2D(latitude: 29.638010, longitude: -82.367084), currentCount: 0),
            Garage(name: "Southwest Lot 4", coordinate: CLLocationCoordinate2D(latitude: 29.637503, longitude: -82.367424), currentCount: 0),
            Garage(name: "Garage 7", coordinate: CLLocationCoordinate2D(latitude: 29.650583, longitude: -82.350972), currentCount: 0), // DMS converted
            Garage(name: "Stadium 1", coordinate: CLLocationCoordinate2D(latitude: 29.651728, longitude: -82.349180), currentCount: 0),
            Garage(name: "Stadium 2", coordinate: CLLocationCoordinate2D(latitude: 29.649024, longitude: -82.347825), currentCount: 0),
            Garage(name: "Stadium 3", coordinate: CLLocationCoordinate2D(latitude: 29.649791, longitude: -82.350006), currentCount: 0),
            Garage(name: "Tigert Parking", coordinate: CLLocationCoordinate2D(latitude: 29.649380, longitude: -82.340550), currentCount: 0)
        ]
    }

    private func addGaragePins() {
        mapView.removeAnnotations(mapView.annotations.filter { !($0 is MKUserLocation) })
        for garage in garages {
            let annotation = GarageAnnotation(garage: garage)
            mapView.addAnnotation(annotation)
        }
        // Fit map to show all pins
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let pins = self.mapView.annotations.filter { !($0 is MKUserLocation) }
            self.mapView.showAnnotations(pins, animated: true)
        }
    }

    private func addZoomButtons() {
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

    private func addRecenterButton() {
        recenterButton.setTitle("📍", for: .normal)
        recenterButton.backgroundColor = .systemGreen
        recenterButton.layer.cornerRadius = 20
        recenterButton.tintColor = .white
        recenterButton.frame = CGRect(x: view.bounds.width - 60, y: 210, width: 40, height: 40)
        recenterButton.addTarget(self, action: #selector(recenterMap), for: .touchUpInside)
        view.addSubview(recenterButton)
    }

    @objc private func recenterMap() {
        guard let loc = mapView.userLocation.location?.coordinate else { return }
        let region = MKCoordinateRegion(center: loc, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        mapView.setRegion(region, animated: true)
    }

    @objc private func zoomIn() {
        var r = mapView.region
        r.span.latitudeDelta *= 0.5
        r.span.longitudeDelta *= 0.5
        mapView.setRegion(r, animated: true)
    }

    @objc private func zoomOut() {
        var r = mapView.region
        r.span.latitudeDelta *= 2
        r.span.longitudeDelta *= 2
        mapView.setRegion(r, animated: true)
    }
}

extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !(annotation is MKUserLocation) else { return nil }
        let id = "Garage"
        var view = mapView.dequeueReusableAnnotationView(withIdentifier: id)
        if view == nil {
            view = MKAnnotationView(annotation: annotation, reuseIdentifier: id)
            view?.canShowCallout = true
            view?.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
            view?.layer.cornerRadius = 10
        } else {
            view?.annotation = annotation
        }
        if let garageAnnotation = annotation as? GarageAnnotation {
            // Display a red circle regardless of garage availability.
            // Full garages remain red and non-full garages are also red.
            // This removes the previous blue state.
            view?.backgroundColor = .systemRed
        }
        return view
    }
}
