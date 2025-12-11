//
//  PhoneActivityMonitor.swift
//  BreatheWithMe
//
//  Monitor phone interactions during sleep sessions
//

import Foundation
import UIKit

@MainActor
class PhoneActivityMonitor: ObservableObject {
    @Published var interactionCount: Int = 0
    private var isMonitoring = false
    private var notificationObservers: [NSObjectProtocol] = []
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        interactionCount = 0
        setupNotifications()
    }
    
    func stopMonitoring() {
        guard isMonitoring else { return }
        isMonitoring = false
        removeNotifications()
    }
    
    private func setupNotifications() {
        let center = NotificationCenter.default
        
        // Track when app becomes active (phone was picked up/unlocked)
        let activeObserver = center.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self, self.isMonitoring else { return }
            self.interactionCount += 1
        }
        
        notificationObservers.append(activeObserver)
    }
    
    private func removeNotifications() {
        for observer in notificationObservers {
            NotificationCenter.default.removeObserver(observer)
        }
        notificationObservers.removeAll()
    }
}

