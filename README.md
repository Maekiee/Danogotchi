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
          src="https://github.com/user-attachments/assets/1571ce05-7d56-4e84-a14f-3572c58e69b3"
          width="260"
          alt="캐릭터 관리 화면"
        >
      </td>
    </tr>
  </tbody>
</table>

---
## 핵심 기능

### 1. 테마 설젙
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

---

## 아키텍처

### Clean Architecture + MVVM-C

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
        NW[Network · Alamofire]
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
    MP --> CD
    RP --> NW
```

### 디렉토리

```
Danogotchi/
├── App/           앱 진입점 · AppDIContainer · Coordinator 계층
├── Core/          BaseViewController · CoreDataStack · 네트워크 · AppLogger
├── Shared/
│   ├── Domain/    Entity · Repository 프로토콜 · UseCase 16개 · Policy 4개
│   ├── Data/      Repository 구현 5종 · Mapper · CoreData 모델 · 추천 단어 시드
│   └── DesignSystem/  색 · 폰트 · 여백 토큰과 공통 컴포넌트
└── Feature/       화면 단위 폴더 12개 (View / ViewModel / Components / Coordinator)
```

## 핵심 아키텍처 패턴

### Clean Architecture*
  - App / Core / Shared / Feature 4계층 분리, 의존 방향은 `Feature → Shared → Core` 단방향이며 Feature 간 참조 없음

### MVVM-C (Input/Output)
- 모든 ViewModel이 `BaseViewModel` 프로토콜의 `transform(input:) -> Output`을 구현해 입력과 출력을 한 함수에 고정

### RxSwift 단방향 바인딩
- Input은 `Observable`, Output은 `Driver`/`Signal`로 노출해 UI 스레드와 에러 처리를 타입으로 강제

### Coordinator 패턴 
- 모든 화면 전환을 `Coordinator`가 담당(`AppFlowCoordinator` → `MainCoordinator` / `OnboardingCoordinator` → Feature별 Coordinator), VC 직접 push 금지, VC ↔ Coordinator는 delegate로 통신

### UseCase 레이어
- 비즈니스 규칙을 `AddVocabUseCase`, `StartQuizUseCase`, `CarePetUseCase`, `EarnExperienceUseCase` 등으로 분리하고, 정책은 `PetStatePolicy` · `PetLevelPolicy` · `ExperiencePolicy`에 상수까지 모아 테스트 가능하게 유지

### Repository 패턴 + DIP
- `Shared/Domain/Interfaces`의 프로토콜과 `Shared/Data/Repositories`의 구현을 분리해 Domain이 CoreData·네트워크를 모르게 구성

### 의존성 주입
- `AppDIContainer`가 팩토리 메서드로 UseCase·ViewModel을 조립하고 조립은 App 계층에서만 수행. 단일 인스턴스가 필요한 Repository(활성 단어장 신호, 펫 1마리 불변식)는 컨테이너가 `lazy`로 보유

### Router 패턴 
- `ApiRouter` enum이 엔드포인트·메서드·파라미터를 한곳에서 정의하고 `ApiService`가 실행 (Alamofire)

### 디자인 시스템 토큰화
- `AppColor` · `AppFont` · `AppSpacing` · `AppRadius` 토큰과 공용 컴포넌트를 `Shared/DesignSystem`에 모아 UIKit·SwiftUI 양쪽에서 공유

### 데이터 플로우 
- View → ViewModel → UseCase → Repository → CoreData 동기 저장 → 변경 신호(Relay) 방출 → 구독 측 재조회. 저장이 먼저이고 UI 갱신은 신호 기반 재조회로 처리

### 테스트: 
- 정책·영속화 계층 중심 단위 테스트 90개 (`PetStatePolicyTests`, `PetPersistenceTests` 등)

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

### Coordinator
* `AppFlowCoordinator` → `MainCoordinator` / `OnboardingCoordinator` → 화면별 Coordinator 계층입니다.
* 온보딩 완료 여부에 따른 첫 화면 분기도 여기서 결정합니다.

### CoreData
* 엔티티 4종(`VocabEntity` · `VocabBookEntity` · `LearningHistoryEntity` · `PetEntity`)을 사용합니다.
* `Mapper`가 엔티티와 도메인 모델을 변환해 도메인 코드가 `NSManagedObject`를 모릅니다.

### Alamofire + Kingfisher
* Unsplash 사진 검색(`ApiRouter`)을 담당합니다.
* 이미지 다운로드와 캐싱을 처리합니다.

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
* 도메인 정책 단위 테스트 **76개**를 운영합니다.

### 빌드 설정
* `xcconfig`로 개발용·운영용 스킴을 분리했습니다.
* 번들 ID, 앱 이름, 스킴에 따라 자동으로 바뀝니다.

---

## 테스트

도메인 정책 단위 테스트 **76개**를 운영합니다.

| 파일 | 검증 내용 |
|---|---|
| `PetStatePolicyTests` (34) | 시간에 따른 수치 감소, 돌보기 경계, 기분 판정 우선순위, 체력 구간별 정산, 사망·부활 페널티 |
| `PetPersistenceTests` (21) | UseCase와 CoreData 저장 왕복, 레벨업·부활·경험치 적립의 실제 저장 결과 |
| `PetLevelPolicyTests` (7) | 레벨별 요구 경험치, 게이지 진행률, 최고 레벨 처리, 경험치 이월 없음 |
| `PetHeartPolicyTests` (7) | 체력의 하트 10칸 표시 변환 |
| `PetNamePolicyTests` (7) | 캐릭터 이름 입력 규칙 |
