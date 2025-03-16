//
//  NutritionLabelOCR.swift
//  Label Detector iOS
//
//  Created by Iain McKenzie on 2025-03-16.
//

import Foundation
import Vision
import UIKit

class NutritionLabelOCR {
    // Configuration properties
    private var recognitionLanguages: [String]
    private var recognitionLevel: VNRequestTextRecognitionLevel
    private var customWords: [String]?
    private var minimumTextHeight: Float?
    
    /**
    - languages: Array of language codes for recognition (e.g., ["en-US", "fr-FR"]). Defaults to system language.
    - recognitionLevel: The level of recognition accuracy vs. speed. Defaults to .accurate.
    - customWords: Optional array of custom words to improve recognition of domain-specific terms.
    - minimumTextHeight: Optional minimum height of text as a fraction of the image height (0.0 to 1.0).
     */
    init(languages: [String]? = nil,
         recognitionLevel: VNRequestTextRecognitionLevel = .accurate,
         customWords: [String]? = nil,
         minimumTextHeight: Float? = nil) {
        self.recognitionLanguages = languages ?? Locale.preferredLanguages
        self.recognitionLevel = recognitionLevel
        self.customWords = customWords
        self.minimumTextHeight = minimumTextHeight
    }
    
    func recognizeText(from image: UIImage) async -> TextRecognition? {
        do {
            guard let cgImage = image.cgImage else {
                throw OCRError.invalidImage
            }
            
            // Create request handler
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            // Create and configure request
            let request = configureTextRecognitionRequest()
            
            // Perform the request
            try handler.perform([request])
            
            // Process results
            guard let observations = request.results else {
                throw OCRError.noResult
            }
            
            // Extract text
            let recognizedText = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: " ")
            
            return TextRecognition(text: recognizedText)
        } catch {
            print("OCR error: \(error)")
            return nil
        }
    }
    
    // MARK: - Helpers
    
    private func configureTextRecognitionRequest() -> VNRecognizeTextRequest {
        let request = VNRecognizeTextRequest()
        
        // Configure request
        request.recognitionLanguages = self.recognitionLanguages
        request.recognitionLevel = self.recognitionLevel
        request.usesLanguageCorrection = true
        
        if let customWords = self.customWords {
            request.customWords = customWords
        }
        
        if let minimumTextHeight = self.minimumTextHeight {
            request.minimumTextHeight = minimumTextHeight
        }
        
        // Use iOS 17 improvements
        request.automaticallyDetectsLanguage = true
        request.revision = VNRecognizeTextRequestRevision3
        
        return request
    }
    
    enum OCRError: Error, LocalizedError {
        case invalidImage
        case noResult
        case processingFailed(String)
        
        var errorDescription: String? {
            switch self {
            case .invalidImage:
                return "The provided image is invalid or corrupted"
            case .noResult:
                return "No text was detected in the image"
            case .processingFailed(let message):
                return "Text recognition failed: \(message)"
            }
        }
    }
}
