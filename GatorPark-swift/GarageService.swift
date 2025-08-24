import Foundation
import FirebaseFirestore

final class GarageService {
    static let shared = GarageService()
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    private init() {}

    func observeGarages(onChange: @escaping ([Garage]) -> Void) {
        listener?.remove()
        listener = db.collection("garages").addSnapshotListener { snapshot, _ in
            guard let documents = snapshot?.documents else {
                onChange([])
                return
            }
            let garages = documents.compactMap { Garage(from: $0) }
            onChange(garages)
        }
    }

    func checkIn(garageName: String) {
        db.collection("garages").document(garageName).updateData([
            "currentCount": FieldValue.increment(Int64(1))
        ])
    }

    func checkOut(garageName: String) {
        db.collection("garages").document(garageName).updateData([
            "currentCount": FieldValue.increment(Int64(-1))
        ])
    }
}

