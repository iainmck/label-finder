//
//  ErrorBannerView.swift
//  Label Detector iOS
//
//  Created by Iain McKenzie on 2025-03-16.
//

import SwiftUI

struct ErrorBannerView: View {
    let message: String
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.yellow)
                
                Text(message)
                    .font(.callout)
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding()
            .background(Color.red.opacity(0.8))
        }
    }
}

#Preview {
    ErrorBannerView(message: "There was an issue")
}
