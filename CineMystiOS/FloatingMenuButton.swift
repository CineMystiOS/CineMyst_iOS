//  FloatingMenuButton.swift
//  CineMystApp
//
//  Updated to integrate with PostComposerViewController
//


import SwiftUI
import UIKit

struct FloatingMenuButton: View {
    
    // MARK: - Public Action Closures
    var didTapCamera: (() -> Void)?
    var didTapGallery: (() -> Void)?
    
    @State private var isExpanded = false
    @State private var buttonScale: CGFloat = 1.0
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Camera Button (Top, 45°)
            if isExpanded {
                MenuActionButton(
                    icon: "camera.fill",
                    label: "Camera",
                    isVisible: isExpanded,
                    offset: calculateOffset(angle: 45, radius: 120)
                ) {
                    collapseAndExecute(didTapCamera)
                }
                .transition(.scale.combined(with: .opacity))
            }
            
            // Gallery Button (Top-Left, 90°)
            if isExpanded {
                MenuActionButton(
                    icon: "photo.on.rectangle",
                    label: "Gallery",
                    isVisible: isExpanded,
                    offset: calculateOffset(angle: 90, radius: 110)
                ) {
                    collapseAndExecute(didTapGallery)
                }
                .transition(.scale.combined(with: .opacity))
            }
            
            // Main Plus/X Button with Enhanced Aesthetics
            Button(action: {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
                    isExpanded.toggle()
                    buttonScale = isExpanded ? 1.1 : 1.0
                    rotationAngle = isExpanded ? 45 : 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
                        buttonScale = 1.0
                    }
                }
            }) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.33, green: 0.10, blue: 0.20).opacity(0.22))
                        .frame(width: 78, height: 78)
                        .blur(radius: 12)

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.38, green: 0.11, blue: 0.22),
                                    Color(red: 0.27, green: 0.08, blue: 0.17)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.22), lineWidth: 1.1)
                        )
                        .frame(width: 64, height: 64)

                    Image(systemName: isExpanded ? "xmark" : "plus")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(rotationAngle))
                }
                .shadow(color: Color(red: 0.25, green: 0.07, blue: 0.15).opacity(0.35), radius: 18, x: 0, y: 12)
            }
            .scaleEffect(buttonScale)
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
    }
    
    // MARK: - Helper Methods
    private func calculateOffset(angle: Double, radius: Double) -> CGSize {
        let radians = angle * .pi / 180
        return CGSize(
            width: -cos(radians) * radius,
            height: -sin(radians) * radius
        )
    }
    
    private func collapseAndExecute(_ action: (() -> Void)?) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isExpanded = false
            rotationAngle = 0
            buttonScale = 1.0
        }
        print("🎬 Menu item tapped, executing action...")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            print("🎬 Calling action closure...")
            action?()
        }
    }
}

// MARK: - Menu Action Button
struct MenuActionButton: View {
    let icon: String
    let label: String
    let isVisible: Bool
    let offset: CGSize
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            action()
        }) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.39, green: 0.12, blue: 0.23),
                                    Color(red: 0.29, green: 0.09, blue: 0.18)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.22), lineWidth: 1.1)
                        )
                        .frame(width: 56, height: 56)
                    Image(systemName: icon)
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundColor(.white)
                }
                .shadow(color: Color(red: 0.25, green: 0.07, blue: 0.15).opacity(0.28), radius: 16, x: 0, y: 10)
                
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(red: 0.30, green: 0.12, blue: 0.21))
            }
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .offset(offset)
        .opacity(isVisible ? 1 : 0)
        .scaleEffect(isVisible ? 1 : 0.1)
    }
}
