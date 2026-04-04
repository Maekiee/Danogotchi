# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

**Danogotchi (단어고치)** — iOS 단어 학습 앱 (iOS 16.0+, iPhone only)
- Swift 5.0, UIKit 기반 프로그래매틱 UI (스토리보드 없음)
- MVVM + Repository Pattern + RxSwift 아키텍처
- 로컬 저장소: Realm, 원격 저장소: Firebase Firestore

## 빌드 명령어

```bash
# Debug 빌드
xcodebuild -scheme Danogotchi-dev build

# Release 빌드
xcodebuild -scheme Danogotchi build

# Xcode에서 실행: 시뮬레이터 또는 실기기 선택 후 ⌘R
```

**주의:** `Danogotchi/App/Secret/Firebase/` 폴더의 `GoogleService-Info.plist`는 `.gitignore`에 포함되어 있으며, 빌드 전 환경별로 별도 설정이 필요합니다.

## 의존성 (Swift Package Manager)

| 패키지 | 용도 |
|--------|------|
| RxSwift / RxCocoa | 반응형 프로그래밍, UI 바인딩 |
| SnapKit | 프로그래매틱 Auto Layout DSL |
| RealmSwift | 로컬 데이터베이스 |
| Firebase (Core, Firestore, Crashlytics, Messaging, RemoteConfig) | 원격 DB, 알림, 분석 |
| Alamofire | HTTP 네트워크 요청 |
| Kingfisher | 이미지 로딩 및 캐싱 |

## 아키텍처 및 데이터 흐름

```
ViewController (Input) → ViewModel.transform() → Repository → Realm / Firestore
                ↑                        ↓
                └──── Driver<T> Output 바인딩 (RxCocoa) ────┘
```

### 레이어 구조

- **`App/`** — AppDelegate (Firebase 초기화, FCM), SceneDelegate (루트 VC 전환)
- **`ViewControllers/`** — 화면 19개, 모두 프로그래매틱 UI + SnapKit
- **`ViewModels/`** — `BaseViewModel` 프로토콜 기반 Input/Output 패턴
- **`Repositories/`** — 프로토콜 우선 설계, Realm(로컬)/Firestore(원격) 구현체 분리
- **`Managers/`** — 싱글턴 전역 상태 (UserInfoManager, ActiveLearningManager, TTSManager)
- **`RealmObjects/`** — Realm 스키마 (WordObject, WordBookObject, LearningHistoryTable)
- **`Components/`** — 재사용 UI 컴포넌트 (일부 SwiftUI 혼용)
- **`Utils/`** — ApiService (Alamofire), FirestoreService, AlertUtils
- **`ViewData/`** — DTO 및 화면 표시용 데이터 모델

### ViewModel 패턴

모든 ViewModel은 `BaseViewModel` 프로토콜을 따르며 `Input`/`Output` 구조체와 `transform(input:)` 메서드를 구현합니다. Output은 RxSwift `Driver<T>`를 사용해 메인 스레드 보장 + 에러 없는 스트림을 제공합니다.

### 주요 싱글턴

- `UserInfoManager` — UserDefaults 기반 사용자 프로필, 활성 단어장 ID/타입, 테마 URL
- `ActiveLearningManager` — 현재 학습 세션의 반응형 상태 관리

### 로컬 DB (Realm)

Debug 빌드 시 콘솔에 Realm 파일 경로가 출력됩니다. 스키마 변경 시 마이그레이션 처리가 필요합니다.

## 컬렉션뷰 패턴

UICollectionView는 `UICollectionViewDiffableDataSource`를 사용합니다. `WaterFallLayout`은 워터폴(Masonry) 형태의 커스텀 레이아웃입니다.

## UI 혼용 (UIKit + SwiftUI)

`CardBlurView`는 SwiftUI로 구현된 블러 카드 컴포넌트이며, `UIHostingController`를 통해 UIKit 셀에서 임베드됩니다 (`MainWordCardCollectionViewCell` 참고).

## 환경 구분

- **Debug:** 앱 이름 `단어고치[DEV]`, 번들 ID 접미사 포함
- **Release:** 번들 ID `com.maekie.Danogotchi`
- 빌드 단계에서 환경에 맞는 `GoogleService-Info.plist`가 자동으로 복사됩니다.
