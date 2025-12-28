//
//  OCRTests.swift
//  ViewLingo-CamTests
//
//  OCR functionality tests
//

import XCTest
import UIKit
import Vision
@testable import ViewLingo_Cam

@available(iOS 18.0, *)
final class OCRTests: XCTestCase {
    
    var ocrService: OCRService!
    
    override func setUp() async throws {
        try await super.setUp()
        await MainActor.run {
            ocrService = OCRService()
        }
    }
    
    override func tearDown() async throws {
        await MainActor.run {
            ocrService = nil
        }
        try await super.tearDown()
    }
    
    // MARK: - OCR Basic Tests
    
    func testOCRInitialization() async throws {
        await MainActor.run {
            XCTAssertNotNil(ocrService, "OCR Service should be initialized")
            // OCRService doesn't expose supportedLanguages directly
            // XCTAssertFalse(ocrService.supportedLanguages.isEmpty, 
            //               "Should have supported languages")
            XCTAssertTrue(ocrService.recognizedTexts.isEmpty, 
                         "Should start with no detected texts")
        }
    }
    
    func testProcessTestImage() async throws {
        // Create a test image with text
        let testImage = createTestImage(with: "Hello World")
        
        // Process the image
        await ocrService.processImage(testImage)
        
        // Wait for processing
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Check results
        await MainActor.run {
            XCTAssertFalse(ocrService.recognizedTexts.isEmpty, 
                          "Should detect text in test image")
            
            if let firstText = ocrService.recognizedTexts.first {
                print("Detected text: '\(firstText.text)' with confidence: \(firstText.confidence)")
                XCTAssertTrue(firstText.text.lowercased().contains("hello") || 
                             firstText.text.lowercased().contains("world"),
                             "Should detect test text")
            }
        }
    }
    
    func testOCRThrottling() async throws {
        let testImage = createTestImage(with: "Test")
        
        // Try rapid processing
        await ocrService.processImage(testImage)
        await ocrService.processImage(testImage) // Should be throttled
        
        // Only first should process
        await MainActor.run {
            XCTAssertFalse(ocrService.isProcessing, 
                          "Should not be processing after throttled request")
        }
    }
    
    func testClearDetectedTexts() async throws {
        let testImage = createTestImage(with: "Clear Test")
        
        // Process image
        await ocrService.processImage(testImage)
        
        // Wait for processing
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Clear texts
        await MainActor.run {
            ocrService.clear()
            XCTAssertTrue(ocrService.recognizedTexts.isEmpty, 
                         "Recognized texts should be cleared")
        }
    }
    
    func testRecognitionModeChange() async throws {
        // Test setting recognition mode
        ocrService.setRecognitionMode(.fast)
        
        // Process with fast mode
        let testImage = createTestImage(with: "Fast mode test")
        await ocrService.processImage(testImage)
        
        // Wait a bit
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Change to accurate mode
        ocrService.setRecognitionMode(.accurate)
        
        // Process with accurate mode
        await ocrService.processImage(testImage)
        
        print("Recognition mode test completed")
    }
    
    // MARK: - OCR Quality Tests
    
    func testMinimumConfidenceFiltering() async throws {
        // Create image with varying quality text
        let testImage = createComplexTestImage()
        
        await ocrService.processImage(testImage)
        
        try await Task.sleep(nanoseconds: 500_000_000)
        
        await MainActor.run {
            // All detected texts should have high confidence
            for text in ocrService.detectedTexts {
                XCTAssertGreaterThanOrEqual(text.confidence, 0.7, 
                                           "Should only include high confidence text")
            }
        }
    }
    
    func testMaximumTextLimit() async throws {
        // Create image with many text elements
        let testImage = createImageWithManyTexts()
        
        await ocrService.processImage(testImage)
        
        try await Task.sleep(nanoseconds: 500_000_000)
        
        await MainActor.run {
            XCTAssertLessThanOrEqual(ocrService.detectedTexts.count, 10,
                                     "Should limit to maximum 10 texts")
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestImage(with text: String) -> UIImage {
        let size = CGSize(width: 300, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // White background
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Black text
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 30),
                .foregroundColor: UIColor.black
            ]
            
            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            
            text.draw(in: textRect, withAttributes: attributes)
        }
    }
    
    private func createComplexTestImage() -> UIImage {
        let size = CGSize(width: 400, height: 300)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Clear text
            let clearText = "Clear Text"
            let clearAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24),
                .foregroundColor: UIColor.black
            ]
            clearText.draw(at: CGPoint(x: 50, y: 50), withAttributes: clearAttributes)
            
            // Blurry text (simulated with light gray)
            let blurryText = "Blurry"
            let blurryAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.lightGray
            ]
            blurryText.draw(at: CGPoint(x: 50, y: 150), withAttributes: blurryAttributes)
            
            // Small text
            let smallText = "tiny"
            let smallAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 8),
                .foregroundColor: UIColor.black
            ]
            smallText.draw(at: CGPoint(x: 50, y: 200), withAttributes: smallAttributes)
        }
    }
    
    private func createImageWithManyTexts() -> UIImage {
        let size = CGSize(width: 500, height: 500)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16),
                .foregroundColor: UIColor.black
            ]
            
            // Create 15 text elements
            for i in 0..<15 {
                let text = "Text \(i + 1)"
                let y = CGFloat(30 * i + 20)
                text.draw(at: CGPoint(x: 50, y: y), withAttributes: attributes)
            }
        }
    }
    
    // MARK: - Performance Tests
    
    func testOCRPerformance() async throws {
        let testImage = createTestImage(with: "Performance Test")
        
        let startTime = Date()
        await ocrService.processImage(testImage)
        
        // Wait for completion
        while await MainActor.run(body: { ocrService.isProcessing }) {
            try await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds
        }
        
        let elapsed = Date().timeIntervalSince(startTime)
        
        XCTAssertLessThan(elapsed, 1.0, "OCR should complete within 1 second")
        print("OCR completed in \(elapsed) seconds")
    }
}