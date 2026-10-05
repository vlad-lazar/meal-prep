@preconcurrency import CoreLocation
import MealPrepCore

enum LocationError: Error {
    case denied, timeout, notFound
}

@MainActor
final class LocationService {
    private let manager = CLLocationManager()

    var isAuthorized: Bool {
        [.authorizedWhenInUse, .authorizedAlways].contains(manager.authorizationStatus)
    }
    var isDenied: Bool {
        [.denied, .restricted].contains(manager.authorizationStatus)
    }

    /// Asks for "When In Use" permission if needed and returns the first fix (15 s timeout).
    func currentCoordinate(timeout: Duration = .seconds(15)) async throws -> Coordinate {
        if isDenied { throw LocationError.denied }
        // While the permission alert is up the clock shouldn't run out on a slow reader.
        let timeout = manager.authorizationStatus == .notDetermined ? .seconds(60) : timeout
        let session = CLServiceSession(authorization: .whenInUse)
        defer { session.invalidate() }
        return try await withThrowingTaskGroup(of: Coordinate.self) { group in
            group.addTask {
                for try await update in CLLocationUpdate.liveUpdates() {
                    if update.authorizationDenied || update.authorizationDeniedGlobally { throw LocationError.denied }
                    if let location = update.location {
                        return Coordinate(latitude: location.coordinate.latitude,
                                          longitude: location.coordinate.longitude)
                    }
                }
                throw LocationError.notFound
            }
            group.addTask {
                try await Task.sleep(for: timeout)
                throw LocationError.timeout
            }
            let first = try await group.next()!
            group.cancelAll()
            return first
        }
    }

    /// Neighbourhood or town name for the location chip.
    func label(for coordinate: Coordinate) async -> String {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let placemark = try? await CLGeocoder().reverseGeocodeLocation(location).first
        return placemark?.subLocality ?? placemark?.locality ?? "Near you"
    }

    func geocode(postcode: String) async throws -> (Coordinate, String) {
        let placemarks = try await CLGeocoder().geocodeAddressString("\(postcode), Denmark")
        guard let placemark = placemarks.first, let location = placemark.location else { throw LocationError.notFound }
        let coordinate = Coordinate(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        return (coordinate, placemark.locality.map { "\(postcode) \($0)" } ?? postcode)
    }
}
