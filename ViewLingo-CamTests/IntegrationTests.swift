//
//  IntegrationTests.swift
//  ViewLingo-CamTests
//
//  End-to-end integration tests for OCR to Translation pipeline
//

import XCTest
import UIKit
import CoreImage
import Translation
@testable import ViewLingo_Cam

@available(iOS 18.0, *)
final class IntegrationTests: XCTestCase {
    
    var ocrService: OCRService!
    var translationService: TranslationService!
    var languagePackService: LanguagePackService!
    var appState: AppState!
    
    override func setUp() async throws {
        try await super.setUp()
        await MainActor.run {
            ocrService = OCRService()
            translationService = TranslationService()
            languagePackService = LanguagePackService.shared
            appState = AppState()
        }
    }
    
    override func tearDown() async throws {
        await MainActor.run {
            ocrService = nil
            translationService = nil
            languagePackService = nil
            appState = nil
        }
        try await super.tearDown()
    }
    
    // MARK: - Full Pipeline Tests
    
    func testCompleteOCRToTranslationPipeline() async throws {
        // Step 1: Create test image with English text
        let testImage = createTestImageWithText("Welcome to ViewLingo")
        
        // Step 2: Perform OCR
        await ocrService.processImage(testImage)
        
        // Wait for OCR
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Step 3: Get detected texts
        let recognizedTexts = await MainActor.run { ocrService.recognizedTexts }
        XCTAssertFalse(recognizedTexts.isEmpty, "Should detect text")
        
        // Step 4: Check if Korean translation is available
        let sourceLanguage = "en"
        let targetLanguage = "ko"
        let canTranslate = await MainActor.run {
            languagePackService.canTranslate(from: sourceLanguage, to: targetLanguage)
        }
        
        if canTranslate {
            // Create translation session
            let config = TranslationSession.Configuration(
                source: Locale.Language(identifier: sourceLanguage),
                target: Locale.Language(identifier: targetLanguage)
            )
            
            // Note: In real app, session would be created by DynamicLanguagePackProvider
            // For testing, we skip session creation since TranslationSession has no public init
            
            // Step 5: Translate detected texts
            let texts = recognizedTexts.map { $0.text }
            let translationResults = await translationService.translateTexts(
                texts,
                targetLanguage: targetLanguage
            )
            let translations = Array(translationResults.values)
            
            XCTAssertFalse(translations.isEmpty, "Should have translations")
            
            for (text, translation) in zip(texts, translations) {
                print("Translated '\(text)' to '\(translation)'")
                XCTAssertNotEqual(text, translation, "Translation should differ from source")
            }
        } else {
            print("Cannot translate from \(sourceLanguage) to \(targetLanguage) - language pack not installed")
        }
    }
    
    func testLiveModeSimulation() async throws {
        // Simulate live mode with multiple frames
        let frames = [
            createTestImageWithText("First frame"),
            createTestImageWithText("Second frame"),
            createTestImageWithText("Third frame")
        ]
        
        let sourceLanguage = "en"
        let targetLanguage = "ja"
        
        // Check language availability
        let canTranslate = await MainActor.run {
            languagePackService.canTranslate(from: sourceLanguage, to: targetLanguage)
        }
        
        guard canTranslate else {
            throw XCTSkip("Japanese not available for live mode test")
        }
        
        // Setup translation session
        let config = TranslationSession.Configuration(
            source: Locale.Language(identifier: sourceLanguage),
            target: Locale.Language(identifier: targetLanguage)
        )
        
        guard let config = config else {
            XCTFail("Failed to create translation configuration")
            return
        }
        
        let session = TranslationSession(configuration: config)
        await MainActor.run {
            translationService.addSession(session, source: sourceLanguage, target: targetLanguage)
        }
        
        // Process each frame
        for (index, frame) in frames.enumerated() {
            print("Processing frame \(index + 1)")
            
            // OCR
            await ocrService.processImage(frame)
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            
            // Get texts
            let texts = await MainActor.run { 
                ocrService.recognizedTexts.map { $0.text }
            }
            
            // Translate
            if !texts.isEmpty {
                let translationResults = await translationService.translateTexts(
                    texts,
                    targetLanguage: targetLanguage
                )
                let translations = Array(translationResults.values)
                
                XCTAssertFalse(translations.isEmpty, 
                              "Frame \(index + 1) should have translations")
            }
            
            // Clear for next frame
            await MainActor.run {
                ocrService.recognizedTexts.removeAll()
            }
            
            // Simulate frame interval
            try await Task.sleep(nanoseconds: 333_000_000) // ~30fps
        }
    }
    
