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
                    // Glow effect background
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.804, green: 0.447, blue: 0.659).opacity(0.4),
                                    Color(red: 0.804, green: 0.447, blue: 0.659).opacity(0.1)
                                ]),
                                center: .center,
                                startRadius: 25,
                                endRadius: 45
                            )
                        )
                        .frame(width: 70, height: 70)
                        .opacity(isExpanded ? 0 : 1)
                    
                    // Main Button
                    Image(systemName: isExpanded ? "xmark" : "plus")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 64, height: 64)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.263, green: 0.086, blue: 0.192),
                                    Color(red: 0.804, green: 0.447, blue: 0.659)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                        .shadow(color: Color(red: 0.804, green: 0.447, blue: 0.659).opacity(0.5), radius: 12, x: 0, y: 6)
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                        .rotationEffect(.degrees(rotationAngle))
                }
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
            print("✅ Button tapped: \(label)")
            action()
        }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 54, height: 54)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.263, green: 0.086, blue: 0.192),
                                Color(red: 0.804, green: 0.447, blue: 0.659)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
                    .shadow(color: Color(red: 0.804, green: 0.447, blue: 0.659).opacity(0.4), radius: 10, x: 0, y: 5)
                
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.primary)
            }
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .offset(offset)
        .opacity(isVisible ? 1 : 0)
        .scaleEffect(isVisible ? 1 : 0.1)
    }
}
