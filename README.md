<div align="left">

# 단어고치

단어고치는 영어학습을 하고 사용자의 성장을 캐릭터의 성장으로 표현해<br/>
학습의 재미와 성장을 직관적으로 보여주는 앱 입니다

[![App Store](https://img.shields.io/badge/App%20Store-다운로드-0D96F6?logo=appstore&logoColor=white)](https://apps.apple.com/kr/app/%EB%8B%A8%EC%96%B4%EA%B3%A0%EC%B9%98/id6753820016)

</div>

---

- **핵심 개발**: 2025.09–2025.10
- **유지보수**: 2025.10–현재
- **개발 인원**: 1인 개발
- **최소 지원 버전**: iOS 16.0

---

## 스크린샷

### 온보딩

| 관심사 선택 | 배경 테마 선택 | 알 선택 |
|:---:|:---:|:---:|
| <img src="https://github.com/user-attachments/assets/cd975405-940f-4be7-83d5-fd3ebacd9b9c" width="260" alt="관심사 선택 온보딩 화면"> | <img src="https://github.com/user-attachments/assets/33212c73-f934-4c6f-b846-2b8775a741db" width="260" alt="배경 테마 선택 화면"> | <img src="https://github.com/user-attachments/assets/91b1efe8-c8e9-4ef1-91c9-99bafc364b34" width="260" alt="알 선택 화면"> |

### 학습

| 단어 탐색 | 4지선다 퀴즈 | 학습 결과 |
|:---:|:---:|:---:|
| <img src="https://github.com/user-attachments/assets/dfbe3b41-ac8a-45c3-9595-dab04d990c19" width="260" alt="단어 탐색 화면"> | <img src="https://github.com/user-attachments/assets/8f297a7e-ae9b-4a54-8c68-470d5c56d940" width="260" alt="4지선다 퀴즈 학습 화면"> | <img src="https://github.com/user-attachments/assets/5ac4449f-c941-4458-a643-12e83485be15" width="260" alt="학습 결과 화면"> |

### 단어장

| 추천 단어장 | 단어 추가 | 단어장 상세 |
|:---:|:---:|:---:|
| <img src="https://github.com/user-attachments/assets/c38f2c08-a882-448b-a0af-c0b0a578b949" width="260" alt="추천 단어장 화면"> | <img src="https://github.com/user-attachments/assets/e1ac0708-e066-4d38-a2c6-7acf1eec94b6" width="260" alt="단어 추가 화면"> | <img src="https://github.com/user-attachments/assets/48a52402-3975-4a06-b7cb-db45dd116685" width="260" alt="단어장 상세 화면"> |

### 캐릭터

<table>
  <thead>
    <tr>
      <th align="center">캐릭터 화면</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td align="center">
        <img
          src="https://github.com/user-attachments/assets/b499d18b-52af-4c46-bb27-679fea5628e8"
          width="260"
          alt="캐릭터 관리 화면"
        >
      </td>
    </tr>
  </tbody>
</table>

---
## 핵심 기능

### 1. 테마 설정
* Unsplash 사진 검색으로 배경 테마 설정

### 2. 단어장

* Core Data 기반 커스텀 단어 CRUD
* 추천 단어장의 단어를 `sourceWordId`로 Core Data에 저장
  — 원본을 복사해 나의 단어장에 넣고, 복사본에 원본 id를 남겨 원본–사본을 연결
* 학습중 단어장 전환 (앱 전체에 항상 1개)

### 3. 단어 탐색

* 쇼츠·릴스 형태의 세로 무한 스크롤
* Core Data 기반 단어별 학습 히스토리를 조회해 학습 횟수와 정답률 표시
*  SwiftUI로 포팅한 단어 카드 UI
* TTS 발음 재생

### 4. 4지선다 퀴즈

* P2C(Power of Two Choices) 알고리즘으로 학습중 단어장에서 출제 단어 선정
* 전수 정렬 없이 O(n) 선정, 매번 다른 문제 구성 유지
* 진행률 표시 및 정답/오답 즉시 피드백

### 5. 학습 결과

* 정답/오답 수와 획득 경험치 요약
* 전 문제 정답 시 보너스 경험치
* 틀린 문제만 다시 풀기 / 이어서 학습하기

### 6. 캐릭터 육성

* 포만감, 갈증, 즐거움, 청결 4수치 돌보기 기능
* 돌봄 수치 기반 기분 9종 표시
* 체력(HP) 관리, 사망 및 부활
* 학습 경험치로 수동 레벨업 (최고 Lv.7)
* 앱 종료 중 흐른 시간을 재실행 시 일괄 정산
* 스프라이트 시트 기반 픽셀 아트 애니메이션

### 7. 날씨 연동 배경

* 현재 위치(CoreLocation)로 OpenWeatherMap 현재 날씨를 조회
* 날씨 상태 코드를 `WeatherType` 7종(뇌우·가랑비·비·눈·안개 등 대기 현상·맑음·구름)으로 환산
* 캐릭터와 같은 스프라이트 시트 방식으로, 날씨에 해당하는 행만 골라 배경을 애니메이션
* 위치 거부·네트워크 실패 시 기본 배경(맑음)을 유지하고 화면을 막지 않음
* 화면 진입과 앱 복귀 때 갱신하며, 진행 중 요청이 있으면 중복 호출하지 않음

---

## 아키텍처

### Clean Architecture + MVVM-C
<img
src="https://github.com/user-attachments/assets/7ea73cbc-8d82-41c5-ab61-20e87a2ef9e5"
width="260"
alt="앱 아미텍처 구조도">


```mermaid
graph TD
    subgraph APP["App · 조립과 화면 전환"]
        DI[AppDIContainer]
        CO[Coordinator]
    end

    subgraph FEATURE["Feature · 화면 12종"]
        VC[ViewController]
        VM[ViewModel<br/>Input · Output]
    end

    subgraph SHARED["Shared · 도메인과 데이터"]
        UC[UseCase · Policy]
        EN[Entity]
        IF[Repository 프로토콜]
        RP[Repository 구현]
        MP[Mapper]
        DS[DesignSystem 토큰]
    end

    subgraph CORE["Core · 공통 기반"]
        CD[(CoreData)]
        NW[Network · URLSession]
        LG[AppLogger · OSLog]
    end

    CO --> VC
    DI -. 주입 .-> VM
    VC --> VM
    VC --> DS
    VM --> UC
    UC --> EN
    UC --> IF
    RP -. 구현 .-> IF
    RP --> MP
    RP --> CD
    RP --> NW
    MP --> EN
```

### 디렉토리

```
Danogotchi/
├── App/           앱 진입점 · AppDIContainer · Coordinator 계층
├── Core/          BaseViewController · CoreDataStack · 네트워크 · AppLogger
├── Shared/
│   ├── Domain/    Entity · Repository 프로토콜 · UseCase · Policy
│   ├── Data/      Repository 구현 7종 · Mapper · CoreData 모델 · 추천 단어 시드
│   └── DesignSystem/  색 · 폰트 · 여백 토큰과 공통 컴포넌트
└── Feature/       Feature 폴더 11개 (View / ViewModel / Components / Coordinator)
```

## 핵심 아키텍처 패턴

### Clean Architecture
  - App / Core / Shared / Feature 4계층 분리, 의존 방향은 `Feature → Shared → Core` 단방향이며 Feature 간 화면 연결은 Coordinator에서 수행

### MVVM-C (Input/Output)
- 모든 ViewModel이 `BaseViewModel` 프로토콜의 `transform(input:) -> Output`을 구현해 입력과 출력을 한 함수에 고정

### RxSwift 단방향 바인딩
- Input은 `Observable`, Output은 `Driver`/`Signal`로 노출해 UI 스레드와 에러 처리를 타입으로 강제

### Coordinator 패턴 
- 모든 화면 전환을 `Coordinator`가 담당(`AppFlowCoordinator` → `MainCoordinator` / `OnboardingCoordinator` → Feature별 Coordinator), VC 직접 push 금지, VC ↔ Coordinator는 delegate로 통신

### UseCase 레이어
- 비즈니스 규칙을 `AddVocabUseCase`, `StartQuizUseCase`, `CarePetUseCase`, `EarnExperienceUseCase` 등으로 분리하고, 정책은 `PetStatePolicy` · `PetLevelPolicy` · `ExperiencePolicy`에 상수까지 모아 테스트 가능하게 유지
- Repository 접근이 필요한 ViewModel은 UseCase 프로토콜을 경유하며, UI 상태 로직과 상태 없는 Domain Policy에는 형식적인 UseCase를 만들지 않음

### Repository 패턴 + DIP
- `Shared/Domain/Interfaces`의 프로토콜과 `Shared/Data/Repositories`의 구현을 분리해 Domain이 CoreData·네트워크를 모르게 구성

### 의존성 주입
- `AppDIContainer`가 팩토리 메서드로 UseCase·ViewModel을 조립하고 조립은 App 계층에서만 수행. 단일 인스턴스가 필요한 Repository(활성 단어장 신호, 펫 1마리 불변식)는 컨테이너가 `lazy`로 보유

### Router 패턴 
- `UnsplashApiRouter` · `WeatherApiRouter`가 `Endpoint`를 구현하고, `DefaultApiClient`가 URLSession과 async/await로 요청을 실행

### 디자인 시스템 토큰화
- `AppColor` · `AppFont` · `AppSpacing` · `AppRadius` 토큰과 공용 컴포넌트를 `Shared/DesignSystem`에 모아 UIKit·SwiftUI 양쪽에서 공유

### 데이터 플로우 
- View → ViewModel → UseCase → Repository → CoreData 동기 저장 성공 → 변경 신호(Relay) 방출 → 구독 측 재조회. 저장 실패는 롤백 후 화면에 전달하며, 성공한 작업만 UI 갱신과 화면 전환으로 연결

### 테스트: 
- 정책·UseCase·ViewModel·영속화·네트워크 테스트 154개 (`PetStatePolicyTests`, `VocabUseCaseTests`, `PetPersistenceTests` 등)

---

## 데이터 흐름

### 퀴즈 정답 → 경험치 적립

```mermaid
sequenceDiagram
    participant V as QuizViewController
    participant VM as QuizViewModel
    participant UC as EarnExperienceUseCase
    participant H as LearningHistoryRepository
    participant P as PetRepository

    V->>VM: 보기 선택
    VM->>UC: record 호출
    UC->>H: 이 단어의 이전 정답률 조회
    Note over UC: 이력 반영 전 값으로 경험치 산정
    UC->>H: 학습 이력 저장
    UC-->>VM: 이번 문제 획득 경험치
    VM->>UC: commit · 만점 보너스 합산
    UC->>P: 캐릭터 경험치 적립
    VM-->>V: 학습 완료 화면으로 이동
```

### 캐릭터 상태 정산

화면을 열거나 앱으로 돌아온 순간, 마지막 정산 시각과의 차이를 계산해 한 번에 반영후 저장

```mermaid
flowchart LR
    A[화면 진입 · 앱 복귀 · 돌보기] --> B[경과 시간 계산<br/>현재 시각 − 마지막 정산 시각]
    B --> C[돌봄 4수치 감소]
    C --> D{수치 구간 판정}
    D -- 모두 65 초과 --> E[체력 회복<br/>시간당 +0.5]
    D -- 20 이하가 있음 --> F[체력 감소<br/>수치 1개당 시간당 −0.25]
    D -- 그 외 --> G[체력 유지]
    E --> H{체력이 0 이하인가}
    F --> H
    G --> H
    H -- 예 --> I[사망 · 부활 필요]
    H -- 아니오 --> J[기분 계산]
    I --> K[CoreData 저장<br/>정산 시각 갱신]
    J --> K
    K --> L[화면 갱신]
```

---

## 주요 기술

### RxSwift / RxCocoa
* ViewModel은 `Input` / `Output` 구조체와 `transform(input:)` 단일 진입점을 갖습니다.
* 외부에는 `Driver` · `Signal`로 노출해 메인 스레드 실행을 보장합니다.

### Swift Concurrency

* 원격 I/O 경로만 `async`/`await`로 씁니다 — `DefaultApiClient`(URLSession) → `DefaultWeatherRepository` · `DefaultSearchThemeRepository` · `DefaultThemeImageRepository` → `FetchCurrentWeatherUseCase` · `SearchThemeUseCase`. `ApiClient`와 `Endpoint`는 `Sendable`입니다.
* Core Data 경로는 동기 `throws`를 유지합니다. "저장 성공 이후에만 변경 신호를 방출한다"는 불변식이 동기 저장에 기대고 있어, 바꿀 이유가 없는 곳을 바꾸지 않았습니다.
* **Rx ↔ async 경계를 한 곳에 고정**했습니다. `DefaultThemeImageRepository.replace`가 `Single.create` 안에서 `Task`를 띄우고, dispose되면 `task.cancel()`로 취소를 전달하며, 오류는 `Result`로 감싸 구독이 끊기지 않게 합니다.
* **델리게이트 → async**: `DeviceLocationProvider`가 `withCheckedThrowingContinuation`으로 `CLLocationManager` 1회 조회를 `async` 함수로 바꿉니다. 이중 resume과 동시 요청을 막고(`LocationError.requestInProgress`), `@MainActor final class` + `nonisolated override init()`으로 DI 조립부는 메인 격리 밖에 둡니다. 델리게이트 채택은 `@preconcurrency`입니다.
* **취소를 기능으로 씁니다.** 테마 검색은 `searchTask`를 새 검색과 `deinit`에서 취소하고 `Task.isCancelled` · `CancellationError`를 걸러 낡은 응답이 화면을 덮지 않게 합니다. 이미지 포맷 폴백 루프는 `Task.checkCancellation()`으로 다음 포맷 시도를 멈추고, 셀 썸네일은 `prepareForReuse`에서 취소합니다.
* 메인 스레드에서 내보내는 작업은 이미지 디코딩 하나입니다 — `Task.detached(priority: .userInitiated)`로 돌리고 결과 적용만 `@MainActor`에서 합니다.
* 현재 Swift 5 언어 모드입니다. 싱글턴 `CoreDataStack.viewContext`가 DI로 흐르는 구조라 strict concurrency를 켜려면 격리 설계가 먼저 필요해, 앱 코드에는 `actor`를 도입하지 않았습니다. 테스트에서는 `actor` 더블(`ControlledSearchRepository` 등)로 응답 순서를 결정적으로 만듭니다.

### Coordinator
* `AppFlowCoordinator` → `MainCoordinator` / `OnboardingCoordinator` → 화면별 Coordinator 계층입니다.
* 온보딩 완료 여부에 따른 첫 화면 분기도 여기서 결정합니다.

### CoreData
* 엔티티 4종(`VocabEntity` · `VocabBookEntity` · `LearningHistoryEntity` · `PetEntity`)을 사용합니다.
* `Mapper`의 `toDomain()`과 필요한 모델의 `apply(_:)`가 엔티티와 도메인 모델을 변환해 도메인 코드가 `NSManagedObject`를 모릅니다.
* 네트워크 DTO는 `toEntity()`로 Domain Model에 변환하며, 읽기 전용 흐름에 사용하지 않는 `toDTO()`는 만들지 않습니다.

### 배경 테마 이미지 — Kingfisher 제거 후 직접 구현

* **Before** — Kingfisher가 다운로드·디코딩·캐싱을 모두 맡았습니다. 원본 해상도를 그대로 받아 디코딩했고, 내려받는 크기·저장 포맷·디코딩 시점을 제어할 지점이 없었습니다.
* **After** — `URLSession`(`ApiClient.data(from:)`) · `ImageIO` · `ImageFileStorage`로 단계를 나눠 직접 구현하고 외부 이미지 라이브러리 의존성을 제거했습니다.

**내려받기 — 크기는 서버에서 맞춥니다**

* Unsplash 이미지 CDN에 `w`·`h`를 `UIScreen.main.nativeBounds` 픽셀로, `fit=crop&crop=center&q=85`로 요청합니다. 기기가 `scaleAspectFill`로 하던 센터 크롭을 서버가 미리 해주므로 전송량과 디코딩 메모리가 같이 줄고 업스케일이 없습니다.
* 포맷은 HEIC → WebP 순으로 시도합니다. CDN은 `fm`을 못 알아들어도 200에 다른 포맷을 주기 때문에 **상태 코드로는 판정할 수 없습니다.** `ImageDecoder.validate(_:)`가 `CGImageSourceGetType`으로 실제 바이트의 타입을 읽고 64px 썸네일까지 뽑아 디코딩 가능함을 확인한 뒤, 저장 확장자를 그 결과에서 가져옵니다.

**저장 — 로컬 파일로 보관합니다**

* `ImageFileStorage`가 `Library/Application Support/ThemeImage/`에 `UUID + 실제 확장자` 이름으로 `.atomic` 쓰기 후 `isExcludedFromBackup`을 세웁니다. URL이 내려가거나 오프라인이어도 배경이 유지됩니다.
* UserDefaults에는 절대 경로가 아니라 **파일명만** 둡니다. 재설치·복원으로 컨테이너 경로가 바뀌어도 파일을 다시 찾습니다.
* 순서가 불변식입니다 — 새 파일을 커밋한 **뒤** `removeAllExcept(fileName:)`로 이전 파일을 정리합니다. 다운로드가 실패해도 기존 배경을 잃지 않고, 중간에 앱이 죽어도 남은 파일은 다음 저장 때 함께 치워집니다.
* 파일이 사라졌으면 `ObserveThemeUseCase`가 저장해둔 원본 URL로 다시 받아 스스로 복구합니다.

**표시 — ImageIO 다운샘플 디코딩**

* `ImageDecoder.decode(fileURL:maxPixelSize:)`가 `CGImageSourceCreateThumbnailAtIndex`로 **화면 높이 픽셀까지만** 디코딩합니다. 전체 비트맵을 메모리에 펼치지 않습니다.
* 디코딩은 `Task.detached(priority: .userInitiated)`에서 끝내고 메인에서는 크로스 디졸브만 합니다. 같은 파일이면 건너뛰고, 새 이미지가 오면 직전 디코딩을 취소합니다.
* 확장자가 아니라 내용으로 포맷을 판별하므로 HEIC·WebP·JPEG 어느 것이 저장돼 있든 같은 경로로 동작합니다.

**테마 검색 그리드**

* 썸네일(`urls.small`)은 `RemoteImageLoader`가 `URLSession` + `NSCache`로 메모리에만 올립니다. 디스크에 쓰지 않고, 셀 재사용 시 `prepareForReuse`에서 요청을 취소하며, 캐시에 있으면 동기로 꺼내 빈 칸이 깜빡이지 않게 합니다.

### DiffableDataSource
* 단어 카드·단어장·테마 목록에 사용합니다.
* 테마 검색 화면은 높이가 제각각인 사진을 위해 워터폴 레이아웃(`WaterFallLayout`)을 직접 구현했습니다.

### SwiftUI 부분 도입
* 단어 카드의 블러 레이어만 SwiftUI로 구현.
* `UIHostingController`로 UIKit에 SwiftUI 포팅.

### 디자인 시스템
* 색·폰트·여백·모서리 반경을 토큰(`AppColor` · `AppFont` · `AppSpacing` · `AppRadius` · `AppBorder`)으로 고정했습니다.
* 화면 코드에 색상값과 폰트 크기를 직접 쓰지 않습니다.

### OSLog
* `AppLogger` 5개 카테고리로 분류합니다.
* subsystem이 번들 ID라 개발용과 운영용 로그가 Console에서 자동으로 분리됩니다.

### XCTest
* 정책·UseCase·ViewModel·영속화·네트워크 테스트 **154개**를 운영합니다.

### 빌드 설정
* `xcconfig`로 개발용·운영용 스킴을 분리했습니다.
* 번들 ID, 앱 이름, 스킴에 따라 자동으로 바뀝니다.

---

## 테스트

정책·UseCase·ViewModel·영속화·네트워크 테스트 **154개**를 운영합니다.

| 파일 | 검증 내용 |
|---|---|
| `PetStatePolicyTests` (34) | 시간 경과, 돌보기, 체력 구간, 사망·부활 |
| `PetPersistenceTests` (22) | 펫 UseCase·Repository 동작, 경험치 적립 실패 전달 |
| `PetLevelPolicyTests` (7) · `PetHeartPolicyTests` (7) · `PetNamePolicyTests` (7) | 레벨·하트 표시·이름 정책 |
| `PetSpriteTests` (13) · `PetTypeTests` (2) · `WeatherSpriteTests` (8) | 스프라이트 리소스·격자·애니메이션 구성 |
| `VocabUseCaseTests` (3) · `StudyReminderPolicyTests` (4) | 단어 조회 조립·변경 신호·알림 일정 |
| `SearchThemeViewModelTests` (6) | 검색 응답 순서·요청 취소·페이지 재시도 |
| `PersistenceFailureTests` (8) | 저장 실패 롤백, 생성·삭제·활성 전환·이력·경험치·시드 재시도 |
| `PersistenceViewModelTests` (5) | 실패 시 폼·목록 유지, 완료 이벤트 차단, 다음 입력으로 복구 |
| `SQLitePersistenceTests` (2) | SQLite 저장소 재개방 후 데이터·삭제 결과 확인 |
| `QuizUseCaseTests` (5) · `QuizViewModelTests` (6) | 출제 경계·채점·경험치·실패한 저장만 재시도 |
| `ApiClientTests` (6) | URLSession 요청 구성·JSON·HTTP 오류·원시 바이트 |
| `ThemeImagePersistenceTests` (6) | 이미지 교체, 포맷 요청 대체, 실패 시 기존 파일 보존 |
| `WeatherUseCaseTests` (3) | 좌표 전달·위치 조회 실패·날씨 요청 실패 |
