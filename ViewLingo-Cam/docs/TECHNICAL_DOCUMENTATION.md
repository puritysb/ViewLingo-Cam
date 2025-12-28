# ViewLingo Cam 기술 문서

## 🏗️ 아키텍처 개요

ViewLingo Cam은 iOS 18 이상에서 작동하는 실시간 카메라 번역 앱으로, 온디바이스 OCR과 번역을 사용하여 네트워크 연결 없이 즉각적인 AR 오버레이 번역을 제공합니다.

### 핵심 원칙
1. **100% 온디바이스 처리**: 모든 OCR과 번역이 로컬에서 처리됨
2. **카메라 모드에서 팝업 없음**: 언어 팩은 온보딩 중에만 사전 설치
3. **실시간 성능**: OCR→번역 300ms 이내
4. **프라이버시 우선**: 어떤 데이터도 기기를 벗어나지 않음

## 📐 시스템 아키텍처

### 모드 아키텍처

#### Standard 모드 (기본)
- **기술**: AVFoundation + Vision Framework + 2D 오버레이
- **성능**: 최적 (CPU 15-20%, 메모리 ~80MB)
- **사용 사례**: 모든 사용자를 위한 프로덕션 준비 완료
- **특징**:
  - 안정적인 텍스트 추적을 위한 적응형 스무딩
  - 일본어 텍스트 최적화
  - 화면 밖 텍스트 즉시 제거
  - 장면 변화 감지

#### ARKit 모드 (실험적)
- **기술**: ARKit + RealityKit + 3D 앵커
- **성능**: 무거움 (CPU 25-35%, 메모리 ~150MB)
- **사용 사례**: 미래의 3D AR 기능
- **상태**: 기능은 작동하나 최적화되지 않음

### 컴포넌트 아키텍처

```
ViewLingo-Cam/ (Swift 6.0)
├── App/
│   ├── AppState.swift           # 전역 상태 관리
│   └── ViewLingoCamApp.swift    # 앱 진입점
├── Camera/
│   ├── CameraManager.swift      # AVCaptureSession 관리
│   └── CameraView.swift         # 메인 카메라 UI
├── Services/
│   ├── OCRService.swift         # Vision Framework OCR (기본 .accurate 모드)
│   ├── TranslationService.swift # Translation Framework
│   └── LanguagePackService.swift # 언어 팩 관리
├── Tracking/
│   ├── TextTracker.swift        # 텍스트 지속성 및 스무딩 (CJK 최적화)
│   └── SceneChangeDetector.swift # 장면 전환 감지
├── Views/
│   ├── ARTranslationOverlay.swift # 버블 스타일 오버레이
│   ├── BoxTranslationOverlay.swift # 박스 스타일 오버레이
│   └── ARKitOverlayView.swift     # ARKit 3D 오버레이
└── Utils/
    ├── Logger.swift              # 로깅 시스템
    └── TextRecovery.swift        # OCR 오류 복구
```

## 🔄 데이터 흐름

### 번역 파이프라인

```
카메라 프레임 → OCR 서비스 → 텍스트 추적기 → 언어 감지 → 번역 서비스 → AR 오버레이 → 화면
```

### 상세 흐름

1. **프레임 캡처** (30fps)
   - AVCaptureSession이 CVPixelBuffer 제공
   - 프레임 카운터가 처리 빈도 결정
   
2. **OCR 처리**
   - 모드 기반 구성:
     - Initial: 정확한 모드 (.accurate), 마스킹 없음
     - Tracking: 정확한 모드 (.accurate), 마스킹된 영역 (안정성 우선)
     - Refresh: 주기적 전체 스캔
   - 일본어 텍스트 감지 시 언어 우선순위 조정 (ja-JP 우선)
   - 모든 언어에서 기본적으로 .accurate 모드 사용
   
3. **텍스트 추적**
   - 여러 관찰의 시간적 융합
   - 품질 점수 시스템
   - 공간 중복 제거
   - 지속성 관리
   
4. **번역**
   - 명시적 언어 쌍 세션 (자동 감지 없음)
   - 캐시 관리 (200개 항목)
   - 효율성을 위한 배치 처리
   
5. **오버레이 렌더링**
   - Standard 모드용 2D SwiftUI 뷰
   - 적응형 팩터를 사용한 위치 스무딩
   - 가시성을 위한 화면 내 감지

## 🔧 기술 구현

### 좌표계 변환

#### Vision → 화면 좌표

Vision Framework 사용:
- 원점: 왼쪽 하단
- 범위: [0,1] 정규화
- 방향: 가로

화면 사용:
- 원점: 왼쪽 상단  
- 범위: 픽셀 좌표
- 방향: 세로/가로

