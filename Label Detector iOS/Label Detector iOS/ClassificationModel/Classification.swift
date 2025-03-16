struct Classification {
    let label: String
    let confidence: Float
    let allProbabilities: [String: Double]
    
    init(label: String, confidence: Float, allProbabilities: [String: Double] = [:]) {
        self.label = label
        self.confidence = confidence
        self.allProbabilities = allProbabilities
    }
}
