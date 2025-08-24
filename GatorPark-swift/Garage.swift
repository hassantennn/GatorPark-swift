import Foundation
import CoreLocation
import FirebaseFirestore

struct Garage {
    let name: String
    let location: GeoPoint
    let capacity: Int
    var currentCount: Int
    let isOpen: Bool

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
    }

    init?(from snapshot: DocumentSnapshot) {
        guard let data = snapshot.data(),
              let name = data["name"] as? String,
              let location = data["location"] as? GeoPoint,
              let capacity = data["capacity"] as? Int,
              let currentCount = data["currentCount"] as? Int,
              let isOpen = data["isOpen"] as? Bool else {
            return nil
        }
        self.name = name
        self.location = location
        self.capacity = capacity
        self.currentCount = currentCount
        self.isOpen = isOpen
    }
}
