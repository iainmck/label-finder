//
//  TextRecognition.swift
//  Label Detector iOS
//
//  Created by Iain McKenzie on 2025-03-16.
//

import Foundation

struct TextRecognition {
    let text: String
    let containsKeyFacts: [String: Bool] // computed
    
    init(text: String, langauges _languages: [String]?=nil) {
        // lowercase everything and remove accents
        var normalizedText = text.lowercased().folding(options: .diacriticInsensitive, locale: Locale(identifier: "en_US_POSIX"))
        
        // add space at end so we can do "[word] " checks and not match on substrings
        normalizedText += " "
        
        self.text = normalizedText
        
        // Process text and look for known fields
        // LIMITATION: OCR will detect any language but only Canadian English and French are hardcoded in logic below right now)
        var CKF: [String: Bool] = [:]
        
        // Nutrition title
        CKF["title"] = ["nutrit"].contains { normalizedText.contains($0) }
        
        // Serving Size
        CKF["serving"] = ["serving", "per ", "pour ", "amount", "teneur"].contains { normalizedText.contains($0) }
        
        // Calories
        CKF["calories"] = ["calorie", "energy"].contains { normalizedText.contains($0) }
        
        // Fat
        CKF["fat"] = ["fat", "lipid"].contains { normalizedText.contains($0) }
        
        // Carbs
        CKF["carbs"] = ["carb", "gluc"].contains { normalizedText.contains($0) }
        
        // Sugar
        CKF["sugar"] = ["sugar", "sucre"].contains { normalizedText.contains($0) }
        
        // Protein
        CKF["protein"] = ["protein"].contains { normalizedText.contains($0) }
        
        // Sodium
        CKF["sodium"] = ["sodium"].contains { normalizedText.contains($0) }
        
        self.containsKeyFacts = CKF
    }
}
