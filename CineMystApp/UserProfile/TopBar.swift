//
//  TopBar.swift
//  testify_Cinemyst
//
//  Created by user@50 on 30/10/25.
//


import SwiftUI

struct TopBarView: View {
    var body: some View {
        HStack {
            Button(action: {}) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.primary)
            }
            Spacer()
            Image(systemName: "ellipsis")
                .font(.title3)
                .rotationEffect(.degrees(90))
                .foregroundColor(.primary)
        }
        .padding(.horizontal)
        .padding(.top, UIApplication.shared.windows.first?.safeAreaInsets.top ?? 20)
        .background(Color(.systemBackground).opacity(0.95))
    }
}

#Preview {
    TopBarView()
}