**세로 모드 변환:**
```swift
// 90도 반시계 방향 회전
screenX = visionBox.minY * screenSize.width
screenY = (1.0 - visionBox.maxX) * screenSize.height
screenWidth = visionBox.height * screenSize.width
screenHeight = visionBox.width * screenSize.height
```

### 일본어 텍스트 최적화

일본어 텍스트는 다음과 같은 이유로 특별한 처리가 필요합니다:
1. **낮은 OCR 신뢰도**: 종종 0.1 미만 (영어는 0.2 이상)
2. **작은 바운딩 박스**: 컴팩트한 문자
3. **복잡한 문자**: 한자/히라가나/가타카나 혼합

**최적화:**
```swift
// 일본어용 초저 신뢰도 임계값
if hasJapanese {
    minConfidenceThreshold = 0.05  // 영어는 0.2
}

// 완화된 크기 필터링
if textMightBeJapanese {
    minWidth = 0.01   // 화면의 1% (표준 2%)
    minHeight = 0.008 // 화면의 0.8%
}

// OCR 모드 설정 (기본 .accurate)
request.recognitionLevel = .accurate  // 모든 언어에서 정확한 모드 사용
if recentJapaneseDetection {
    request.recognitionLanguages = ["ja-JP", "en-US"]  // 일본어 우선순위
} else {
    request.recognitionLanguages = ["en-US", "ja-JP", "ko-KR"]
}
```

### 텍스트 추적 및 스무딩

#### 적응형 스무딩 알고리즘

```swift
// 모드별 기본 스무딩 팩터
Standard 모드: 0.75 (영어), 0.65 (CJK 텍스트: 한국어, 일본어)
ARKit 모드: 0.85 (영어), 0.8 (CJK 텍스트)

// 움직임 기반 적응
큰 움직임 (>10%): 팩터 + 0.2 (빠른 반응)
중간 (5-10%): 팩터 + 0.1
작은 (2-5%): 기본 팩터
아주 작은 (<2%): 팩터 - 0.3 (고정)

// CJK 텍스트(한국어, 일본어)는 추가 고정성
if hasCJK {
    baseFactor -= 0.1  // 더 안정적인 추적
}
```

#### 텍스트 품질 점수

품질 점수 (0-1) 기준:
- 신뢰도: 30% 가중치
- 텍스트 길이: 20% 가중치
- 문자 품질: 20% 가중치
- 번역 가용성: 20% 가중치
- CJK 보너스: 10% 가중치

점수 0.4 미만의 텍스트는 표시되지 않음.

### 장면 변화 감지

카메라 움직임/장면 전환 감지:
- **안정**: 텍스트 변화 30% 미만, 지속성 × 2.0
- **이동 중**: 변화 30-70%, 지속성 × 1.0  
- **전환 중**: 변화 70% 초과, 지속성 × 0.3

전환 시 오버레이 자동 삭제 트리거.

### 메모리 관리

#### 텍스트 제한
- 최대 추적 텍스트: 15개
- 대기 텍스트 큐: 3프레임 확인
- 번역 캐시: 200개 항목
- 프레임 처리: 2-3프레임마다

#### 화면 밖 제거 (Standard 모드)
```swift
if !isOnScreen {
    // 1프레임 후 즉시 제거
    shouldRemove = framesSinceLastSeen >= 1
}
```

## 📊 성능 지표

### 목표 성능

| 지표 | 목표 | 실제 (Standard) | 실제 (ARKit) |
|------|------|----------------|--------------|
| OCR 지연시간 | <250ms | ~50ms | ~50ms |
| 번역 | <150ms | ~100ms | ~100ms |
| 전체 파이프라인 | <500ms | ~200ms | ~250ms |
| CPU 사용률 | <30% | 15-20% | 25-35% |
| 메모리 | <150MB | ~80MB | ~150MB |
| 배터리 (10분) | <8% | ~5% | ~8% |

### 처리 빈도

**Standard 모드:**
- 추적: 2프레임마다 (15 fps)
- 새로고침: 45프레임마다 (1.5초)
- 일본어: 감지 시 매 프레임

**ARKit 모드:**
- ARFrameProcessor가 처리
- 유사한 빈도 패턴

## 🐛 알려진 이슈 및 해결책

### 이슈 1: 일본어 텍스트 감지
**문제**: 매우 낮은 신뢰도 점수로 자주 필터링됨
**해결책**: 
- 초저 신뢰도 임계값 (0.05)
- 완화된 크기 필터
- 정확한 모드 강제
- 감지 시 매 프레임 처리

### 이슈 2: 텍스트 깜빡임
**문제**: 텍스트가 사라졌다가 다시 나타남
**해결책**:
- 움직임 기반 적응형 스무딩
- 관찰의 시간적 융합
- 품질 기반 지속성

