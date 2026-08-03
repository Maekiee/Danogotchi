# 빌드 환경 / 의존성 / UI

## 환경(스킴) 상태

### `Danogotchi-dev` (개발)
- 앱 표시명: `단어고치[DEV]`
- 번들 ID: DEV 접미사 포함
- Firebase 설정: Debug용 `GoogleService-Info.plist`

### `Danogotchi` (운영)
- 앱 표시명: `단어고치`
- 번들 ID: `com.maekie.Danogotchi`
- Firebase 설정: Release용 `GoogleService-Info.plist`

### 공통 사항
- 빌드 페이즈에서 환경에 맞는 `GoogleService-Info.plist`가 자동 복사된다.
- `Danogotchi/App/Secret/Firebase/`는 `.gitignore`에 포함 — 빌드 전 환경별 plist를 별도 배치해야 한다.

## 테스트 상태

- 현재 별도 테스트 타깃 / 자동화된 단위·UI 테스트는 운영되지 않는다.
- 검증은 시뮬레이터·실기기 수동 테스트로 진행한다.
- 테스트 추가 시 Domain 레이어부터 우선 도입(외부 의존성이 없어 격리 용이).

## 로컬 DB

- CoreData 사용. 스택은 `Core/Storage/CoreDataStack.swift` — `NSPersistentContainer(name: "Model")` 싱글턴, `viewContext`에 자동 머지 + `NSMergeByPropertyObjectTrumpMergePolicy` 적용.
- 모델 파일: `Shared/Data/DataSources/CoreDataEntities/Model.xcdatamodeld` (엔티티: `VocabEntity` / `VocabBookEntity` / `LearningHistoryEntity`).
- 스키마 변경 시 마이그레이션 처리 필요.

## 컬렉션뷰 / UI

- `UICollectionView`는 `UICollectionViewDiffableDataSource` 사용.
- `WaterfallLayout`(`Feature/SearchTheme/Components/WaterFallLayout.swift`)은 워터폴(Masonry) 형태의 커스텀 레이아웃.
- `CardBlurView`는 SwiftUI로 구현되어 `UIHostingController`로 UIKit 셀에 임베드 (`MainWordCardCollectionViewCell` 참고).

## 의존성 (Swift Package Manager)
- RxSwift / RxCocoa: 반응형 프로그래밍, UI 바인딩
- SnapKit: 프로그래매틱 Auto Layout DSL
- Firebase: (Core, Firestore, Crashlytics, Messaging, RemoteConfig): 원격 DB, 알림, 분석
- Alamofire: HTTP 네트워크 요청 (`Core/Network/ApiService.swift`)
- Kingfisher: 이미지 로딩 및 캐싱
- IQKeyboardManager: 키보드 회피/툴바 자동 처리 (`App/AppDelegate.swift`에서 전역 활성화)
- Toast-Swift: 토스트 메시지 (`Core/Utils/ToastManager.swift`)


