//
//  GalleryGrid.swift
//  testify_Cinemyst
//
//  Created by user@50 on 30/10/25.
//

import SwiftUI

struct GalleryGridView: View {
let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

var body: some View {
    LazyVGrid(columns: columns, spacing: 6) {
        ForEach(1..<7) { index in
            Image("img\(index)") // Add images named img1, img2, etc. to Assets
                .resizable()
                .scaledToFill()
                .frame(height: 120)
                .clipped()
                .cornerRadius(8)
        }
    }
    .padding()
}


}
