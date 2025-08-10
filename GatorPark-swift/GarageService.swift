import Foundation

final class GarageService {
    static let shared = GarageService()
    private let baseURL = URL(string: "http://localhost:3000")!
    private var webSocketTask: URLSessionWebSocketTask?

    func fetchGarages(completion: @escaping ([Garage]) -> Void) {
        let url = baseURL.appendingPathComponent("garages")
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data,
               let garages = try? JSONDecoder().decode([Garage].self, from: data) {
                DispatchQueue.main.async {
                    completion(garages)
                }
            } else {
                DispatchQueue.main.async { completion([]) }
            }
        }.resume()
    }

    func listenForUpdates(onUpdate: @escaping (Garage) -> Void) {
        let wsURL = URL(string: "ws://localhost:3000")!
        webSocketTask = URLSession.shared.webSocketTask(with: wsURL)
        webSocketTask?.resume()
        receiveUpdate(onUpdate)
    }

    private func receiveUpdate(_ onUpdate: @escaping (Garage) -> Void) {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .data(let data):
                    if let garage = try? JSONDecoder().decode(Garage.self, from: data) {
                        DispatchQueue.main.async { onUpdate(garage) }
                    }
                case .string(let string):
                    if let data = string.data(using: .utf8),
                       let garage = try? JSONDecoder().decode(Garage.self, from: data) {
                        DispatchQueue.main.async { onUpdate(garage) }
                    }
                @unknown default:
                    break
                }
            case .failure:
                break
            }
            self?.receiveUpdate(onUpdate)
        }
    }

    func checkIn(garageName: String) {
        updateGarage(garageName: garageName, action: "checkin")
    }

    func checkOut(garageName: String) {
        updateGarage(garageName: garageName, action: "checkout")
    }

    private func updateGarage(garageName: String, action: String) {
        guard let encoded = garageName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else { return }
        let url = baseURL.appendingPathComponent("garages/")
            .appendingPathComponent(encoded)
            .appendingPathComponent(action)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        URLSession.shared.dataTask(with: request).resume()
    }
}
