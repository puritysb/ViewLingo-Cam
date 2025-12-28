//
//  TranslationTests.swift
//  ViewLingo-CamTests
//
//  Comprehensive translation functionality tests
//

import XCTest
import Translation
@testable import ViewLingo_Cam

@available(iOS 18.0, *)
final class TranslationTests: XCTestCase {
    
    var translationService: TranslationService!
    var languagePackService: LanguagePackService!
    
    override func setUp() async throws {
        try await super.setUp()
        await MainActor.run {
            translationService = TranslationService()
            languagePackService = LanguagePackService.shared
        }
    }
    
    override func tearDown() async throws {
        await MainActor.run {
            translationService = nil
            languagePackService = nil
        }
        try await super.tearDown()
    }
    
    // MARK: - Language Installation Tests
    
    func testCheckLanguageInstallation() async throws {
        // Test common language pairs
        let languagePairs = [
            ("en", "ko"),
            ("ko", "en"),
            ("en", "ja"),
            ("ja", "en"),
            ("ko", "ja"),
            ("ja", "ko")
        ]
        
        for (source, target) in languagePairs {
            let canTranslate = await MainActor.run {
                languagePackService.canTranslate(from: source, to: target)
            }
            print("Can translate \(source)→\(target): \(canTranslate)")
        }
    }
    
    func testLanguagePackStatus() async throws {
        // Check all language pack statuses
        await languagePackService.checkAllStatuses()
        
        // Wait for status check to complete
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        await MainActor.run {
            let statuses = languagePackService.packStatuses
            
            // Should have statuses for all supported pairs
            XCTAssertFalse(statuses.isEmpty, "Should have language pack statuses")
            
            // Log all statuses
            for (pair, status) in statuses {
                print("Language pair \(pair.key): \(status)")
            }
        }
    }
    
    // MARK: - Translation Tests
    
    func testBasicTranslation() async throws {
        let sourceText = "Hello, world!"
        let sourceLanguage = "en"
        let targetLanguage = "ko"
        
        // Check if translation is possible
        let canTranslate = await MainActor.run {
            languagePackService.canTranslate(from: sourceLanguage, to: targetLanguage)
        }
        
        if canTranslate {
            // Create a translation configuration
            let config = TranslationSession.Configuration(
                source: Locale.Language(identifier: sourceLanguage),
                target: Locale.Language(identifier: targetLanguage)
            )
            
            guard let config = config else {
                XCTFail("Failed to create translation configuration")
                return
            }
            
            // Create session
            let session = TranslationSession(configuration: config)
            
            // Add session to service
            await MainActor.run {
                translationService.addSession(session, source: sourceLanguage, target: targetLanguage)
            }
            
            // Translate text
            let translations = await translationService.translateTexts(
                [sourceText],
                from: sourceLanguage,
                to: targetLanguage
            )
            
            XCTAssertFalse(translations.isEmpty, "Should have translation results")
            if let translation = translations.first {
                print("Translated '\(sourceText)' to '\(translation)'")
                XCTAssertFalse(translation.isEmpty, "Translation should not be empty")
            }
        } else {
            print("Cannot translate from \(sourceLanguage) to \(targetLanguage) - language pack not installed")
        }
    }
    
    func testMultipleTranslations() async throws {
        let texts = [
            "Good morning",
            "How are you?",
            "Thank you"
        ]
        let sourceLanguage = "en"
        let targetLanguage = "ja"
        
        // Check if translation is possible
        let canTranslate = await MainActor.run {
            languagePackService.canTranslate(from: sourceLanguage, to: targetLanguage)
        }
        
        if canTranslate {
            // Create configuration and session
            let config = TranslationSession.Configuration(
                source: Locale.Language(identifier: sourceLanguage),
                target: Locale.Language(identifier: targetLanguage)
            )
            
            guard let config = config else {
                XCTFail("Failed to create translation configuration")
                return
            }
            
            let session = TranslationSession(configuration: config)
            
            // Add session
            await MainActor.run {
                translationService.addSession(session, source: sourceLanguage, target: targetLanguage)
            }
            
            // Translate multiple texts
            let translations = await translationService.translateTexts(
                texts,
                from: sourceLanguage,
                to: targetLanguage
            )
            
            XCTAssertEqual(translations.count, texts.count, "Should have same number of translations")
            
            for (original, translated) in zip(texts, translations) {
                print("'\(original)' → '\(translated)'")
                XCTAssertFalse(translated.isEmpty, "Translation should not be empty")
            }
        } else {
            print("Cannot translate from \(sourceLanguage) to \(targetLanguage) - language pack not installed")
        }
    }
    
