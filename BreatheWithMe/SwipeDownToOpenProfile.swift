//
//  SwipeDownToOpenProfile.swift
//  BreatheWithMe
//
//  Adds a reusable swipe-down gesture to trigger an action (open Profile).
//

import SwiftUI

struct SwipeDownToOpenProfile: ViewModifier {
    let threshold: CGFloat = 100
    let horizontalTolerance: CGFloat = 80
    let onTrigger: () -> Void

    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .simultaneousGesture(
                DragGesture(minimumDistance: 20, coordinateSpace: .local)
                    .onEnded { value in
                        let t = value.translation
                        if t.height > threshold && abs(t.width) < horizontalTolerance {
                            onTrigger()
                        }
                    }
            )
    }
}

extension View {
    func swipeDownToOpenProfile(_ action: @escaping () -> Void) -> some View {
        modifier(SwipeDownToOpenProfile(onTrigger: action))
    }
}


