import Foundation
import FirebaseFirestore

final class GarageService {
    static let shared = GarageService()
    private let db = Firestore.firestore()
    private init() {}

    func observeGarages(onChange: @escaping ([Garage]) -> Void) {
        db.collection("garages").addSnapshotListener { snapshot, _ in
            let garages = snapshot?.documents.compactMap { Garage(from: $0) } ?? []
            onChange(garages)
        }
    }
}
