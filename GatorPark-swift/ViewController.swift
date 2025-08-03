import UIKit
import MapKit

class ViewController: UIViewController {

    let mapView = MKMapView()
    let recenterButton = UIButton(type: .system)
    let searchBar = UISearchBar()
    let suggestionsTableView = UITableView()
    private var filteredGarages: [Garage] = []

    struct Garage {
        let name: String
        let coordinate: CLLocationCoordinate2D
        var currentCount: Int
        /// The maximum number of vehicles the garage can hold.
        /// Defaults to a small value for easier testing.
        var capacity: Int = 2
    }

    class GarageAnnotation: NSObject, MKAnnotation {
        var garage: Garage
        var coordinate: CLLocationCoordinate2D { garage.coordinate }
        var title: String? { garage.name }
        var subtitle: String? { "Spaces: \(garage.currentCount)/\(garage.capacity)" }
        var isFull: Bool { garage.currentCount >= garage.capacity }

        init(garage: Garage) {
            self.garage = garage
        }
    }

    // Data source: exact coordinates for each garage
    var garages: [Garage] = []
    private var allGarages: [Garage] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupMap()
        setupSearchBar()
        setupSuggestionsTableView()
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

    private func setupSearchBar() {
        searchBar.delegate = self
        searchBar.showsCancelButton = true
        searchBar.placeholder = "Search garages or open spots"
        searchBar.searchBarStyle = .minimal
        searchBar.backgroundImage = UIImage()

        if #available(iOS 13.0, *) {
            let textField = searchBar.searchTextField
            textField.backgroundColor = .systemBackground
            textField.layer.cornerRadius = 10
            textField.layer.masksToBounds = true
        }

        searchBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar)
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8)
        ])
    }
    private let suggestionCellID = "SuggestionCell"

    private func setupSuggestionsTableView() {
        suggestionsTableView.isHidden = true
        suggestionsTableView.delegate = self
        suggestionsTableView.dataSource = self
        suggestionsTableView.backgroundColor = .systemBackground
        suggestionsTableView.register(UITableViewCell.self, forCellReuseIdentifier: suggestionCellID)
        suggestionsTableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(suggestionsTableView)
        view.bringSubviewToFront(suggestionsTableView)

        NSLayoutConstraint.activate([
            suggestionsTableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            suggestionsTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            suggestionsTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            suggestionsTableView.heightAnchor.constraint(equalToConstant: 200)
        ])
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
        allGarages = garages
    }

    private func addGaragePins(fitAll: Bool = true) {
        mapView.removeAnnotations(mapView.annotations.filter { !($0 is MKUserLocation) })
        for garage in garages {
            let annotation = GarageAnnotation(garage: garage)
            mapView.addAnnotation(annotation)
        }
        // Fit map to show all pins if requested
        guard fitAll else { return }
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

            let checkIn = UIButton(type: .system)
            checkIn.setTitle("In", for: .normal)
            checkIn.setTitleColor(.white, for: .normal)
            checkIn.backgroundColor = .systemGreen
            checkIn.frame = CGRect(x: 0, y: 0, width: 44, height: 30)
            checkIn.layer.cornerRadius = 5
            view?.leftCalloutAccessoryView = checkIn

            let checkOut = UIButton(type: .system)
            checkOut.setTitle("Out", for: .normal)
            checkOut.setTitleColor(.white, for: .normal)
            checkOut.backgroundColor = .systemOrange
            checkOut.frame = CGRect(x: 0, y: 0, width: 44, height: 30)
            checkOut.layer.cornerRadius = 5
            view?.rightCalloutAccessoryView = checkOut
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

    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard let garageAnnotation = view.annotation as? GarageAnnotation,
              let index = garages.firstIndex(where: { $0.name == garageAnnotation.garage.name }) else { return }

        if control == view.leftCalloutAccessoryView {
            if garages[index].currentCount < garages[index].capacity {
                garages[index].currentCount += 1
                garageAnnotation.garage.currentCount = garages[index].currentCount
            }
        } else if control == view.rightCalloutAccessoryView {
            if garages[index].currentCount > 0 {
                garages[index].currentCount -= 1
                garageAnnotation.garage.currentCount = garages[index].currentCount
            }
        }

        if let annView = mapView.view(for: garageAnnotation) {
            annView.backgroundColor = garageAnnotation.isFull ? .systemRed : .systemBlue
            annView.annotation = garageAnnotation
            mapView.selectAnnotation(garageAnnotation, animated: false)
        }
    }
}

extension ViewController: UISearchBarDelegate {
    private func performSearch(text: String) {
        if let spots = Int(text) {
            garages = allGarages.filter { $0.capacity - $0.currentCount > spots }
            addGaragePins()
        } else if let garage = allGarages.first(where: { $0.name.lowercased().contains(text.lowercased()) }) {
            garages = allGarages
            addGaragePins(fitAll: false)
            let region = MKCoordinateRegion(center: garage.coordinate,
                                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            mapView.setRegion(region, animated: true)
            if let annotation = mapView.annotations.first(where: {
                ($0 as? GarageAnnotation)?.garage.name == garage.name
            }) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.mapView.selectAnnotation(annotation, animated: true)
                }
            }
        }
    }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        suggestionsTableView.isHidden = true
        guard let text = searchBar.text, !text.isEmpty else { return }
        performSearch(text: text)
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredGarages.removeAll()
            suggestionsTableView.isHidden = true
            garages = allGarages
            addGaragePins()
        } else if Int(searchText) == nil {
            filteredGarages = allGarages.filter { $0.name.lowercased().contains(searchText.lowercased()) }
            suggestionsTableView.isHidden = filteredGarages.isEmpty
            suggestionsTableView.reloadData()
        } else {
            filteredGarages.removeAll()
            suggestionsTableView.isHidden = true
        }
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = nil
        searchBar.resignFirstResponder()
        filteredGarages.removeAll()
        suggestionsTableView.isHidden = true
        garages = allGarages
        addGaragePins()
    }
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredGarages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: suggestionCellID, for: indexPath)

        cell.textLabel?.text = filteredGarages[indexPath.row].name
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let garage = filteredGarages[indexPath.row]
        searchBar.text = garage.name
        suggestionsTableView.isHidden = true
        searchBar.resignFirstResponder()
        performSearch(text: garage.name)
    }
}
