import SwiftUI
import Foundation
import Vision
import CoreML

class NutritionLabelDetector {
    // Instance properties
    private let model: yolov5nano
    private let inputSize = CGSize(width: 640, height: 640)
    private let classLabels = ["nutrition_label"] // unique to model
        
    init() throws {
        // Initialize the model using the generated class
        model = try yolov5nano()
    }
    
    // MARK: - Detection Methods
    
    func detect(in image: UIImage) async -> [Detection] {
        do {
            // Resize and letterbox the image to 640x640
            let resizedImage = image.resizedWithLetterboxing(to: self.inputSize)
            
            // Convert CGImage to CVPixelBuffer - necessary for the model input
            guard let pixelBuffer = resizedImage.convertToPixelBuffer() else {
                throw NSError(domain: "NutritionLabelDetector", code: 1,
                             userInfo: [NSLocalizedDescriptionKey: "Failed to prepare image for model"])
            }

            // Run inference and process outputs
            // Can play with iouThreshold and confidenceThreshold to make detection more/less lenient
            let output = try self.model.prediction(image: pixelBuffer, iouThreshold: 0.45, confidenceThreshold: 0.25)
            let processedDetections = self.processDetections(confidence: output.confidence, coordinates: output.coordinates, originalImageSize: image.size)
                                    
            return processedDetections
        } catch {
            print("Detection error: \(error)")
            return []
        }
    }
    
    private func processDetections(confidence: MLMultiArray, coordinates: MLMultiArray, originalImageSize: CGSize) -> [Detection] {
        var detections: [Detection] = []
        
        // Constants for the YOLO output interpretation
        let numBoxes = confidence.shape[0].intValue  // Number of detection boxes
        let numClasses = confidence.shape[1].intValue  // Number of classes
        
        // Confidence threshold - adjust as needed
        let confidenceThreshold: Float = 0.50
        
        // Process each detection box
        for i in 0..<numBoxes {
            var maxConfidence: Float = 0.0
            var classIndex: Int = 0
            
            // Find the class with the highest confidence for this box
            for j in 0..<numClasses {
                let confidenceValue = confidence[[i, j] as [NSNumber]].floatValue
                if confidenceValue > maxConfidence {
                    maxConfidence = confidenceValue
                    classIndex = j
                }
            }
            
            // Skip low confidence detections
            if maxConfidence < confidenceThreshold {
                continue
            }
            
            // Check if the class index is valid
            if classIndex >= 0 && classIndex < classLabels.count {
                // Extract bounding box coordinates (normalized from 0 to 1)
                // coordinates is in [box, [x, y, width, height]] format
                let x = coordinates[[i, 0] as [NSNumber]].floatValue
                let y = coordinates[[i, 1] as [NSNumber]].floatValue
                let width = coordinates[[i, 2] as [NSNumber]].floatValue
                let height = coordinates[[i, 3] as [NSNumber]].floatValue
                
                // Create bounding box in normalized coordinates (0-1)
                let boundingBox = CGRect(
                    x: CGFloat(x - width/2),
                    y: CGFloat(y - height/2),
                    width: CGFloat(width),
                    height: CGFloat(height)
                )
                
                // Create detection object
                let detection = Detection(
                    boundingBox: boundingBox,
                    confidence: Double(maxConfidence),
                    classIndex: classIndex,
                    className: classLabels[classIndex],
                    originalImageSize: originalImageSize
                )
                
                detections.append(detection)
            }
        }
        
        return detections
    }
}

// MARK: - Detection Object

struct Detection: Identifiable {
    let id = UUID()
    let boundingBox: CGRect  // In original image coordinates
    let confidence: Double
    let classIndex: Int
    let className: String
    let minDistanceFromEdges: CGFloat
        
    let color: Color = .blue
    
    // Added init to auto-calculate min distance from edges of original image
    init(boundingBox: CGRect, confidence: Double, classIndex: Int, className: String, originalImageSize: CGSize) {
        self.boundingBox = boundingBox
        self.confidence = confidence
        self.classIndex = classIndex
        self.className = className
        
        // First, convert normalized coordinates to original image coordinates
        let boxInOriginal = CGRect(
            x: boundingBox.minX * originalImageSize.width,
            y: boundingBox.minY * originalImageSize.height,
            width: boundingBox.width * originalImageSize.width,
            height: boundingBox.height * originalImageSize.height
        )
        
        // Calculate distance to each edge
        let distanceToLeft = boxInOriginal.minX
        let distanceToTop = boxInOriginal.minY
        let distanceToRight = originalImageSize.width - boxInOriginal.maxX
        let distanceToBottom = originalImageSize.height - boxInOriginal.maxY
        
        // Find the minimum distance
        self.minDistanceFromEdges = min(distanceToLeft, distanceToTop, distanceToRight, distanceToBottom)
    }
}

// MARK: - UIImage Extension for Preprocessing

extension UIImage {
    // Resizes and letterboxes an image to the specified size while maintaining aspect ratio
    func resizedWithLetterboxing(to targetSize: CGSize) -> UIImage {
        let imageSize = self.size
        
        // Calculate scaling factor to maintain aspect ratio
        let widthRatio = targetSize.width / imageSize.width
        let heightRatio = targetSize.height / imageSize.height
        let scaleFactor = min(widthRatio, heightRatio)
        
        // Calculate new size after scaling
        let scaledWidth = imageSize.width * scaleFactor
        let scaledHeight = imageSize.height * scaleFactor
        
        // Calculate letterboxing padding
        let widthPadding = (targetSize.width - scaledWidth) / 2
        let heightPadding = (targetSize.height - scaledHeight) / 2
        
        // Create new context with target size
        UIGraphicsBeginImageContextWithOptions(targetSize, true, 1.0)
        let context = UIGraphicsGetCurrentContext()!
        
        // Fill the background with black (for letterboxing)
        context.setFillColor(UIColor.black.cgColor)
        context.fill(CGRect(origin: .zero, size: targetSize))
        
        // Draw the scaled image in the center
        self.draw(in: CGRect(
            x: widthPadding,
            y: heightPadding,
            width: scaledWidth,
            height: scaledHeight
        ))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return newImage
    }
}

extension UIImage {
    func convertToPixelBuffer() -> CVPixelBuffer? {
        
        let attributes = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue
        ] as CFDictionary
        
        var pixelBuffer: CVPixelBuffer?
        
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault, Int(self.size.width),
            Int(self.size.height),
            kCVPixelFormatType_32ARGB,
            attributes,
            &pixelBuffer)
        
        guard (status == kCVReturnSuccess) else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        
        let context = CGContext(
            data: pixelData,
            width: Int(self.size.width),
            height: Int(self.size.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!),
            space: rgbColorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        
        context?.translateBy(x: 0, y: self.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context!)
        self.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        UIGraphicsPopContext()
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        return pixelBuffer
    }
}
