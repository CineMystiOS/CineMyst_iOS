//
//  ProfileHeader.swift
//  testify_Cinemyst
//
//  Created by user@50 on 30/10/25.
//
import SwiftUI

struct ProfileHeaderView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image("profile_pic")
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.green, lineWidth: 3))
                .shadow(radius: 5)
            
            Text("Kristen")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("@Kristin_kaif234 · Professional Actor")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("1.2K")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            Text("Connections")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            HStack(spacing: 20) {
                Button("Edit Profile") {}
                    .buttonStyle(.borderedProminent)
                    .tint(Color.purple)
                
                Button("Edit Portfolio") {}
                    .buttonStyle(.borderedProminent)
                    .tint(Color.purple.opacity(0.8))
            }
            .padding(.top, 4)
        }
        .padding()
    }
}

#Preview {
    ProfileHeaderView()
}
