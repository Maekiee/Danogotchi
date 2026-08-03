# 아키텍처

기존 MVVM + Repository 구조를 **Clean Architecture + MVVM-C (Input/Output) + RxSwift** 로 전면 교체하는 중이다.
멀티모듈·TCA 전환(장기 목표)을 대비해 **App / Core / Shared / Feature** 구조로 디렉토리 개편 완료(2026-07). UseCase 도입 등 코드 레벨 이관은 점진적으로 진행한다.

## 레이어 구조 (디렉토리)

핵심 두 가지:
1. **`Shared/Domain/Interfaces`(프로토콜)와 `Shared/Data/Repositories`(구현)의 분리** — 의존성 역전(DIP)으로 Domain이 외부 의존성을 모른다.
2. **의존 방향은 `Feature → Shared → Core` 한 방향**, 조립(구현체 주입)은 `App`에서만 한다. Feature는 다른 Feature를 참조하지 않는다.

> **배치 규칙**: 도메인 조각·UI가 **2개 이상 Feature에서 쓰이면 `Shared/`**, 정확히 1개 Feature 전용이면 **그 Feature 폴더 안**(예: `Feature/Quiz/Components/CustomProgressView`)에 둔다.
>
> **UseCase 레이어**(`Shared/Domain/UseCases/`)는 필요한 순간에만 추가한다. 처음부터 일괄 도입하지 않고, **비즈니스 규칙이 복잡해져 ViewModel에서 분리가 필요한 순간에 만든다**.

## MVVM-C / Coordinator
- 모든 화면 전환은 `Coordinator` 프로토콜을 통해 수행된다 (직접 `pushViewController` 금지).
- 계층: `AppFlowCoordinator` → `MainCoordinator` / `OnboardingCoordinator` → 각 `Feature*Coordinator`.
- VC ↔ Coordinator 통신은 **delegate 패턴** (`*ViewControllerDelegate`).
- 자식 코디네이터는 `addChild` / `removeChild`로 생명주기 관리.

> 네이밍 / ViewModel(Input-Output) / Rx / Repository / DI 세부 컨벤션은 `docs/conventions.md` 참조.

## 마이그레이션 정책 (메모리 기록 일치)
- 기존 코드 위치를 기준으로 "어디에 둘지" 고민하지 않는다.
- 클린아키텍처 설계를 먼저 확정하고, 거기에 맞지 않는 코드는 수정 또는 삭제.
- 필요한 레이어/파일이 없으면 새로 추가, 잘못된 위치의 코드는 과감히 제거.

# 도메인 컨텍스트

## 핵심 비즈니스 용어 (Domain Model)

### 단어 (Word)
- 위치: `Shared/Domain/Entities/Vocab.swift`
- 학습 단위. 필드: `id / word / meaning / createAt`

### 단어장 (WordBook)
- 위치: `Shared/Domain/Entities/VocabBook.swift`
- 단어 묶음. 필드: `id / title / wordList / createAt`

### 나의 단어장
- 식별: `title == "나의 단어장"` 매직 스트링
- 사용자가 직접 추가하는 기본 단어장. 분기 로직의 핵심 식별자.

### 추천 단어장
- 위치: `RecommendBookRepository`
- 큐레이션된 외부 단어장 (Firestore 등).

### 활성 단어장
- 위치: `UserInfoManager.activeBookIdentifier`
- 현재 학습 대상으로 선택된 단어장 (id + 타입: 내것/추천).

### 학습 이력
- 위치: `Shared/Domain/Entities/LearningHistory.swift`
- 단어별 정/오답 기록. 정답률(accuracy) 산출 근거.

### 퀴즈
- 위치: `Feature/Quiz`
- 활성 단어장으로부터 생성되는 학습 세션.

### 테마 (Theme)
- 위치: `SearchThemeRepository`
- 메인 화면 배경(이미지 URL). 사용자 프로필에 저장.

### CreateWord
- 위치: `Shared/Domain/Entities/CreateVocab.swift`
- 단어 등록/편집 시점의 입력 DTO.

## 핵심 데이터 흐름 (Write 패스)

낙관적 갱신(Optimistic Update) — UI 먼저 갱신 후 영속화. 활성 단어장에 영향이 가면 `clearQuizState()` 등 부수효과를 처리한다.

## 전역 상태 / 싱글턴

- `UserInfoManager` — UserDefaults: 사용자 프로필, 활성 단어장 ID/타입, 테마 URL, 퀴즈 진행 상태
- `ActiveLearningManager` — 현재 학습 세션의 반응형 상태 (Rx 기반)
- `TTSManager` — AVSpeechSynthesizer 래퍼 (단어 발음)

> 싱글턴 직접 참조는 점진적으로 줄여나가는 중. 신규 코드는 가능하면 **AppDIContainer를 통한 주입** 또는 Repository 의존성으로 우회한다.