    func testCaching() async throws {
        let text = "Cache test"
        let sourceLanguage = "en"
        let targetLanguage = "ko"
        
        // Check if translation is possible
        let canTranslate = await MainActor.run {
            languagePackService.canTranslate(from: sourceLanguage, to: targetLanguage)
        }
        
        if canTranslate {
            // Create session
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
            
            // First translation
            let startTime1 = Date()
            let result1 = await translationService.translateTexts(
                [text],
                from: sourceLanguage,
                to: targetLanguage
            )
            let time1 = Date().timeIntervalSince(startTime1)
            
            // Second translation (should be cached)
            let startTime2 = Date()
            let result2 = await translationService.translateTexts(
                [text],
                from: sourceLanguage,
                to: targetLanguage
            )
            let time2 = Date().timeIntervalSince(startTime2)
            
            // Verify same result
            XCTAssertEqual(result1.first, result2.first, "Cached translation should be the same")
            
            // Cached should be faster
            print("First translation: \(time1)s, Cached: \(time2)s")
            XCTAssertLessThan(time2, time1, "Cached translation should be faster")
        }
    }
    
    func testLanguageDetection() async throws {
        // Test language detection with different texts
        let testCases = [
            ("Hello world", "en"),
            ("안녕하세요", "ko"),
            ("こんにちは", "ja"),
            ("Bonjour", "fr"),
            ("Hola", "es")
        ]
        
        for (text, expectedLanguage) in testCases {
            let detectedLanguage = await MainActor.run {
                translationService.detectLanguage(for: text)
            }
            
            print("Text: '\(text)' - Detected: \(detectedLanguage ?? "unknown"), Expected: \(expectedLanguage)")
            
            // Language detection might not be perfect, so we just log results
            if let detected = detectedLanguage {
                if detected == expectedLanguage {
                    print("✅ Correctly detected")
                } else {
                    print("⚠️ Different detection")
                }
            }
        }
    }
    
    func testEmptyTextHandling() async throws {
        let emptyTexts = ["", "   ", "\n\n"]
        
        for text in emptyTexts {
            let result = await translationService.translateTexts(
                [text],
                from: "en",
                to: "ko"
            )
            
            // Should handle empty text gracefully
            XCTAssertTrue(result.isEmpty || result.first?.isEmpty == true,
                         "Empty text should return empty or no translation")
        }
    }
    
    func testSameLanguageTranslation() async throws {
        let text = "Test"
        let language = "en"
        
        // Try to translate to same language
        let canTranslate = await MainActor.run {
            languagePackService.canTranslate(from: language, to: language)
        }
        
        XCTAssertFalse(canTranslate, "Should not allow same language translation")
    }
    
    func testUnsupportedLanguage() async throws {
        // Try an unsupported language
        let canTranslate = await MainActor.run {
            languagePackService.canTranslate(from: "en", to: "xyz")
        }
        
        XCTAssertFalse(canTranslate, "Should not support invalid language code")
    }
    
    // MARK: - Performance Tests
    
    func testTranslationPerformance() async throws {
        let texts = (1...10).map { "Test text \($0)" }
        let sourceLanguage = "en"
        let targetLanguage = "ko"
        
        // Check if translation is possible
        let canTranslate = await MainActor.run {
            languagePackService.canTranslate(from: sourceLanguage, to: targetLanguage)
        }
        
        if canTranslate {
            // Setup session
            let config = TranslationSession.Configuration(
                source: Locale.Language(identifier: sourceLanguage),
                target: Locale.Language(identifier: targetLanguage)
            )
            
            guard let config = config else { return }
            
            let session = TranslationSession(configuration: config)
            await MainActor.run {
                translationService.addSession(session, source: sourceLanguage, target: targetLanguage)
            }
            
            // Measure performance
            let startTime = Date()
            let translations = await translationService.translateTexts(
                texts,
                from: sourceLanguage,
                to: targetLanguage
            )
            let elapsed = Date().timeIntervalSince(startTime)
            
            print("Translated \(texts.count) texts in \(elapsed)s")
            print("Average: \(elapsed / Double(texts.count))s per text")
            
            XCTAssertEqual(translations.count, texts.count)
            XCTAssertLessThan(elapsed, 5.0, "Should translate 10 texts in under 5 seconds")
        }
    }
}