### 이슈 3: 화면 밖 텍스트 지속
**문제**: 화면 밖으로 이동한 텍스트가 남아있음
**해결책**:
- 화면 밖 1프레임 후 즉시 제거 (Standard 모드)
- 더 엄격한 화면 마진 감지 (2% 마진)

### 이슈 4: 좌표 정렬 불일치
**문제**: 오버레이 위치가 텍스트와 일치하지 않음
**해결책**:
- 적절한 Vision→화면 변환
- 기기 방향 고려
- 세로 모드용 90° 반시계 회전

## 🚀 최적화 전략

### OCR 최적화
1. **인식 모드 선택**
   - 모든 언어에서 기본적으로 정확한 모드 (.accurate) 사용
   - 일본어 감지 시 언어 우선순위 조정 (ja-JP 우선)
   - 안정성과 정확도를 우선시하는 설계
   
2. **영역 마스킹**
   - 이미 추적된 영역 건너뛰기
   - 중복 처리 감소
   
3. **가장자리 필터링**
   - Standard 모드용 0.5% 마진
   - ARKit 모드용 2% 마진

### 번역 최적화
1. **명시적 세션**
   - 자동 감지 오버헤드 없음
   - 사전 생성된 언어 쌍
   
2. **캐싱**
   - 200개 항목 LRU 캐시
   - 번역 전 확인
   
3. **배치 처리**
   - 소스 언어별 텍스트 그룹화
   - 언어당 단일 API 호출

### 메모리 최적화
1. **텍스트 제한**
   - 최대 15개 추적 텍스트
   - 초과 시 가장 오래된 것 자동 제거
   
2. **대기 큐**
   - 추적 전 3프레임 확인
   - 노이즈가 시스템에 진입하는 것 방지
   
3. **캐시 제한**
   - 번역 캐시: 200개 항목
   - FIFO 제거 정책

## 🔐 프라이버시 및 보안

### 데이터 처리
- **네트워크 호출 없음**: 모든 것이 온디바이스에서 처리
- **데이터 저장 없음**: 임시 메모리 내 캐싱만
- **분석 없음**: 추적이나 원격 측정 없음
- **카메라 접근**: 필수, 명확히 설명됨

### 언어 팩 관리
- **사전 설치**: 온보딩 중에만
- **동적 다운로드 없음**: 카메라 모드에서 절대 안 함
- **상태 확인**: 논블로킹 검증

## 📱 기기 호환성

### 요구사항
- **최소 iOS**: 18.0
- **기기**: iPhone 12 이상
- **필수 기능**:
  - 카메라 접근
  - Vision Framework
  - Translation Framework
  - ARKit (선택사항)

### 기기별 성능

| 기기 | Standard 모드 | ARKit 모드 |
|------|--------------|------------|
| iPhone 15 Pro | 우수 | 양호 |
| iPhone 14 | 우수 | 양호 |
| iPhone 13 | 양호 | 보통 |
| iPhone 12 | 양호 | 보통 |

## 🔄 버전 히스토리

### v1.0.0 (현재)
- 초기 릴리즈
- 통합 Standard 모드 (Legacy + Enhanced)
- 일본어 텍스트 최적화
- 즉각적인 화면 밖 제거
- 장면 변화 감지
- 텍스트 품질 점수
- 기본 OCR 및 번역
- ARKit 실험 모드

## 🛠️ 개발 가이드라인

### 새 기능 추가
1. Standard 모드 구현 선호
2. 일본어 텍스트로 테스트
3. 메모리 사용량 모니터링
4. 300ms 미만 지연시간 보장

### 코드 스타일
- Swift 6.0 기능 사용 (strict concurrency checking)
- Apple의 Swift API 가이드라인 준수
- 디버깅을 위한 로깅 추가
- 복잡한 알고리즘에 주석 추가

### 테스트 체크리스트
- [ ] 3개 언어 모두 테스트 (한국어, 영어, 일본어)
- [ ] 화면 밖 제거 검증
- [ ] 시간 경과에 따른 메모리 사용량 확인
- [ ] 좌표 변환 검증
- [ ] 장면 전환 테스트
- [ ] 카메라 모드에서 팝업 없음 확인

## 📚 참고자료

- [Vision Framework 문서](https://developer.apple.com/documentation/vision)
- [Translation Framework (iOS 18)](https://developer.apple.com/documentation/translation)
- [ARKit 문서](https://developer.apple.com/documentation/arkit)
- [AVFoundation 프로그래밍 가이드](https://developer.apple.com/documentation/avfoundation)

---

*최종 업데이트: 2025년 1월*
*버전: 1.0.0*