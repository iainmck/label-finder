import UIKit
import CoreML
import Vision
class NutritionLabelClassifier {
    private let model: NutritionLabelClassifier_ctrl
    private let inputSize = CGSize(width: 360, height: 360) // MAKE SURE SIZE MATCHES MODEL CLASS
    
    init() async throws {
        model = try await NutritionLabelClassifier_ctrl.load()
    }
    
    func classify(image: UIImage) async -> Classification? {
        do {
            // Resize and letterbox the image to what the model is trained on
            let resizedImage = image.resizedByStretching(to: self.inputSize)
            
            // Convert CGImage to CVPixelBuffer - necessary for the model input
            guard let pixelBuffer = resizedImage.convertToPixelBuffer() else {
                throw NSError(domain: "NutritionLabelClassifier", code: 1,
                             userInfo: [NSLocalizedDescriptionKey: "Failed to prepare image for model"])
            }

            // Run inference and process outputs
            let output = try await model.prediction(input: NutritionLabelClassifier_ctrlInput(image: pixelBuffer))
            
            // Get the top prediction
            let classification = Classification(
                label: output.target,
                confidence: Float(output.targetProbability[output.target] ?? 0.0),
                allProbabilities: output.targetProbability
            )
            
            return classification
        } catch {
            print("Classification error: \(error)")
            return nil
        }
    }
}
