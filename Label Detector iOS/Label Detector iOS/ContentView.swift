//
//  ContentView.swift
//  Label Detector iOS
//
//  Created by Iain McKenzie on 2025-03-15.
//

import SwiftUI
import PhotosUI

struct ContentView: View {
    @StateObject private var controller = ContentViewController()
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var showCamera = false
    
    var body: some View {
        VStack {
            // Show error banner if initialization failed
            if let errorMessage = controller.initializationError {
                ErrorBannerView(message: errorMessage)
            }
            
            if let image = controller.image {
                // Main content with image and detections
                ZStack {
                    Image(uiImage: image.resizedWithLetterboxing(to: .init(width: 640, height: 640)))
                        .resizable()
                        .scaledToFit()
                        .overlay(
                            ZStack {
                                // Overlay detection bounding boxes only if detector is available
                                ForEach(controller.detections) { detection in
                                    BoundingBoxView(detection: detection)
                                }
                            }
                        )
                }
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Detector Model").font(.title3).bold().frame(maxWidth: .infinity, alignment: .leading)
                        
                        if controller.detections.isEmpty {
                            Text("No nutrition label detected")
                        } else {
                            VStack(alignment: .leading) {
                                ForEach(controller.detections) { detection in
                                    HStack(alignment: .top) {
                                        Circle().fill(detection.color).frame(width: 12, height: 12).offset(y: 5)
                                        VStack(alignment: .leading) {
                                            Text("\(detection.className): \(Int(detection.confidence * 100))%").font(.callout)
                                            Text("Distance from edge: \(Int(detection.minDistanceFromEdges * 100))%").font(.caption)
                                            Text("Area covered: \(Int(detection.areaCovered * 100))%").font(.caption)
                                        }
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        Text("Classifier Model").font(.title3).bold().frame(maxWidth: .infinity, alignment: .leading).padding(.top, 15)
                        
                        if let classification = controller.classification {
                            HStack(alignment: .top) {
                                Circle().fill(classification.label == "has_label" ? .green : .red).frame(width: 12, height: 12).offset(y: 5)
                                VStack(alignment: .leading) {
                                    Text("\(classification.label): \(Int(classification.confidence * 100))%").font(.callout)
                                    HStack(spacing: 10) {
                                        ForEach(Array(classification.allProbabilities), id: \.key) { key, value in
                                            Text("\(key): \(Int(value * 100))%").font(.caption).opacity(0.5)
                                        }
                                    }
                                }
                            }
                            
                        } else {
                            Text("No nutrition label detected")
                        }
                        
                        Text("OCR").font(.title3).bold().frame(maxWidth: .infinity, alignment: .leading).padding(.top, 15)
                        
                        if let textRecognition = controller.textRecognition {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 5)], alignment: .leading, spacing: 5) {
                                ForEach(Array(textRecognition.containsKeyFacts), id: \.key) { key, value in
                                    HStack {
                                        Circle().fill(value ? .green : .red).frame(width: 8, height: 8)
                                        Text(key).font(.caption)
                                    }
                                    .fixedSize(horizontal: true, vertical: false)
                                }
                            }
                            
                            Text(textRecognition.text).font(.caption).opacity(0.5).multilineTextAlignment(.leading)
                        } else {
                            Text("No nutrition label detected")
                        }
                    }
                }
                .padding(.horizontal)
            } else {
                // Placeholder when no image is selected
                ContentUnavailableView(
                    "No Image Selected",
                    systemImage: "photo.badge.plus",
                    description: Text("Select a nutrition label below")
                )
            }
            
            Spacer()
            
            // Options to add photo
            HStack {
                PhotosPicker(selection: $photosPickerItem, matching: .images) {
                    ButtonText(text: "Gallery")
                }
                .onChange(of: photosPickerItem) {
                    Task {
                        if let data = try? await photosPickerItem?.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                            Task { @MainActor in
                                controller.image = uiImage
                                controller.runVisionModels()
                            }
                        }
                        photosPickerItem = nil
                    }
                }
                
                Button { showCamera = true } label: {
                    ButtonText(text: "Camera")
                }
                .sheet(isPresented: $showCamera) {
                    ImagePickerCamera(selectedImage: { image in
                        if let image = image {
                            controller.image = image
                            controller.runVisionModels()
                        }
                    })
                }
            }
            .padding(.vertical)
        }
    }
}

#Preview {
    ContentView()
}

struct ButtonText: View {
    let text: String
    
    var body: some View {
        Text(text)
            .foregroundColor(.black)
            .padding()
            .background(Color.yellow)
            .cornerRadius(10)
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
    }
}
