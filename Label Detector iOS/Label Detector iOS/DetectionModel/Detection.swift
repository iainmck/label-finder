import Foundation
import SwiftUI

struct Detection: Identifiable {
    let id = UUID()
    let boundingBox: CGRect  // In normalized coordinates (0-1)
    let confidence: Double
    let classIndex: Int
    let className: String
    
    // Computed at initialization
    let minDistanceFromEdges: CGFloat // 0-1
    let areaCovered: CGFloat // 0-1
 
    // Fixed (for now)
    let color: Color = .blue
    
    init(boundingBox: CGRect, confidence: Double, classIndex: Int, className: String, originalImageSize: CGSize) {
        self.boundingBox = boundingBox
        self.confidence = confidence
        self.classIndex = classIndex
        self.className = className
        
        // COMPUTED FIELDS BELOW
        
        // For rectangular images, we need to scale the normalized coordinates correctly
        // Calculate the scaling factors to convert from the letterboxed square back to original aspect ratio
        let widthRatio = originalImageSize.width / originalImageSize.height
        let heightRatio = originalImageSize.height / originalImageSize.width
                
        // Convert bounding box from letterboxed normalized coords to original image normalized coords
        let originalBoundingBox: CGRect
        if heightRatio < 1 {
            // Letterboxing on top/bottom
            originalBoundingBox = CGRect(x: 0, y: (1 - heightRatio) / 2, width: 1, height: heightRatio)
        } else {
            // Letterboxing on left/right
            originalBoundingBox = CGRect(x: (1 - widthRatio) / 2, y: 0, width: widthRatio, height: 1)
        }
                
        // Now calculate the percentage distance to each edge of the original image
        let distanceToLeft = max(0, boundingBox.minX - originalBoundingBox.minX)
        let distanceToTop = max(0, boundingBox.minY - originalBoundingBox.minY)
        let distanceToRight = max(0, originalBoundingBox.maxX - boundingBox.maxX)
        let distanceToBottom = max(0, originalBoundingBox.maxY - boundingBox.maxY)
        
        // Find the minimum percentage distance
        self.minDistanceFromEdges = min(distanceToLeft, distanceToTop, distanceToRight, distanceToBottom)
        
        // --- now do area covered
        self.areaCovered = boundingBox.width * boundingBox.height / (originalBoundingBox.width * originalBoundingBox.height)
    }
}
