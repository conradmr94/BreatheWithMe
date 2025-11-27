//
//  WalkLocationManager.swift
//  BreatheWithMe
//
//  Manages location tracking, route recording, and walk metrics calculation
//

import Foundation
import CoreLocation
import Combine

@MainActor
final class WalkLocationManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var currentDistance: Double = 0 // meters
    @Published var currentPace: Double = 0 // seconds per km
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isTracking: Bool = false
    @Published var route: [CLLocationCoordinate2D] = []
    @Published var currentSpeed: Double = 0 // meters per second
    
    // MARK: - Private Properties
    
    private let locationManager = CLLocationManager()
    private var routeLocations: [CLLocation] = []
    private var lastLocation: CLLocation?
    private var sessionStartTime: Date?
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    // MARK: - Setup
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.activityType = .fitness
        locationManager.distanceFilter = 5 // Update every 5 meters
        locationManager.allowsBackgroundLocationUpdates = false
        authorizationStatus = locationManager.authorizationStatus
        
        // If already authorized, start monitoring location immediately
        if authorizationStatus == .authorizedWhenInUse || 
           authorizationStatus == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }
    
    // MARK: - Public Methods
    
    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    /// Start getting location updates to show user's current position (without tracking a route)
    func startMonitoringLocation() {
        guard authorizationStatus == .authorizedWhenInUse || 
              authorizationStatus == .authorizedAlways else {
            print("⚠️ WalkLocationManager: Location not authorized for monitoring")
            requestAuthorization()
            return
        }
        
        print("✅ WalkLocationManager: Starting location monitoring")
        locationManager.startUpdatingLocation()
    }
    
    /// Stop getting location updates
    func stopMonitoringLocation() {
        if !isTracking {
            print("🛑 WalkLocationManager: Stopping location monitoring")
            locationManager.stopUpdatingLocation()
        }
    }
    
    func startTracking() {
        guard authorizationStatus == .authorizedWhenInUse || 
              authorizationStatus == .authorizedAlways else {
            print("⚠️ WalkLocationManager: Location not authorized")
            requestAuthorization()
            return
        }
        
        print("✅ WalkLocationManager: Starting location tracking")
        sessionStartTime = Date()
        routeLocations.removeAll()
        route.removeAll()
        currentDistance = 0
        lastLocation = nil
        isTracking = true
        
        // If not already updating location, start now
        locationManager.startUpdatingLocation()
    }
    
    func stopTracking() {
        print("🛑 WalkLocationManager: Stopping location tracking")
        locationManager.stopUpdatingLocation()
        isTracking = false
        sessionStartTime = nil
    }
    
    func reset() {
        stopTracking()
        routeLocations.removeAll()
        route.removeAll()
        currentDistance = 0
        currentPace = 0
        currentSpeed = 0
        lastLocation = nil
        userLocation = nil
    }
    
    // MARK: - Computed Properties
    
    var totalDistanceMeters: Double {
        currentDistance
    }
    
    var totalDistanceKilometers: Double {
        currentDistance / 1000.0
    }
    
    var paceSecondsPerKm: Double {
        currentPace
    }
    
    var averageSpeed: Double {
        guard let startTime = sessionStartTime else { return 0 }
        let elapsed = Date().timeIntervalSince(startTime)
        guard elapsed > 0 else { return 0 }
        return currentDistance / elapsed
    }
    
    // MARK: - Private Helpers
    
    private func calculateDistance(from: CLLocation, to: CLLocation) -> Double {
        return from.distance(from: to)
    }
    
    private func updatePace(elapsed: TimeInterval) {
        guard elapsed > 0, currentDistance > 0 else {
            currentPace = 0
            return
        }
        
        let distanceKm = currentDistance / 1000.0
        if distanceKm > 0 {
            currentPace = elapsed / distanceKm
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension WalkLocationManager: CLLocationManagerDelegate {
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
            print("📍 WalkLocationManager: Authorization status changed to \(authorizationStatus.rawValue)")
            
            // If we just got authorized, start monitoring location to show current position
            if authorizationStatus == .authorizedWhenInUse || 
               authorizationStatus == .authorizedAlways {
                locationManager.startUpdatingLocation()
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let location = locations.last else { return }
            
            // Filter out inaccurate readings
            guard location.horizontalAccuracy >= 0 && location.horizontalAccuracy <= 50 else {
                print("⚠️ WalkLocationManager: Ignoring inaccurate location (accuracy: \(location.horizontalAccuracy)m)")
                return
            }
            
            // Always update current location so map shows where user is
            userLocation = location.coordinate
            
            // Only track route and calculate metrics when actively tracking a walk
            if isTracking {
                routeLocations.append(location)
                route.append(location.coordinate)
                
                // Calculate distance if we have a previous location
                if let lastLoc = lastLocation {
                    let distance = calculateDistance(from: lastLoc, to: location)
                    
                    // Only add distance if it's reasonable (less than 100m between updates)
                    if distance < 100 {
                        currentDistance += distance
                    }
                    
                    // Calculate speed (meters per second)
                    let timeDiff = location.timestamp.timeIntervalSince(lastLoc.timestamp)
                    if timeDiff > 0 {
                        currentSpeed = distance / timeDiff
                    }
                }
                
                lastLocation = location
                
                // Update pace
                if let startTime = sessionStartTime {
                    let elapsed = Date().timeIntervalSince(startTime)
                    updatePace(elapsed: elapsed)
                }
                
                print("📍 WalkLocationManager: Distance: \(String(format: "%.2f", totalDistanceKilometers))km, Speed: \(String(format: "%.2f", currentSpeed))m/s")
            } else {
                print("📍 WalkLocationManager: Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            print("❌ WalkLocationManager: Location error: \(error.localizedDescription)")
            
            if let clError = error as? CLError {
                switch clError.code {
                case .denied:
                    print("⚠️ WalkLocationManager: Location access denied by user")
                    stopTracking()
                case .locationUnknown:
                    print("⚠️ WalkLocationManager: Location unknown, will retry")
                default:
                    print("⚠️ WalkLocationManager: CLError code: \(clError.code.rawValue)")
                }
            }
        }
    }
}

