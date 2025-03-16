//
//  BoundingBoxView.swift
//  Label Detector iOS
//
//  Created by Iain McKenzie on 2025-03-15.
//

import SwiftUI

struct BoundingBoxView: View {
    let detection: Detection
    
    var body: some View {
        GeometryReader { geometry in
            let rect = scaledRect(for: geometry.size)
            
            ZStack(alignment: .topLeading) {
                Rectangle()
                    .stroke(detection.color, lineWidth: 2)
                    .background(detection.color.opacity(0.1))
                
                Text("\(Int(detection.confidence * 100))%")
                    .font(.caption)
                    .padding(2)
                    .background(detection.color)
                    .foregroundColor(.white)
                    .offset(y: -20)
            }
            .position(x: rect.midX, y: rect.midY)
            .frame(width: rect.width, height: rect.height)
        }
    }
    
    private func scaledRect(for viewSize: CGSize) -> CGRect {
        return CGRect(
            x: detection.boundingBox.origin.x * viewSize.width,
            y: detection.boundingBox.origin.y * viewSize.height,
            width: detection.boundingBox.width * viewSize.width,
            height: detection.boundingBox.height * viewSize.height
        )
    }
}

#Preview {
    BoundingBoxView(detection: Detection(boundingBox: CGRect(x: 0.5, y: 0.25, width: 0.5, height: 0.25), confidence: 0.55, classIndex: 0, className: "label", originalImageSize: CGSize(width: 420, height: 230)))
}
