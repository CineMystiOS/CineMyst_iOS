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
            
            // Main Plus/X Button
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            }) {
                Image(systemName: isExpanded ? "xmark" : "plus")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(isExpanded ? .accentColor : .white)
                    .frame(width: 60, height: 60)
                    .background(
                        LinearGradient(
                            colors: isExpanded
                            ? [Color(.systemGray5)]
                                : [Color.accentColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
            }
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
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(
                        LinearGradient(
                            colors: [Color.accentColor.opacity(0.8), Color.accentColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
                
                Text(label)
                    .font(.system(size: 11, weight: .medium))
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
