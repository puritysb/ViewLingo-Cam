# ViewLingo Cam 1.0

## 🎯 세계에서 가장 빠른 온디바이스 실시간 카메라 번역 앱

ViewLingo Cam은 iOS 18의 최신 Translation API를 활용하여 카메라로 비춘 텍스트를 실시간으로 번역하는 AR 번역 앱입니다.

## ✨ 핵심 특징

- **100% 온디바이스 처리**: 완전한 프라이버시 보호
- **실시간 AR 오버레이**: 원본 텍스트 위에 자연스럽게 번역 표시
- **팝업 없는 카메라 모드**: 번역 중 언어 팩 설치 팝업 완전 차단
- **3개 언어 지원**: 한국어, 영어, 일본어 상호 번역
- **빠른 성능**: OCR→번역 300ms 이내

## 🏗️ 아키텍처

### 폴더 구조
```
ViewLingo-Cam/
├── App/                  # 앱 진입점 및 상태 관리
├── Onboarding/          # 온보딩 및 언어 팩 설치
├── Camera/              # 카메라 세션 관리
├── Services/            # 핵심 서비스 (OCR, 번역, 언어팩)
├── Views/               # UI 컴포넌트
└── Utils/               # 유틸리티 (로깅)
```

### 핵심 원칙

#### 1. 언어 팩 관리
- **온보딩에서만 설치**: 앱 첫 실행 시 필요한 모든 언어 팩 설치
- **카메라 모드 차단**: 절대 prepareTranslation() 호출 금지
- **상태 기반 번역**: 설치된 언어만 번역, 미설치 시 건너뛰기

#### 2. 번역 플로우
```swift
1. OCR 수행 (Vision Framework)
2. 언어 팩 확인 (canTranslate)
3. 가능한 경우만 번역
4. AR 오버레이 표시
```

## 🚀 시작하기

### 요구사항
- iOS 18.0+
- Xcode 16.0+
- iPhone 12 이상

### 설치
1. Xcode에서 프로젝트 열기
2. ViewLingo-Cam 타겟 선택
3. 새 파일들을 타겟에 추가
4. 빌드 및 실행

## 📱 사용 방법

### 온보딩
1. 앱 첫 실행 시 환영 화면
2. 번역 대상 언어 선택 (한국어/영어/일본어)
3. 언어 팩 자동 설치 (진행률 표시)
4. 완료 후 카메라 시작

### 카메라 모드
1. 텍스트에 카메라 비추기
2. 자동 OCR 및 번역
3. AR 오버레이로 결과 표시
4. Live 모드로 실시간 번역

## 🔧 기술 스택

- **OCR**: Vision Framework (Accurate 모드)
- **번역**: Translation Framework (iOS 18)
- **카메라**: AVCaptureSession
- **UI**: SwiftUI
- **로깅**: os.log + 파일 로깅

## 🚫 주의사항

### 절대 하지 말아야 할 것
1. 카메라 모드에서 TranslationSession.prepareTranslation() 호출
2. 미설치 언어 감지 시 다운로드 시도
3. 동적 UIHostingController present/dismiss

### 반드시 해야 할 것
1. 온보딩에서 모든 언어 팩 설치 완료
2. 카메라 모드 진입 전 언어 팩 상태 확인
3. 번역 불가 시 조용히 건너뛰기

## 📊 성능 목표

- 앱 실행 → 첫 번역: < 3초
- OCR 처리: < 250ms
- 번역 처리: < 150ms
- 메모리 사용: < 100MB
- 배터리: 10분 사용 시 < 5%

## 🐛 디버깅

### 로그 확인
```swift
// 앱 내 디버그 뷰
설정 > 디버그 정보 > 로그

// 파일 로그 위치
Documents/ViewLingoCam.log
```

### 언어 팩 상태
```swift
// 디버그 뷰에서 확인
설정 > 디버그 정보 > 언어 팩
```

## 📝 로깅 카테고리

- `🔍 DEBUG`: 디버그 정보
- `ℹ️ INFO`: 일반 정보
- `⚠️ WARN`: 경고
- `❌ ERROR`: 에러
- `📋 [Onboarding]`: 온보딩 관련
- `📦 [LanguagePack]`: 언어 팩 관련
- `🔤 [Translation]`: 번역 관련
- `👁️ [OCR]`: OCR 관련
- `📷 [Camera]`: 카메라 관련

## 🔄 업데이트 내역

### v1.0.0 (2025-01-28)
- 초기 릴리즈
- 팝업 없는 카메라 모드
- 안정적인 언어 팩 관리
- 개선된 AR 오버레이
- 상세 로깅 시스템

## 📄 라이선스

Copyright © 2025 ViewLingo Team. All rights reserved.