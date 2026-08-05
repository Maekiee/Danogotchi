# 아키텍처

기존 MVVM + Repository 구조를 **Clean Architecture + MVVM-C (Input/Output) + RxSwift** 로 전면 교체하는 중이다.
멀티모듈·TCA 전환(장기 목표)을 대비해 **App / Core / Shared / Feature** 구조로 디렉토리 개편 완료(2026-07). UseCase 도입 등 코드 레벨 이관은 점진적으로 진행한다.

## 레이어 구조 (디렉토리)

핵심 두 가지:
1. **`Shared/Domain/Interfaces`(프로토콜)와 `Shared/Data/Repositories`(구현)의 분리** — 의존성 역전(DIP)으로 Domain이 외부 의존성을 모른다.
2. **의존 방향은 `Feature → Shared → Core` 한 방향**, 조립(구현체 주입)은 `App`에서만 한다. Feature는 다른 Feature를 참조하지 않는다.

> **배치 규칙**: 도메인 조각·UI가 **2개 이상 Feature에서 쓰이면 `Shared/`**, 정확히 1개 Feature 전용이면 **그 Feature 폴더 안**(예: `Feature/Quiz/Components/CustomProgressView`)에 둔다.
>
> **UseCase 레이어**(`Shared/Domain/UseCases/`)는 도입 진행 중(현재 7개). 처음부터 일괄 도입하지 않고, **비즈니스 규칙이 복잡해져 ViewModel에서 분리가 필요한 순간에 만든다**.

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

### 단어 (Vocab)
- 위치: `Shared/Domain/Entities/Vocab.swift`
- 학습 단위. 필드: `id / word / meaning / bookType / level / partOfSpeech / sourceWordId / createAt`
- `sourceWordId`: 추천 단어를 복사해 저장한 단어면 원본 id, 직접 추가한 단어는 nil.

### 단어장 (VocabBook)
- 위치: `Shared/Domain/Entities/VocabBook.swift`
- 단어 묶음. 필드: `id / title / bookType / level / vocabList / isActive / createAt`

### 단어장 종류 (BookTopic)
- 위치: `Shared/Domain/Entities/BookTopic.swift`
- `myBook`(나의 단어장) / `travel` / `emotion` / `life` / `business`.
- **분기는 항상 `bookType == .myBook`으로 한다. 제목 문자열 비교 금지.**

### 추천 단어장
- 첫 실행 시 `Shared/Data/DatabaseSeeder.seedIfNeeded`가 `MockData/RecommendBooks.swift`를 CoreData에 시드한다 (로컬, 원격 아님).
- 추천 단어를 나의 단어장에 담으면 복사본이 생기고 원본 id는 `Vocab.sourceWordId`에 남는다.

### 활성 단어장 (학습중 단어장)
- 저장: `VocabBookEntity.isActive` — 앱 전체에서 **항상 1개**. `setActiveBook(id:)`가 같은 트랜잭션에서 기존 것을 해제한다.
- 읽기: `VocabBookRepository.readActiveBook()` / 변경 신호: `activeBookId: Observable<UUID?>`
- **신호는 값 캐시가 아니다** — 신호를 받으면 `readActiveBook()`으로 다시 읽는다.

### 학습 이력
- 위치: `Shared/Domain/Entities/LearningHistory.swift`
- 단어별 정/오답 기록. 정답률(accuracy) 산출 근거.

### 퀴즈
- 위치: `Feature/Quiz`
- 활성 단어장으로부터 생성되는 학습 세션.

### 테마 (Theme)
- 조회: `SearchThemeRepository` → Unsplash REST (`Core/Network/ApiRouter.searchPhoto`).
- 선택 결과 URL은 `UserInfoManager.currentThemeUrl`에 저장된다. 메인 화면 배경으로 쓰인다.

## 핵심 데이터 흐름 (Write 패스)

UseCase → Repository → CoreData 동기 저장 → `activeBookId` 등 Relay 신호 방출 → 구독 측이 재조회.
즉 **저장이 먼저, UI 갱신은 신호 기반 재조회**다.

## 전역 상태 / 싱글턴

- `UserInfoManager` — UserDefaults: `username` / `userId`(미사용) / `themeUrl` 만. 활성 단어장·퀴즈 상태는 여기 없다(CoreData로 이관됨).
- `TTSManager` — AVSpeechSynthesizer 래퍼 (단어 발음)

> 싱글턴 직접 참조는 점진적으로 줄여나가는 중. 신규 코드는 가능하면 **AppDIContainer를 통한 주입** 또는 Repository 의존성으로 우회한다.

