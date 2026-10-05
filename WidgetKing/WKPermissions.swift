import Foundation
import CoreLocation
import EventKit

// Widgets can't ask for permissions; the app asks the moment the library
// first needs one (a weather or sun/moon element → location, calendar
// element → calendar, reminders element → reminders), and stores the
// location in the App Group for the extension's Open-Meteo calls.
final class WKPermissions: NSObject, CLLocationManagerDelegate {
    static let shared = WKPermissions()
    private let manager = CLLocationManager()
    private var wantsLocation = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func requestWhatTheLibraryNeeds() {
        let designs = WKStore.designs()
        var kinds = Set<String>()
        for d in designs {
            for el in d.elements { kinds.insert(el.kind) }
            for row in d.lockRows { kinds.insert(row.kind) }
        }
        if kinds.contains("weather") || kinds.contains("astro") { requestLocation() }
        if kinds.contains("calendar") { requestCalendar() }
        if kinds.contains("reminders") || kinds.contains("reminder") { requestReminders() }
    }

    func requestLocation() {
        wantsLocation = true
        switch manager.authorizationStatus {
        case .notDetermined: manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways: manager.requestLocation()
        default: break
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if wantsLocation, manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        WKLiveFetch.setLocation(lat: loc.coordinate.latitude, lon: loc.coordinate.longitude)
        wantsLocation = false
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}

    func requestCalendar() {
        if EKEventStore.authorizationStatus(for: .event) == .notDetermined {
            EKEventStore().requestFullAccessToEvents { _, _ in }
        }
    }

    func requestReminders() {
        if EKEventStore.authorizationStatus(for: .reminder) == .notDetermined {
            EKEventStore().requestFullAccessToReminders { _, _ in }
        }
    }
}
