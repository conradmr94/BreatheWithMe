//
//  TopSlideCover.swift
//  BreatheWithMe
//

import SwiftUI

struct TopSlideCover<OverlayContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let overlayContent: () -> OverlayContent

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                ZStack(alignment: .top) {
                    // Dim backdrop fades in/out and only captures taps when visible
                    Color.black
                        .opacity(isPresented ? 0.35 : 0)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                                isPresented = false
                            }
                        }
                        .allowsHitTesting(isPresented)
                        .animation(.easeInOut(duration: 0.25), value: isPresented)

                    // Content slides from offscreen-top using offset
                    overlayContent()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .offset(y: isPresented ? 0 : -UIScreen.main.bounds.height)
                        .animation(.spring(response: 0.4, dampingFraction: 0.9), value: isPresented)
                }
                .zIndex(1000)
                .allowsHitTesting(isPresented)
            }
    }
}

extension View {
    func topSlideCover<OverlayContent: View>(isPresented: Binding<Bool>, @ViewBuilder content: @escaping () -> OverlayContent) -> some View {
        modifier(TopSlideCover(isPresented: isPresented, overlayContent: content))
    }
}


