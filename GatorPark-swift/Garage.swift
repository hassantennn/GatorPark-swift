import Foundation
import CoreLocation
import FirebaseFirestore

struct Garage {
    let id: String
    let name: String
    let coordinate: CLLocationCoordinate2D
    let capacity: Int
    var currentCount: Int
    let isOpen: Bool

    init?(from document: DocumentSnapshot) {
        guard let data = document.data(),
              let name = data["name"] as? String,
              let latitude = data["latitude"] as? CLLocationDegrees,
              let longitude = data["longitude"] as? CLLocationDegrees,
              let capacity = data["capacity"] as? Int,
              let currentCount = data["currentCount"] as? Int,
              let isOpen = data["isOpen"] as? Bool else {
            return nil
        }
        self.id = document.documentID
        self.name = name
        self.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        self.capacity = capacity
        self.currentCount = currentCount
        self.isOpen = isOpen
    }
}
