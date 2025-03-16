import SwiftUI
import Foundation
import Vision
import CoreML

class NutritionLabelDetector: ObservableObject {
    // Instance properties
    private let model: MLModel
    private let visionModel: VNCoreMLModel
    private let inputSize = CGSize(width: 640, height: 640)
    
    // Published properties for SwiftUI
    @Published var detections: [Detection] = []
    @Published var isProcessing = false
    
    // Classes that the model will detect
    private let classLabels = ["label"]
    
    // MARK: - Initialization
    
    init() throws {
        // Load the ML model - replace "YOLOv5s" with your actual model name
        let modelURL = Bundle.main.url(forResource: "yolov5nano", withExtension: "mlpackage")!
        model = try MLModel(contentsOf: modelURL)
        visionModel = try VNCoreMLModel(for: model)
    }
    
    // MARK: - Public Methods
    
    func detect(in image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        
        isProcessing = true
        
        // Preprocess the image (resize with letterboxing)
        let resizedImage = image.resizedWithLetterboxing(to: inputSize)
        
        // Create Vision request
        let request = VNCoreMLRequest(model: visionModel) { [weak self] request, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Vision request error: \(error)")
                DispatchQueue.main.async {
                    self.detections = []
                    self.isProcessing = false
                }
                return
            }
            
            // Process results
            let detections = self.processDetections(for: request, originalImage: image)
            
            DispatchQueue.main.async {
                self.detections = detections
                self.isProcessing = false
            }
        }
        
        // Configure the request
        request.imageCropAndScaleOption = .scaleFill
        
        // Perform the request
        let handler = VNImageRequestHandler(cgImage: resizedImage.cgImage!, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }
    
    // MARK: - Helper Methods
    
    private func processDetections(for request: VNRequest, originalImage: UIImage) -> [Detection] {
        // Get the results
        guard let results = request.results as? [VNCoreMLFeatureValueObservation],
              results.count >= 2 else {
            return []
        }
        
        // Get confidence and coordinates feature values
        let confidenceFeatureValue = results[0].featureValue
        let coordinatesFeatureValue = results[1].featureValue
        
        // Extract the MLMultiArrays
        guard let confidences = confidenceFeatureValue.multiArrayValue,
              let coordinates = coordinatesFeatureValue.multiArrayValue else {
            return []
        }
        
        // Convert results to Detection objects
        var detections: [Detection] = []
        
        // Original image dimensions
        let imageWidth = originalImage.size.width
        let imageHeight = originalImage.size.height
        
        // Get scaling factors for converting normalized coordinates to image coordinates
        let scaleTransform = getScaleTransform(
            from: inputSize,
            to: originalImage.size
        )
        
        // Number of detections
        let numDetections = coordinates.shape[1].intValue
        let numClasses = confidences.shape[2].intValue
        
        // Threshold for detection confidence
        let confidenceThreshold: Float = 0.25
        
        // Process detections
        for i in 0..<numDetections {
            // Find the class with highest confidence
            var maxConfidence: Float = 0
            var maxClassIndex: Int = 0
            
            for c in 0..<numClasses {
                let confidence = confidences[[0, i, c] as [NSNumber]].floatValue
                if confidence > maxConfidence {
                    maxConfidence = confidence
                    maxClassIndex = c
                }
            }
            
            // Skip low confidence detections
            if maxConfidence < confidenceThreshold {
                continue
            }
            
            // Get bounding box coordinates (normalized from 0 to 1)
            let x = coordinates[[0, i, 0] as [NSNumber]].floatValue
            let y = coordinates[[0, i, 1] as [NSNumber]].floatValue
            let width = coordinates[[0, i, 2] as [NSNumber]].floatValue
            let height = coordinates[[0, i, 3] as [NSNumber]].floatValue
            
            // Convert normalized coordinates to image coordinates with correct scaling
            let boundingBox = CGRect(
                x: CGFloat(x) - CGFloat(width) / 2,
                y: CGFloat(y) - CGFloat(height) / 2,
                width: CGFloat(width),
                height: CGFloat(height)
            )
            
            // Apply the letterbox transformation to get coordinates on the original image
            let transformedBox = apply(scaleTransform: scaleTransform, to: boundingBox, imageSize: originalImage.size)
            
            // Create detection object
            let className = maxClassIndex < classLabels.count ? classLabels[maxClassIndex] : "unknown"
            let detection = Detection(
                boundingBox: transformedBox,
                confidence: Double(maxConfidence),
                classIndex: maxClassIndex,
                className: className,
                color: .blue
            )
            
            detections.append(detection)
        }
        
        return detections
    }
    
    private func getScaleTransform(from inputSize: CGSize, to outputSize: CGSize) -> CGAffineTransform {
        // Calculate the scale factor while preserving aspect ratio
        let widthRatio = outputSize.width / inputSize.width
        let heightRatio = outputSize.height / inputSize.height
        let scale = min(widthRatio, heightRatio)
        
        // Calculate letterboxing offsets
        let offsetX = (outputSize.width - inputSize.width * scale) / 2
        let offsetY = (outputSize.height - inputSize.height * scale) / 2
        
        // Create transformation
        var transform = CGAffineTransform.identity
        transform = transform.translatedBy(x: offsetX / scale, y: offsetY / scale)
        transform = transform.scaledBy(x: 1/scale, y: 1/scale)
        
        return transform
    }
    
    private func apply(scaleTransform: CGAffineTransform, to rect: CGRect, imageSize: CGSize) -> CGRect {
        // Transform the rectangle
        let transformedRect = rect.applying(scaleTransform)
        
        // Ensure the rectangle is within the image bounds
        return transformedRect.intersection(CGRect(origin: .zero, size: imageSize))
    }
}

// MARK: - Detection Object

struct Detection: Identifiable {
    let id = UUID()
    let boundingBox: CGRect  // In original image coordinates
    let confidence: Double
    let classIndex: Int
    let className: String
    let color: Color
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
