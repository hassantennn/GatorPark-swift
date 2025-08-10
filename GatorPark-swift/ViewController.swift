import UIKit
import MapKit
import UserNotifications

class ViewController: UIViewController {

    let service = GarageService.shared
    let mapView = MKMapView()
    let searchBar = UISearchBar()
    let suggestionsTableView = UITableView()
    let suggestionsBlurView: UIVisualEffectView = {
        let effect: UIBlurEffect
        if #available(iOS 13.0, *) {
            effect = UIBlurEffect(style: .systemMaterial)
        } else {
            effect = UIBlurEffect(style: .light)
        }
        let view = UIVisualEffectView(effect: effect)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()
    private var filteredGarages: [Garage] = []
    private var checkedInGarage: String?

    class GarageAnnotation: NSObject, MKAnnotation {
        var garage: Garage
        var coordinate: CLLocationCoordinate2D { garage.coordinate }
        var title: String? { garage.name }
        var subtitle: String? {
            let occupied = garage.currentCount
            let capacity = garage.capacity
            let availability: String
            switch occupied {
            case 0..<4:
                availability = "high availability"
            case 4..<8:
                availability = "moderate availability"
            case 8...capacity:
                availability = "low availability"
            default:
                availability = "low availability"
            }
            return "Spaces: \(occupied)/\(capacity) - \(availability)"
        }
        /// Fraction of occupied spaces 0.0...1.0
        var occupancy: Float {
            guard garage.capacity > 0 else { return 0 }
            return Float(garage.currentCount) / Float(garage.capacity)
        }

        /// Textual status for the current occupancy level.
        var statusText: String {
            switch occupancy {
            case 0..<0.33:
                return "Empty"
            case 0..<0.66:
                return "Moderate"
            default:
                return "Busy"
            }
        }
        var isFull: Bool { garage.currentCount >= garage.capacity }

        init(garage: Garage) {
            self.garage = garage
        }
    }

    // Data source: exact coordinates for each garage
    var garages: [Garage] = []
    private var allGarages: [Garage] = []
    private var hasAnimatedInitialPins = false
    private let checkoutReminderID = "checkoutReminder"

    override func viewDidLoad() {
        super.viewDidLoad()
        setupMap()
        setupSearchBar()
        setupSuggestionsTableView()
        service.fetchGarages { [weak self] garages in
            self?.garages = garages
            self?.allGarages = garages
            self?.addGaragePins()
        }
        service.listenForUpdates { [weak self] garage in
            self?.updateGarage(garage)
        }
        addZoomButtons()
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
        suggestionsTableView.delegate = self
        suggestionsTableView.dataSource = self
        suggestionsTableView.backgroundColor = .clear
        suggestionsTableView.register(UITableViewCell.self, forCellReuseIdentifier: suggestionCellID)
        suggestionsTableView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(suggestionsBlurView)
        suggestionsBlurView.contentView.addSubview(suggestionsTableView)
        view.bringSubviewToFront(suggestionsBlurView)
        setSuggestionsHidden(true)

        NSLayoutConstraint.activate([
            suggestionsBlurView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            suggestionsBlurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            suggestionsBlurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            suggestionsBlurView.heightAnchor.constraint(equalToConstant: 200),

            suggestionsTableView.topAnchor.constraint(equalTo: suggestionsBlurView.contentView.topAnchor),
            suggestionsTableView.leadingAnchor.constraint(equalTo: suggestionsBlurView.contentView.leadingAnchor),
            suggestionsTableView.trailingAnchor.constraint(equalTo: suggestionsBlurView.contentView.trailingAnchor),
            suggestionsTableView.bottomAnchor.constraint(equalTo: suggestionsBlurView.contentView.bottomAnchor)
        ])
    }

