import SwiftUI
import Foundation
import Vision
import CoreML

class NutritionLabelDetector {
    // Instance properties
    private let model: yolov5nano
    private let inputSize = CGSize(width: 640, height: 640)
    private let classLabels = ["nutrition_label"] // unique to model
        
    init() async throws {
        model = try await yolov5nano.load()
    }
        
    func detect(in image: UIImage) async -> [Detection] {
        do {
            // Resize and letterbox the image to what the model is trained on
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