    func testAppStateIntegration() async throws {
        // Test app state management
        await MainActor.run {
            // Set target language
            appState.targetLanguage = "ko"
            XCTAssertEqual(appState.targetLanguage, "ko")
            
            // Toggle live translation
            appState.isLiveTranslationEnabled = true
            XCTAssertTrue(appState.isLiveTranslationEnabled ?? false)
            
            // Check AR mode
            XCTAssertNotNil(appState.arMode)
        }
    }
    
    func testCJKTextProcessing() async throws {
        // Test Korean text
        let koreanImage = createTestImageWithText("안녕하세요")
        await ocrService.processImage(koreanImage)
        try await Task.sleep(nanoseconds: 500_000_000)
        
        let koreanTexts = await MainActor.run { ocrService.recognizedTexts }
        if !koreanTexts.isEmpty {
            print("Detected Korean text: \(koreanTexts.map { $0.text })")
            
            // Try to translate to English
            let canTranslate = await MainActor.run {
                languagePackService.canTranslate(from: "ko", to: "en")
            }
            
            if canTranslate {
                let config = TranslationSession.Configuration(
                    source: Locale.Language(identifier: "ko"),
                    target: Locale.Language(identifier: "en")
                )
                
                if let config = config {
                    let session = TranslationSession(configuration: config)
                    await MainActor.run {
                        translationService.addSession(session, source: "ko", target: "en")
                    }
                    
                    let translationResults = await translationService.translateTexts(
                        koreanTexts.map { $0.text },
                        targetLanguage: "en"
                    )
                    let translations = Array(translationResults.values)
                    
                    print("Korean to English translations: \(translations)")
                }
            }
        }
        
        // Clear and test Japanese text
        await MainActor.run {
            ocrService.recognizedTexts.removeAll()
        }
        
        let japaneseImage = createTestImageWithText("こんにちは")
        await ocrService.processImage(japaneseImage)
        try await Task.sleep(nanoseconds: 500_000_000)
        
        let japaneseTexts = await MainActor.run { ocrService.recognizedTexts }
        if !japaneseTexts.isEmpty {
            print("Detected Japanese text: \(japaneseTexts.map { $0.text })")
        }
    }
    
    func testPerformanceMetrics() async throws {
        let testImage = createTestImageWithText("Performance test text")
        
        // Measure OCR performance
        let ocrStart = Date()
        await ocrService.processImage(testImage)
        try await Task.sleep(nanoseconds: 100_000_000)
        let ocrTime = Date().timeIntervalSince(ocrStart)
        
        print("OCR completed in \(ocrTime)s")
        XCTAssertLessThan(ocrTime, 1.0, "OCR should complete within 1 second")
        
        // Get detected texts
        let texts = await MainActor.run { 
            ocrService.recognizedTexts.map { $0.text }
        }
        
        if !texts.isEmpty {
            // Check if translation is available
            let canTranslate = await MainActor.run {
                languagePackService.canTranslate(from: "en", to: "ko")
            }
            
            if canTranslate {
                // Setup session
                let config = TranslationSession.Configuration(
                    source: Locale.Language(identifier: "en"),
                    target: Locale.Language(identifier: "ko")
                )
                
                if let config = config {
                    let session = TranslationSession(configuration: config)
                    await MainActor.run {
                        translationService.addSession(session, source: "en", target: "ko")
                    }
                    
                    // Measure translation performance
                    let translationStart = Date()
                    let translationResults = await translationService.translateTexts(
                        texts,
                        targetLanguage: "ko"
                    )
                    let translations = Array(translationResults.values)
                    let translationTime = Date().timeIntervalSince(translationStart)
                    
                    print("Translation completed in \(translationTime)s")
                    XCTAssertLessThan(translationTime, 2.0, "Translation should complete within 2 seconds")
                    
                    // Total pipeline time
                    let totalTime = ocrTime + translationTime
                    print("Total pipeline time: \(totalTime)s")
                    XCTAssertLessThan(totalTime, 3.0, "Full pipeline should complete within 3 seconds")
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestImageWithText(_ text: String) -> CIImage {
        // Create a simple test image with text
        let size = CGSize(width: 400, height: 200)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let uiImage = renderer.image { context in
            // White background
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Black text
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 32),
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
        
        guard let cgImage = uiImage.cgImage else {
            return CIImage()
        }
        
        return CIImage(cgImage: cgImage)
    }
}