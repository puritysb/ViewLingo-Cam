# ViewLingo Cam

> **This project has been discontinued.** The codebase was later migrated to [YomiLingo](https://github.com/puritysb/YomiLingo) (language learning pivot), which has also been discontinued. This repository is archived for reference only.

---

iOS 실시간 카메라 번역 앱. 카메라로 텍스트를 비추면 AR 오버레이로 번역 결과를 실시간 표시합니다.

## Features

- **Live Camera Translation** — 카메라로 비추는 텍스트를 실시간 번역
- **AR Overlay** — 원본 텍스트 위에 자연스러운 번역 오버레이 (2D Standard + 3D ARKit)
- **100% On-Device** — Apple Translation Framework 기반 완전 오프라인 처리
- **CJK Optimized** — 한국어/일본어/영어 OCR 최적화 (초저 신뢰도 임계값, 세로 텍스트 지원)
- **Privacy First** — 네트워크 호출 없음, 데이터 저장 없음

## Tech Stack

- **Swift 6.0** / **iOS 18.0+**
- Native frameworks only (no third-party dependencies):
  - Vision (OCR), Translation (on-device), AVFoundation (camera)
  - ARKit, RealityKit, Metal, CoreImage, NaturalLanguage
  - SwiftUI, Combine

## Project Structure

```
ViewLingo-Cam/
├── App/            # AppState, ViewLingoCamApp (entry point)
├── Camera/         # CameraManager (AVFoundation, 15fps), CameraView
├── Services/       # OCR, Translation, TextRecovery, LanguagePack, Localization
├── Tracking/       # TextTracker, ARKit/Vision tracking, SceneChangeDetector, MotionTracker
├── Views/          # BoxTranslationOverlay, ARKitOverlayView, Settings, Debug
├── Utils/          # Logger, CIContextHelper, AtomicInt, UnsafeSendable
├── docs/           # TECHNICAL_DOCUMENTATION.md (상세 기술 문서)
└── Testing/        # TEST_GUIDE.md, AR_MODE_TEST_GUIDE.md
```

## Performance

| Metric | Standard Mode | ARKit Mode |
|--------|--------------|------------|
| OCR | ~50ms | ~50ms |
| Translation | ~100ms | ~100ms |
| Full Pipeline | ~200ms | ~250ms |
| CPU | 15-20% | 25-35% |
| Memory | ~80MB | ~150MB |

## Build

```bash
xcodebuild -project ViewLingo-Cam.xcodeproj -scheme ViewLingo-Cam -sdk iphoneos build
```

Requires Xcode with iOS 18.0+ SDK. Camera features require a physical device.

## Documentation

- `ViewLingo-Cam/docs/TECHNICAL_DOCUMENTATION.md` — 상세 기술 문서 (아키텍처, 데이터 흐름, 최적화)
- `ViewLingo-Cam/Testing/TEST_GUIDE.md` — 테스트 시나리오 가이드
- `ViewLingo-Cam/Testing/AR_MODE_TEST_GUIDE.md` — AR 모드 테스트 가이드
- `ViewLingo-Cam/README.md` — 내부 개발 문서 (Korean)

## Related Projects

- [YomiLingo](https://github.com/puritysb/YomiLingo) — 이 프로젝트에서 분기한 한국어-일본어 학습 앱 (discontinued)

## License

MIT License
