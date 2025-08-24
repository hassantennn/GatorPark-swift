import Foundation
import CoreLocation

struct Garage: Codable {
    let name: String
    let latitude: Double
    let longitude: Double
    var currentCount: Int
    var capacity: Int

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