    private func setSuggestionsHidden(_ hidden: Bool) {
        suggestionsTableView.isHidden = hidden
        suggestionsBlurView.isHidden = hidden
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

    private func updateGarage(_ updated: Garage) {
        if let idx = garages.firstIndex(where: { $0.name == updated.name }) {
            garages[idx] = updated
        }
        if let idx = allGarages.firstIndex(where: { $0.name == updated.name }) {
            allGarages[idx] = updated
        }
        if let annotation = mapView.annotations.first(where: { ($0 as? GarageAnnotation)?.garage.name == updated.name }) as? GarageAnnotation {
            annotation.garage = updated
            if let annView = mapView.view(for: annotation) as? MKMarkerAnnotationView {
                let color = annotation.isFull ? UIColor.systemRed : UIColor.systemBlue
                annView.markerTintColor = color
                if let stack = annView.detailCalloutAccessoryView as? UIStackView,
                   let statusLabel = stack.arrangedSubviews.first as? UILabel,
                   let progress = stack.arrangedSubviews.last as? UIProgressView {
                    statusLabel.text = annotation.statusText
                    progress.progress = annotation.occupancy
                }
                annView.annotation = annotation
            }
        } else {
            addGaragePins(fitAll: false)
        }
    }

    private func addZoomButtons() {
        let zoomInButton = UIButton(type: .system)
        zoomInButton.setTitle("+", for: .normal)
        zoomInButton.tintColor = .white
        zoomInButton.backgroundColor = UIColor(red: 0, green: 0, blue: 0.5, alpha: 1.0)
        zoomInButton.addTarget(self, action: #selector(zoomIn), for: .touchUpInside)

        let zoomOutButton = UIButton(type: .system)
        zoomOutButton.setTitle("-", for: .normal)
        zoomOutButton.tintColor = .white
        zoomOutButton.backgroundColor = UIColor(red: 0, green: 0, blue: 0.5, alpha: 1.0)
        zoomOutButton.addTarget(self, action: #selector(zoomOut), for: .touchUpInside)

        let zoomInFrame = CGRect(x: view.bounds.width - 60, y: 120, width: 40, height: 40)
        let zoomOutFrame = CGRect(x: view.bounds.width - 60, y: 170, width: 40, height: 40)

        view.addSubview(makeBlurContainer(for: zoomInButton, frame: zoomInFrame, cornerRadius: 8))
        view.addSubview(makeBlurContainer(for: zoomOutButton, frame: zoomOutFrame, cornerRadius: 8))
    }

    private func makeBlurContainer(for button: UIButton, frame: CGRect, cornerRadius: CGFloat) -> UIView {
        if #available(iOS 13.0, *) {
            let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterialDark))
            blur.frame = frame
            blur.layer.cornerRadius = cornerRadius
            blur.clipsToBounds = true
            blur.overrideUserInterfaceStyle = .dark
            button.frame = blur.bounds
            blur.contentView.addSubview(button)
            return blur
        } else {
            button.frame = frame
            button.backgroundColor = UIColor(red: 0, green: 0, blue: 0.5, alpha: 1.0)
            button.layer.cornerRadius = cornerRadius
            return button
        }
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

    private func scheduleCheckoutReminder(for garage: Garage) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [checkoutReminderID])
        let content = UNMutableNotificationContent()
        content.title = "Checkout Reminder"
        content.body = "Don't forget to check out of \(garage.name)."
        // Trigger a reminder 2.5 hours (9,000 seconds) after check-in
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2.5 * 60 * 60, repeats: false)
        let request = UNNotificationRequest(identifier: checkoutReminderID, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    private func cancelCheckoutReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [checkoutReminderID])
        center.removeDeliveredNotifications(withIdentifiers: [checkoutReminderID])
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !(annotation is MKUserLocation) else { return nil }
        let id = "Garage"
        var view = mapView.dequeueReusableAnnotationView(withIdentifier: id) as? MKMarkerAnnotationView
        if view == nil {
            view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: id)
            view?.canShowCallout = true

            let checkIn = UIButton(type: .system)
            checkIn.setTitle("In", for: .normal)
            checkIn.tintColor = .systemGreen
            checkIn.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.2)
            checkIn.frame = CGRect(x: 0, y: 0, width: 60, height: 34)
            checkIn.layer.cornerRadius = 5
            view?.leftCalloutAccessoryView = checkIn

            let checkOut = UIButton(type: .system)
            checkOut.setTitle("Out", for: .normal)
            checkOut.tintColor = .systemOrange
            checkOut.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.2)
            checkOut.frame = CGRect(x: 0, y: 0, width: 60, height: 34)
            checkOut.layer.cornerRadius = 5
            view?.rightCalloutAccessoryView = checkOut
        } else {
            view?.annotation = annotation
        }
        if let garageAnnotation = annotation as? GarageAnnotation {
            // Reflect the garage availability with annotation color.
            let color = garageAnnotation.isFull ? UIColor.systemRed : UIColor.systemBlue
            view?.markerTintColor = color
            view?.glyphText = "P"
            view?.glyphTintColor = .white

            // Status indicator within callout
            let statusLabel = UILabel()
            statusLabel.font = UIFont.systemFont(ofSize: 12)
            statusLabel.text = garageAnnotation.statusText

            let progress = UIProgressView(progressViewStyle: .default)
            progress.progress = garageAnnotation.occupancy

            let stack = UIStackView(arrangedSubviews: [statusLabel, progress])
            stack.axis = .vertical
            stack.spacing = 4
            stack.translatesAutoresizingMaskIntoConstraints = false
            stack.widthAnchor.constraint(equalToConstant: 120).isActive = true

            view?.detailCalloutAccessoryView = stack
        }
        return view
    }

    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        guard !hasAnimatedInitialPins else { return }
        hasAnimatedInitialPins = true
        for (index, view) in views.enumerated() {
            guard !(view.annotation is MKUserLocation) else { continue }
            let dropOffset = mapView.bounds.size.height
            view.transform = CGAffineTransform(translationX: 0, y: -dropOffset)
            UIView.animate(
                withDuration: 0.6,
                delay: 0.05 * Double(index),
                usingSpringWithDamping: 0.6,
                initialSpringVelocity: 0.8,
                options: [.curveEaseInOut],
                animations: {
                    view.transform = .identity
                }
            )
        }
    }

    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard let garageAnnotation = view.annotation as? GarageAnnotation,
              let index = garages.firstIndex(where: { $0.name == garageAnnotation.garage.name }) else { return }

        let isCheckIn = control == view.leftCalloutAccessoryView
        if isCheckIn {
            if let current = checkedInGarage {
                let message = current == garageAnnotation.garage.name ? "You are already checked in here." : "You are already checked in at \(current). Please check out before checking in to another garage."
                showAlert(title: "Already Checked In", message: message)
                return
            }
        } else {
            guard let current = checkedInGarage else {
                showAlert(title: "Not Checked In", message: "You are not currently checked in to any garage.")
                return
            }
            guard current == garageAnnotation.garage.name else {
                showAlert(title: "Wrong Garage", message: "You are checked in at \(current).")
                return
            }
        }

        let actionText = isCheckIn ? "check in" : "check out"
        let alert = UIAlertController(title: "Confirm", message: "Are you sure you want to \(actionText)?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Confirm", style: .default) { [weak self] _ in
            guard let self = self else { return }
            if isCheckIn {
                if self.garages[index].currentCount < self.garages[index].capacity {
                    self.garages[index].currentCount += 1
                    garageAnnotation.garage.currentCount = self.garages[index].currentCount
                    self.checkedInGarage = garageAnnotation.garage.name
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    self.scheduleCheckoutReminder(for: garageAnnotation.garage)
                    self.service.checkIn(garageName: garageAnnotation.garage.name)
                }
            } else {
                if self.garages[index].currentCount > 0 {
                    self.garages[index].currentCount -= 1
                    garageAnnotation.garage.currentCount = self.garages[index].currentCount
                    self.checkedInGarage = nil
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    self.cancelCheckoutReminder()
                    self.service.checkOut(garageName: garageAnnotation.garage.name)
                }
            }

            if let annView = self.mapView.view(for: garageAnnotation) as? MKMarkerAnnotationView {
                let color = garageAnnotation.isFull ? UIColor.systemRed : UIColor.systemBlue
                annView.markerTintColor = color
                annView.annotation = garageAnnotation
                self.mapView.selectAnnotation(garageAnnotation, animated: false)

                if let stack = annView.detailCalloutAccessoryView as? UIStackView,
                   let statusLabel = stack.arrangedSubviews.first as? UILabel,
                   let progress = stack.arrangedSubviews.last as? UIProgressView {
                    statusLabel.text = garageAnnotation.statusText
                    progress.progress = garageAnnotation.occupancy
                }
            }
        })
        present(alert, animated: true)
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
        setSuggestionsHidden(true)
        guard let text = searchBar.text, !text.isEmpty else { return }
        performSearch(text: text)
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredGarages.removeAll()
            setSuggestionsHidden(true)
            garages = allGarages
            addGaragePins()
        } else if Int(searchText) == nil {
            filteredGarages = allGarages.filter { $0.name.lowercased().contains(searchText.lowercased()) }
            setSuggestionsHidden(filteredGarages.isEmpty)
            suggestionsTableView.reloadData()
        } else {
            filteredGarages.removeAll()
            setSuggestionsHidden(true)
        }
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = nil
        searchBar.resignFirstResponder()
        filteredGarages.removeAll()
        setSuggestionsHidden(true)
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
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        cell.textLabel?.text = filteredGarages[indexPath.row].name
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let garage = filteredGarages[indexPath.row]
        searchBar.text = garage.name
        setSuggestionsHidden(true)
        searchBar.resignFirstResponder()
        performSearch(text: garage.name)
    }
}
