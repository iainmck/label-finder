import SwiftUI

class ContentViewController: ObservableObject {
    @Published var image: UIImage?
    @Published var initializationError: String?
    
    private var detector: NutritionLabelDetector?
    @Published var detections: [Detection] = []
    
    private var classifier: NutritionLabelClassifier?
    @Published var classification: Classification? = nil
    
    private var ocr = NutritionLabelOCR() // has simple init
    @Published var textRecognition: TextRecognition? = nil
    
    init() {
        Task { await initializeDetector() }
        Task { await initializeClassifier() }
    }
    
    private func initializeDetector() async {
        do {
            detector = try await NutritionLabelDetector()
            print("NutritionLabelDetector initialized")
        } catch {
            let errorMessage = "Failed to initialize YOLO detector: \(error.localizedDescription)"
            print("⚠️ \(errorMessage)")
            Task { @MainActor in initializationError = errorMessage }
        }
    }
    
    private func initializeClassifier() async {
        do {
            classifier = try await NutritionLabelClassifier()
            print("NutritionLabelClassifier initialized")
        } catch {
            let errorMessage = "Failed to initialize YOLO detector: \(error.localizedDescription)"
            print("⚠️ \(errorMessage)")
            Task { @MainActor in initializationError = errorMessage }
        }
    }
    
    func runVisionModels() {
        guard let image = image else { return }
        
        if let detector = detector {
            Task {
                let _detections = await detector.detect(in: image)
                Task { @MainActor in self.detections = _detections }
            }
        }
        
        if let classifier = classifier {
            Task {
                let _classification = await classifier.classify(image: image)
                Task { @MainActor in self.classification = _classification }
            }
        }
        
        Task {
            let _textRecognition = await ocr.recognizeText(from: image)
            Task { @MainActor in self.textRecognition = _textRecognition }
        }
    }
}
