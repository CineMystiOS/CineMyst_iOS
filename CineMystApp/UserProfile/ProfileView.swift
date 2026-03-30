//
// ProfileView.swift
// testify_Cinemyst
//
// Created by user@50 on 30/10/25.
//

import SwiftUI

struct ProfileView: View {
@State private var selectedTab = "Gallery"
let tabs = ["Gallery", "Flicks", "Tagged"]

var body: some View {
    ZStack {
        // Full background color
        Color(.systemBackground)
            .ignoresSafeArea()
        
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                
                // MARK: - Top Bar
                TopBarView()
                    .padding(.top, 8)
                
                // MARK: - Profile Card Section
                ZStack(alignment: .top) {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
                        .frame(height: 220)
                        .padding(.horizontal)
                        .padding(.top, 60)
                    
                    VStack(spacing: 8) {
                        // Profile Image
                        Image("profile_pic")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 110, height: 110)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.green, lineWidth: 3))
                            .overlay(alignment: .bottomTrailing) {
                                ZStack {
                                    Circle().fill(Color.blue)
                                        .frame(width: 30, height: 30)
                                    Image(systemName: "plus")
                                        .foregroundColor(.white)
                                        .font(.system(size: 16, weight: .bold))
                                }
                            }
                            .shadow(radius: 5)
                        
                        // Name + Handle
                        Text("Kristen")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Text("@Kristin_kaif234 · Professional Actor")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        // Connections
                        Text("1.2K Connections")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .padding(.top, 2)
                        
                        // MARK: - Gradient Buttons
                        HStack(spacing: 20) {
                            // Edit Profile Button
                            Button(action: {}) {
                                Text("Edit Profile")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 24)
                                    .frame(maxWidth: .infinity)
                            }
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(hex: "#8129A3"),
                                        Color(hex: "#290A13")
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(color: Color.purple.opacity(0.3), radius: 5, x: 0, y: 3)
                            
                            // Edit Portfolio Button
                            Button(action: {}) {
                                Text("Edit Portfolio")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 24)
                                    .frame(maxWidth: .infinity)
                            }
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(hex: "#8129A3"),
                                        Color(hex: "#290A13")
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(color: Color.purple.opacity(0.3), radius: 5, x: 0, y: 3)
                        }
                        .padding(.top, 8)
                        .padding(.horizontal)
                    }
                    .padding(.top, 20)
                }
                .padding(.top, 10)
                
                // MARK: - About Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("About")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("Professional actor with 10+ years of experience in theater, film, and television. Passionate about storytelling and bringing characters to life.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Label("Mumbai, India", systemImage: "mappin.and.ellipse")
                        Spacer()
                        Label("10+ years", systemImage: "briefcase.fill")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // MARK: - Tabs
                HStack {
                    ForEach(tabs, id: \.self) { tab in
                        VStack {
                            Text(tab)
                                .fontWeight(selectedTab == tab ? .semibold : .regular)
                                .foregroundColor(selectedTab == tab ? .primary : .gray)
                            Capsule()
                                .fill(selectedTab == tab ? Color.purple : Color.clear)
                                .frame(height: 3)
                        }
                        .onTapGesture { selectedTab = tab }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // MARK: - Gallery Grid
                if selectedTab == "Gallery" {
                    GalleryGridView()
                } else {
                    Text("Coming soon...")
                        .foregroundColor(.gray)
                        .padding()
                }
            }
            .padding(.bottom, 20)
        }
    }
}


}

#Preview {
ProfileView()
}
