# TODO — 학습하기 재설계 (활성 단어장 기반 출제)

> **이전 스프린트**(Realm → CoreData 전환)는 완료되었다. 기록은 문서 하단
> [완료 아카이브](#완료-아카이브--realm--coredata-전환-스프린트) 참조.

## 스프린트 목표

단어장 상세에서 "학습하기"를 누르면 그 단어장이 **학습중 단어장**이 되고, 학습중 단어장을
기반으로 문제를 생성하는 구조로 학습 흐름을 재설계한다.

**변경 정책**
- 이어하기 학습 삭제 — 학습하기는 항상 새 세션으로 시작한다
- 학습중 단어장은 앱 전체에서 항상 **1개**
- 단어 20개 이하: 전체를 셔플해 출제 / 20개 초과: 학습 이력 기반 가중 랜덤으로 20개 선정
- 학습을 중간에 종료해도 이미 푼 단어의 학습 카운트·정오답은 저장된다
- 학습중 단어장은 Explore 카드로 표시되고, 단어장 목록/상세에 "학습중"으로 표시된다

**진행률: A-1 / A-2 완료(`e0c744c`) · A-3 완료(`e9b71db`) · B-1 + B-2(일부) 완료(`365418e`) · 잔여 8장 17h**

> ⚠️ **A-3에서 CoreData 모델을 in-place 수정했다. 기존 스토어를 가진 기기는 앱 삭제 후
> 재설치해야 한다**(안 하면 `CoreDataStack.swift:14` 의 `fatalError`). **팀원 기기도 동일.**
> A-1~A-3의 런타임 수동 검증은 아직 미실행 — 각 카드 하단 체크리스트 참조.

착수 순서: `B-2`(잔여) → `B-3` → `C-1` → `C-2` → `C-3` → `C-4` → `D-1` → `D-2`

---

## ✅ A-1. 이어하기(퀴즈 진행상태 복원) 제거 — 완료 · 2h

- [x] `UserInfoManager` — 퀴즈 상태 키 4개(`currentQuizWordIds`/`currentQuizIndex`/`currentCorrectCount`/`currentIncorrectWordIds`) + `clearQuizState()` 삭제
- [x] `QuizViewModel` — 진행상태 복원 생성자·중간 저장 제거, `currentIndex` 는 항상 0에서 시작, `userInfo` 싱글턴 참조 삭제
- [x] `ExploreVocabViewController` — 퀴즈 재개 분기 삭제. 빈 배열 가드와 `>= 4` 가드는 **유지**(`generateChoices` 가 오답 3개 필요)
- [x] `ActiveLearningManager` / `ToggleSaveVocabUseCase` / `DeleteVocabUseCase` — `clearQuizState()` 호출 3곳과 `clearQuizStateIfActive()` 메서드 2개 제거
- [x] **orphan 정리** — `DeleteVocabUseCase` 의존성 3개 → 1개(`vocabRepository` 만), `ToggleSaveVocabUseCase` 에서 `userInfo` 제거, `AppDIContainer` 팩토리 2곳 인자 축소
- [x] grep `currentQuiz|clearQuizState` 0건 · BUILD SUCCEEDED

> **이 카드는 isActive 재설계와 무관하므로 영구적으로 유효하다.**

## ✅ A-2. 활성 단어장 식별자 UUID 단일화 — 완료 · 3h

- [x] `UserInfoManager` — `ActiveBookType` / `ActiveBookIdentifier` / `selectedBookId` 삭제, `activeBookIdentifier` 를 `UUID?` 로, `Keys.activeBookType` 제거
- [x] `ActiveLearningManager` — `VocabularyBookType` / `activeBookSource` 삭제, `flatMapLatest` + switch → `map { $0.flatMap { repo.readBook(id: $0) } }`, `setActiveBook(_ book:)` 로 단순화 (57줄 → 33줄)
- [x] `SearchThemeViewController` — 온보딩의 `selectedBookId` 우회로를 `setActiveBook(book)` 호출로 교체. **`setActiveBook` 의 첫 실제 호출자가 생겼다**(이전까지 호출자 0건)
- [x] `ExploreVocabViewModel` — 미사용 변수 `activeBookSourceRelay` 삭제
- [x] grep `ActiveBookType|ActiveBookIdentifier|VocabularyBookType|selectedBookId` 0건 · BUILD SUCCEEDED

> **⚠️ 이 카드의 코드는 A-3에서 삭제된다.** 되돌리지 않는 이유: revert하면 삭제한 타입들이
> 부활해 A-3에서 다시 지워야 한다. 현재 상태는 A-3이 지울 대상을 `activeBookId` 키 하나로
> 줄여놓은 선행 작업이다.

### 남은 수동 검증 (미실행)

> A-3에서 같은 경로를 다시 건드렸으므로 **아래 검증은 A-3 완료 조건에 흡수**되었다.
> A-3 재설치 검증 시 함께 소화한다.

- [ ] 앱 삭제 후 재설치 → 온보딩 테마 선택 → Explore에 나의 단어장 카드가 표시된다
- [ ] 단어 4개 이상 추가 → 학습 2~3문제 후 X로 종료 → 다시 학습하기 시 **1번 문제부터** 시작
- [ ] Explore 카드의 학습 횟수/정답률에 방금 푼 기록이 반영된다
- [ ] 단어장 상세에서 단어 삭제/저장해제 → 크래시 없음 (UseCase 의존성 축소 확인)

---

## ✅ A-3. 활성 단어장을 CoreData `isActive` 필드로 이전 — 완료 · 커밋 `e9b71db` · 4h

> **왜**: 지금은 "활성 단어장 id는 UserDefaults, 단어장 실체는 CoreData"로 진실원본이 쪼개져
> 있다. 활성 단어장을 삭제하면 UserDefaults에 죽은 UUID가 남고 `readBook(id:)` 이 nil을
> 반환해 Explore가 조용히 빈 화면이 된다. 활성 여부는 단어장의 속성이므로 CoreData로 옮긴다.
>
> 얻는 것: 진실원본 1개(단어장 삭제 시 활성 상태도 함께 소멸) · "활성은 1개"가 저장 시점에
> 강제되는 스키마 불변식 · `ActiveLearningManager` 클래스 소멸

> **설계 변경(구현 시 확정)**: Relay에 `VocabBook` 값을 캐시하면 단어 추가/삭제가 반영되지 않으므로,
> Relay는 **변경 신호(`UUID?`)만** 나르고 읽기는 매번 `isActive == YES` 술어로 CoreData를 조회한다.
> 이로써 아래 "함께 고친 버그"가 해소된다.

### ✅ A-3-1. CoreData 모델
- [x] `Model.xcdatamodeld/Model.xcdatamodel/contents` 의 `VocabBookEntity` 에 속성 추가
  ```xml
  <attribute name="isActive" attributeType="Boolean" defaultValueString="NO" usesScalarValueType="YES"/>
  ```
- [x] `VocabBookEntity+CoreDataProperties.swift` 에 `@NSManaged public var isActive: Bool` 추가
- [x] `DatabaseSeeder` 는 **수정하지 않았다** — 기본값 NO로 시드되고 온보딩이 나의 단어장을 활성화한다

> **⚠️ 출시본 없음 확정 → in-place 수정함.** 모델 버전이 `Model.xcdatamodel` 하나뿐이고
> `.xccurrentversion` 도 없어 구버전 모델이 번들에 남지 않는다. 기존 스토어를 가진 기기는
> 마이그레이션 소스 모델을 못 찾아 `CoreDataStack.swift:14` 의 `fatalError` 로 죽는다.
> → **개발 기기·시뮬레이터 앱 삭제 후 재설치 필수. 팀원 기기도 동일.**

### ✅ A-3-2. 도메인 엔티티
- [x] `Shared/Domain/Entities/VocabBook.swift` 에 `let isActive: Bool` 추가 (B-2 배지가 소비)
- [x] `Shared/Data/Mappers/VocabBookMapper.swift` 의 `VocabBook(...)` 에 `isActive: isActive` 추가
  — **`VocabBook` 생성처는 이 Mapper 한 곳뿐**(grep 재확인 완료)

### ✅ A-3-3. Repository 확장
- [x] `Shared/Domain/Interfaces/Repositories/VocabBookRepository.swift` (+ `import RxSwift`)
  ```swift
  var activeBookId: Observable<UUID?> { get } /// 변경 신호. 내용은 readActiveBook()으로 다시 읽는다.
  func readActiveBook() -> VocabBook?
  func setActiveBook(id: UUID)
  ```
- [x] `Shared/Data/Repositories/DefaultVocabBookRepository.swift`
  - `private let activeBookIdRelay = BehaviorRelay<UUID?>(value: nil)` — init에서 1회 fetch로 채움
  - `private func fetchActiveBookEntities()` — 술어 `isActive == YES` (해제 시 잔여물까지 훑도록 fetchLimit 없음)
  - `setActiveBook(id:)` — 기존 활성 전부 해제 → 대상 지정 → `saveContext()` → Relay 갱신 (한 트랜잭션)
  - `deleteBook(id:)` — 삭제 전 `isActive` 확인 → 활성이었으면 Relay에 nil 방출
  - `ponytail: Relay 직접 갱신 — 앱 외부에서 DB가 바뀌는 경로가 생기면 NSFetchedResultsController로 교체`

### ✅ A-3-4. 단일 인스턴스 확보
- [x] `AppDIContainer` — `makeVocabBookRepository()` → `lazy var vocabBookRepository` 로 전환,
      호출 3곳 교체(`makeAddVocabUseCase` / `makeFetchVocabsUseCase` / `makeToggleSaveVocabUseCase`).
      무상태 repo 2종은 팩토리 그대로
- [x] `SearchThemeViewController` — `DefaultVocabBookRepository(...)` 직접 생성 제거
- [x] grep `DefaultVocabBookRepository(` → **DI 컨테이너 1곳만** 남음

### ✅ A-3-5. 삭제
- [x] **`Shared/Domain/ActiveLearningManager.swift` 파일 전체 삭제**
- [x] `UserInfoManager` — `activeBookIdentifier` / `activeBookIdentifierRelay` / `Keys.activeBookId` /
      `removeUserInfo()` 의 `activeBookIdentifier = nil` 삭제
      → `username` / `userId` / `currentThemeUrl` 전용 UserDefaults 래퍼로 축소.
      **`private init()` 은 빈 채로 유지** — 지우면 싱글턴 강제가 풀려 외부에서 생성 가능해진다
- [x] `AppDIContainer` — 주입된 적 없는 `activeLearningManager` 프로퍼티 삭제

### ✅ A-3-6. 소비처 교체
- [x] `ExploreVocabViewModel` — `vocabBookRepository` 생성자 주입, 트리거마다 `readActiveBook()` 재조회.
      미사용 프로퍼티 `userInfo` 도 제거(orphan 정리)
- [x] `SearchThemeViewModel.activateMyBook()` 신설(나의 단어장 조회 → 없으면 생성 → 활성 지정),
      `SearchThemeViewController.handleOnboardingSubmit` 은 이를 호출만 한다.
      두 코디네이터 모두 `makeSearchThemeViewModel(mode:)` 경유라 **코디네이터 수정 불필요**

### ✅ 함께 고친 기존 버그
- [x] `ExploreVocabViewModel` 의 `withLatestFrom(activeBookRelay)` 가 **stale `VocabBook` 스냅샷**을
      재사용해, 단어를 추가·삭제해도 `book.vocabList` 가 갱신되지 않던 문제
      → 트리거마다 CoreData 재조회로 해소

### 완료 조건
- [x] grep `ActiveLearningManager|activeBookIdentifier|Keys.activeBookId` **0건**
- [x] **BUILD SUCCEEDED** (커밋 `e9b71db`)
- [ ] 앱 삭제 재설치 → 온보딩 완료 → Explore에 나의 단어장 카드 표시
- [ ] 단어 추가 → Explore 목록에 **즉시 반영** (stale 스냅샷 수정 확인)
- [ ] 설정 → 테마 변경 시 테마만 바뀌고 활성 단어장 유지 (`.settings` 경로 회귀 없음)
- [ ] `ZISACTIVE = 1` 인 레코드가 정확히 1개
- [ ] 활성 단어장 삭제 경로는 **`deleteBook` 호출처가 0곳**이라 UI 재현 불가 — 코드 리뷰로 대체

---

## ✅ B-1. 단어장 상세의 학습하기 → 활성 단어장 지정 — 완료 · 커밋 `365418e` · 1.5h

`VocabBookDetailViewController` 의 학습하기 버튼이 `print` 만 실행하던 문제.
`setActiveBook(id:)` 의 호출자가 온보딩 1곳뿐이라 앱 안에서 학습 대상을 바꿀 방법이 없었다.

- [x] **`Shared/Domain/UseCases/SetActiveBookUseCase.swift` 신설** — `execute(topic:) -> Observable<Bool>`.
      `readAllBooks(bookType: topic).first` 로 id를 얻어 `setActiveBook(id:)` 호출, 단어장 없으면 false
- [x] `VocabBookDetailViewController` — `print` 제거, `startLearningRelay`(기존 `saveVocabRelay` 패턴)로
      ViewModel Input 전달
- [x] `VocabBookDetailViewModel` — `Input.startLearningTrigger` 추가, UseCase 주입
- [x] `AppDIContainer` — `makeSetActiveBookUseCase()` 추가 + `makeVocabDetailViewModel` 에 주입
- [x] 죽어 있던 `libraryDidSelectActiveBook()`(호출처 0곳) 을 `LibraryViewControllerDelegate` 에서 제거

> **원안 대비 변경 2가지**
> 1. **repo 직접 주입 → `SetActiveBookUseCase` 신설.** ViewModel의 기존 의존성이 전부 UseCase라
>    레이어 일관성을 지켰고, D-2에서 Mock repo로 검증 가능해진다.
> 2. **"모달 닫고 Explore 복귀"는 취소.** 실제 사용 시 시트가 닫히는 흐름이 어색해,
>    **지정 후 상세 화면에 그대로 머무르는 것**으로 변경했다. 이에 따라 `didActivateBook` Output과
>    `myBookDetailDidActivateBook()` delegate는 만들었다가 다시 제거했다.
>    Explore는 `activeBookId` Relay를 구독하므로 **모달을 닫는 시점이 아니라 지정 시점에 이미 갱신**된다.

**완료 조건**
- [x] **BUILD SUCCEEDED**
- [ ] 추천/나의 단어장 모두에서 지정 동작 · 다른 단어장 지정 시 이전 단어장이 해제됨
- [ ] 학습하기 탭 시 모달이 닫히지 않고 유지됨

## 🔶 B-2. "학습중" 표시 (단어장 목록 카드 + 상세 버튼) — **잔여 2h** · 선행 B-1

> **상세 버튼은 완료(커밋 `365418e`).** 남은 건 **Library 목록 카드 배지**뿐이다.

> **⚠️ 선행 조사 결과**: `LibraryViewController:206` 이 `snapshot.appendItems(BookTopic.allCases)` 로
> 카드를 만든다. **DB를 조회하지 않고 enum으로 카드를 생성하고**, DiffableDataSource item 타입도
> `BookTopic` 이다(`:32` `:34` `:162`). 따라서 `isActive` 를 카드에 실으려면 Library를 DB 조회
> 기반으로 전환해야 한다. 현재 `LibraryViewModel` 은 `transform` 이 빈 `Output()` 을 반환하는
> 껍데기이고 `AppDIContainer:52` 도 `LibraryViewModel()` 로 **의존성 주입이 없다**.

- [ ] `LibraryViewModel` 구현 — `readAllBooks()` → `[VocabBookCardInfo]`(topic + isActive) Output
      (+ `AppDIContainer.makeLibraryViewModel()` 에 의존성 주입 추가)
- [ ] `LibraryViewController` — DiffableDataSource item 타입 `BookTopic` → `VocabBookCardInfo` 교체
      (`:32` `:34` `:162` `:206`)
- [ ] `VocabTopicCardCollectionViewCell.binding(with:)` 시그니처 변경 + 학습중 배지 뷰 추가
- [x] `VocabBookDetailViewController` 우상단 버튼 — 활성 단어장이면 "학습중" + disabled
- [x] 활성 id를 구독해 내 id와 비교하는 로직은 **필요 없다** — 조회 결과에 `isActive` 가 실려 온다

### ✅ 완료분 — 상세 버튼 "학습중" 표기 (0.5h)

- [x] **`Shared/Domain/UseCases/IsActiveBookUseCase.swift` 신설** —
      `readAllBooks(bookType: topic).first?.isActive ?? false`. A-3에서 `isActive` 가 도메인까지
      실려 오므로 별도 비교 로직이 필요 없다
- [x] `VocabBookDetailViewModel` — `Output.isActiveBook: Driver<Bool>` 추가.
      **`viewWillAppear`(재진입) + `startLearningTrigger` 성공(화면 유지)** 두 경로가 모두 이 값을 갱신한다
- [x] `VocabBookDetailViewController` — `configView()` 에서 인라인 생성하던 `UIBarButtonItem` 을
      저장 프로퍼티 `startLearningButton` 으로 승격(참조가 없으면 상태를 못 바꾼다).
      `title = isActive ? "학습중" : "학습하기"` · `isEnabled = !isActive`
- [x] `AppDIContainer` — `makeIsActiveBookUseCase()` 추가 + 주입
- [x] **BUILD SUCCEEDED**

**완료 조건**: 활성 단어장 카드에만 배지 · 다른 단어장 지정 시 배지가 하나만 이동(동시 2개 없음)

## B-3. 활성 단어장 미선택 상태 처리 — **2h** · 선행 B-1

`activeBook` 이 nil이면 Explore 카드가 0개가 되고 "학습할 단어가 없습니다" 알럿이 뜬다.
실제 원인은 단어장 미선택이므로 문구가 원인과 맞지 않는다.

- [ ] `activeBook == nil` 일 때 Explore에 빈 상태 뷰(단어장 선택 유도)
- [ ] 같은 조건에서 학습하기 버튼 disabled
- [ ] 기존 "학습할 단어가 없습니다" 알럿은 단어 4개 미만 케이스 전용으로 분리

> `isActive` 방식에서는 활성 단어장 삭제 시에도 자동으로 이 경로를 타므로 커버 범위가 넓어진다.

---

## C-1. `StartQuizUseCase` 신설 — 출제 세트 선정 — **4h** · 선행 A-1 + 정책 확정

현재 출제 세트는 `ExploreVocabViewController:218~` 에서 단어장 전체를 그대로 넘긴다.

- [ ] `Shared/Domain/UseCases/StartQuizUseCase.swift` 신설 (기존 UseCase 5개와 동일 패턴)
- [ ] 활성 단어장을 `vocabBookRepository.activeBook` 에서 받아 출제 세트 결정
  - 20개 이하: 전체 셔플
  - 20개 초과: 학습 이력 기반 가중 랜덤 20개
- [ ] `QuizData.allWord` 에는 20개 세트가 아니라 **단어장 전체**를 넘긴다 (보기 다양성)
- [ ] 단어 4개 미만이면 실패 반환 — `QuizViewModel.generateChoices` 가 오답 3개를 필요로 하므로 필수

**완료 조건**: 20개 초과 → 항상 20문제 · 20개 이하 → 전체 출제되고 매번 순서가 달라짐 ·
4개 미만 → 시작되지 않고 안내 · 보기 4개가 항상 채워짐

## C-2. 출제 진입점을 VC → ViewModel/UseCase로 이동 — **2h** · 선행 C-1

- [ ] `ExploreVocabViewController` 학습하기 핸들러의 가드/조립/알럿 분기를 `ExploreVocabViewModel` 로 이관
- [ ] `ExploreVocabViewModel.Output` 에 `startQuiz` / `alert` 추가
- [ ] ViewController는 delegate 호출만 담당

**완료 조건**: `ExploreVocabViewController` 에 `QuizData` 생성 코드 0줄 · 동작 회귀 없음

## C-3. 학습 이력 집계 중복 제거 — **1.5h** · 선행 C-1

`vocabId` 별 (정답, 전체) 집계가 이미 두 곳에 중복 구현되어 있다.
`ExploreVocabViewModel:41~` / `DefaultFetchVocabsUseCase:47~`
C-1의 선정 로직도 같은 집계를 쓰므로 세 번째 복붙 전에 합친다.

- [ ] `LearningHistoryRepository.stats()` 또는 공용 UseCase 한 곳으로 이동
- [ ] 위 두 소비처와 C-1이 동일 구현을 공유

**완료 조건**: 집계 구현이 1곳 · Explore 카드와 단어장 상세의 학습횟수/정답률 회귀 없음

## C-4. 학습 완료 화면의 재출제 정책 재정의 — **2h** · 선행 C-1 + 정책 확정

`QuizCoordinator:68` 의 "처음부터 다시 학습하기"가 `originalData.allWord` 전체로 재시작한다.
`allWord` 는 단어장 전체이므로 20개 초과 단어장에서 상한이 깨진다.

- [ ] `allWord` 전체 재시작 제거 → `StartQuizUseCase` 재호출
- [ ] "틀린 문제 학습하기"(`retryIncorrect`)는 현행 유지

**완료 조건**: 20개 초과 단어장에서 재시작 시 20문제 유지 · 20개 이하는 기존과 동일

---

## D-1. 중단 시 이력 보존 검증 + 중단 알럿 문구 — **1h** · 선행 A-1, C-2

`QuizViewModel:100` 에서 답 선택 즉시 `addHistory` 를 호출해 CoreData에 저장하므로
"중간 종료 시에도 저장" 요구사항은 **이미 충족되어 있다. 신규 개발이 아닌 검증 카드다.**

- [ ] 수동 검증: 5문제 풀고 X로 종료 → Explore 카드/단어장 상세의 학습 횟수·정답률에 5건 반영
- [ ] `QuizCoordinator:95` 알럿 문구 수정 — 이어하기가 없어졌으므로 "진행분은 저장되고 이어하기는
      없다"는 의미가 드러나도록

## D-2. Domain 유닛테스트 타깃 신설 + 선정 로직 테스트 — **2.5h** · 선행 C-1

현재 테스트 타깃이 없다(`docs/environment.md:21`). 랜덤이 포함된 선정 로직은 테스트 없이
회귀를 감지할 수 없다.

- [ ] 유닛테스트 타깃 신설 (Domain 전용, 외부 의존성 없음)
- [ ] `StartQuizUseCase` 케이스: 4개 미만 실패 / 정확히 20개 / 21개 이상 → 20개 /
      미학습·저정답률 단어의 선정 확률이 더 높은지(가중치 방향성) / 반복 실행 시 순서 변화

> `ActiveLearningManager` 가 사라지고 `VocabBookRepository` 프로토콜로 접근하므로 Mock 주입이
> 가능해진다. 기존 구조에서는 `UserInfoManager` 가 `private init` 이라 활성 단어장 관련 테스트가
> 불가능했다.

---

## 착수 전 확정 필요

- [x] **① 출시본 존재 여부** — **출시본 없음 확정**. 모델 in-place 수정 완료(+0h), 앱 재설치 필요
- [ ] **② C-1 가중 랜덤 정책** — 제안: `w = (1 - accuracy) + 1/(total + 1)` 확률 추출.
      정답률순 정렬만 하면 매번 같은 단어가 뽑혀 "랜덤"이 아니게 된다
- [ ] **③ C-4 재출제 정책** — 제안: 새로 20개 다시 뽑기(직전 학습 결과가 다음 세트에 반영됨).
      대안: 같은 20개를 셔플만

## 검증 명령

```bash
xcodebuild -scheme Danogotchi-dev build

# A-3 완료 후 0건 (검증 완료)
grep -rn "ActiveLearningManager\|activeBookIdentifier\|Keys.activeBookId" --include="*.swift" Danogotchi/

# DI 컨테이너 1곳만 나와야 함 (Relay 단일 인스턴스 보장)
grep -rn "DefaultVocabBookRepository(" --include="*.swift" Danogotchi/

# B-1 완료 후 0건 (죽은 delegate 제거 + print 제거 + 모달 닫기 취소)
grep -rn "libraryDidSelectActiveBook\|단어장 학습하기로 변경\|didActivateBook" --include="*.swift" Danogotchi/
```

## 시간 산정

| 구간 | 시간 |
|---|---|
| A-1 + A-2 (완료) | 5h |
| A-3 (완료) | 4h |
| B-1 (완료) + B-2 상세버튼 (완료) | 2h |
| B-2 잔여(목록 카드 배지) + B-3 | 4h |
| C-1 + C-2 + C-3 + C-4 | 9.5h |
| D-1 + D-2 | 3.5h |
| **잔여** | **17h** |

---

# 완료 아카이브 — Realm → CoreData 전환 스프린트

> **방향**: Realm을 리팩토링하지 않는다. **Realm이 없다고 가정하고 CoreData 데이터 레이어를 새로 구현**한 뒤,
> Repository/ViewModel 소비처를 새 CoreData 구현체로 갈아끼우고, 마지막에 Realm 잔재를 제거한다.
> 신규 코드는 옛 Realm 코드와 **잠시 공존**하다가 Phase 7에서 일괄 삭제한다.
>
> - 네이밍: 도메인 `Vocab` / `VocabBook` / `LearningHistory`, CoreData `*Entity`
> - 도메인 id 타입: **UUID** (CoreData 기준)
> - 데이터 이관 없음 (clean start)
>
> **이번 스프린트 범위**: Realm **완전 제거** → CoreData 전환. 데이터 레이어(Phase 1~5)는 완료, 남은 작업은 **Phase 6(소비처 통합) + Phase 7(Realm 제거)**. **신규 기능(북마크)은 이번 스프린트 제외 — 문서 하단 "이연" 항목 참고.**

진행률(대략): **Phase 1~6 완료 · Phase 7 거의 완료** — 코드/문서 레벨 Realm 제거 완료(옛 파일 13개 삭제 · DI 팩토리 3종 제거 · `import RealmSwift`/`ObjectId`/`Realm` grep 0건). ✅ **BUILD SUCCEEDED**. 남은 작업: **① Xcode SPM `realm-swift` 패키지 제거(GUI) · ② 런타임 이슈 1건**(Phase 7 하단 참고).

> **최근 작업(현재 세션)**: **Phase 7 Realm 제거 수행** — 옛 파일 13개 삭제(도메인 4 · Realm Object 3 · 옛 프로토콜 3 · 옛 구현 3), `AppDIContainer` 죽은 팩토리 3종(`makeWordRepository`/`makeWordBookRepository`/`makeLearningHistoryRepository`) 제거, `AppDelegate`의 `import RealmSwift`+`#if DEBUG try? Realm()` 블록 제거, `MyBookDetail`의 `myBookObjectId`/`bookObjectId` → `myBookId`/`bookId` 리네이밍. **grep 검증: `import RealmSwift`·`ObjectId`·`Realm` 전부 0건**. 문서(`AGENTS.md`·`architecture.md`·`environment.md`·`conventions.md`) 용어를 CoreData/`Vocab`로 갱신. 남은 건 **Xcode에서 SPM `realm-swift` 패키지 제거**(pbxproj 손상 위험으로 GUI 권장)와 **런타임 이슈 1건**(clean start 미표시, 하단).

---

## ✅ Phase 1. 데이터 모델 + 엔티티 — 완료
- [x] CoreData 모델 `Model.xcdatamodeld`, 엔티티 3종(`VocabBookEntity`/`VocabEntity`/`LearningHistoryEntity`)
- [x] 속성 + 관계 2쌍 + 삭제규칙(Cascade/Nullify, inverse)
- [x] SwiftData off, Codegen **Manual/None**
- [x] NSManagedObject 서브클래스 6개 직접 소유 (`Local/Entities/`)

## ✅ Phase 2. CoreData 스택 — 완료
- [x] `CoreDataStack` (싱글턴 + `viewContext` + `saveContext`)
- [x] `AppDIContainer`에 주입 (하이브리드: `shared` 보유, repo엔 `viewContext` 주입 예정)
- [x] ⚠️ `savceContext` → `saveContext` 오타 수정

## ✅ Phase 3. 깨끗한 도메인 모델 (신규 정의) — 완료
> Realm을 전혀 모르는 새 도메인. 옛 `Word`/`WordBook`과 잠시 공존, Phase 7에서 옛 모델 제거.
- [x] `Vocab` (id:UUID / word / meaning / createAt) — `import RealmSwift`·`toObject` 없음
- [x] `VocabBook` (id:UUID / title / type / originBookId / vocabList / createAt)
- [x] `LearningHistory` (id:UUID / vocabId:UUID / isCorrect / createAt)
- [x] `VocabBookType` (`.mine` / `.recommended`) — `String` rawValue, 엔티티 `type`과 직결
- [x] `CreateVocab` (입력 DTO, Realm/ObjectId 없음)

## ✅ Phase 4. 매퍼 (Entity → 도메인) — 완료
> 추가만 하는 새 코드 → 빌드 안 깨짐.
- [x] `Data/Mappers/` 신설
- [x] `VocabEntity → Vocab`, `VocabBookEntity → VocabBook`, `LearningHistoryEntity → LearningHistory`
- [x] `@NSManaged` 옵셔널 해제(non-nil 보장)를 매퍼에서 수행

## ✅ Phase 5. 새 Repository 프로토콜 + CoreData 구현 (신규 작성) — 완료
> 옛 Realm repo는 건드리지 않고 새 프로토콜/구현을 나란히 추가.
- [x] 프로토콜 껍데기 추가: `VocabRepository` / `VocabBookRepository` / `VocabLearningHistoryRepository`
- [x] 구현체 껍데기 추가: `DefaultVocabRepository` / `DefaultVocabBookRepository` / `DefaultVocabLearningHistoryRepository`
- [x] 프로토콜 채택은 역할별 `extension`으로 분리 (향후 다중 프로토콜 채택 대비)
- [x] 깨끗한 프로토콜 시그니처 정의(도메인 타입만, `ObjectId`/`WordObject` 없음)
- [x] CoreData 구현체에 `NSManagedObjectContext` 생성자 주입
- [x] `DefaultVocabRepository` CRUD 구현
- [x] `DefaultVocabBookRepository` CRUD + 단어 관계 추가/조회 구현
- [x] 통합 단어장 필드 저장 반영: `type` / `originBookId` / `originWordId`
- [x] `DefaultVocabLearningHistoryRepository` 구현
- [x] 관계 기반 정답률 집계

## Phase 6. 통합 — 소비처를 새 CoreData 구현체로 전환  ⬅️ **이번 스프린트 핵심**
> 빌드가 크게 흔들리는 유일 구간. **공통 모델 → 도메인 상태/DI → ViewModel/VC → 코디네이터** 순으로 전환.
> 목표: 소비처에서 `import RealmSwift`·`ObjectId`·`Word`·`WordBook`·`CreateWord`·`WordObject` 전부 제거.

### ✅ 6-1. 공통 모델 먼저 (`Word` → `Vocab`) — 완료
- [x] `Common/Models/QuizData.swift` — `words`/`allWord` `[Word]` → `[Vocab]`
- [x] `Common/Models/QuizResult.swift` — `incorrectWords` `[Word]` → `[Vocab]`
- [x] `Common/Models/WordDisplayInfo.swift` — `word: Word` → `word: Vocab`

### ✅ 6-2. 도메인 상태 / 전역 싱글턴 — 완료
- [x] **`Domain/ActiveLearningManager.swift` 전면 재작성** (부담: 대)
  - `activeBook: BehaviorRelay<WordBook?>` → `<VocabBook?>`
  - `enum WordBookSource { .realm / .recommended }` → `.mine` / `.recommended` (도메인 `VocabBookType`과 일치)
  - `WordBookRepository` → `VocabBookRepository`, `loadRealmBook` 재작성: `ObjectId(string:)` 제거→`UUID`, `read`/`fetchWordsInWordBook` → `readBook(id:)`/`fetchVocabs(inBookId:)`
- [x] **`Data/DataSources/Local/UserInfoManager.swift`**
  - `enum ActiveBookType { .realm }` → `.mine` (rawValue 정렬, clean start이라 UserDefaults 호환 불필요)
  - 레거시 `selectedBookId` setter의 `type: .realm` / `.type == .realm`, 잔재 키(`"WordBookId"`) 정리

### ✅ 6-3. DI 컨테이너 — 완료
- [x] `AppDIContainer`: `makeVocabRepository()` / `makeVocabBookRepository()` / `makeVocabLearningHistoryRepository()` 추가 — 각 구현체에 `coreDataStack.viewContext` 주입
- [x] `makeMyBookDetailViewModel` / `makeCreateWordViewModel(vocabItem:)` 을 Vocab repo 주입으로 전환
  - ⚠️ `makeLibraryViewModel` 은 **주입 없음**(`LibraryViewModel()`) — VM이 빈 껍데기라 필요 없었다. B-2 잔여에서 주입한다
- [x] `ActiveLearningManager` 기본 인자 교체 (`DefaultVocabBookRepository`)
- [x] 옛 `make*Repository()`(Word/WordBook/LearningHistory) 제거 — *Phase 7에서 `Default*` 구현체·프로토콜과 함께 제거 완료*

### ✅ 6-4. ViewModel / ViewController (부담순) — 7/7 완료
- [x] **CreateWord** (대) — `CreateWord`→`CreateVocab`, `ObjectId?`→`UUID?`, `create`→`createVocab(...originWordId:)`, `addWord(bookId:word:WordObject)`→`addVocab(bookId:word:meaning:originWordId:)`, `update`→`updateVocab(id:UUID,...)`
  - *구현 메모*: 죽은 신규-단어장 생성 주석 로직 제거, 저장 시 호출부가 넘긴 `vocabItem.vocabBookId` 사용
- [x] **Library** (중) — 추천 단어장 다운로드 로직 재구성(`create(title:)`→`createBook(title:type:.recommended)`, `readAll().last`→`readBook(id:)`, word 객체 생성 제거→`addVocab` 문자열 전달), `"나의 단어장"` 조회→`readAllBooks(type: .mine)`
  - *구현 메모*: 추천/다운로드 매칭을 `title` 매직스트링→`originBookId` 기반으로 교체, `selectedBookId: String?`→`UUID?`, `itemSelected` source `.realm`→`.mine`
- [x] **MyBookDetail** (중) — `ObjectId`→`UUID`, `Word`→`Vocab`, `"나의 단어장"` 조회→`type: .mine`, `fetchWordsInWordBook`→`fetchVocabs(inBookId:)`, 이력 repo→`VocabLearningHistoryRepository`
  - ✅ 정답률 집계 `vocabId` 매칭 — Quiz가 `VocabLearningHistory`에 기록하게 되어 **정상 표시**(0 문제 해소)
- [x] **ExploreVocab** (중) — `Word`→`Vocab`, 이력 repo→`VocabLearningHistoryRepository`, 그룹핑 키 `wordId`→`vocabId`, `deleteWordTrigger` 타입 `Vocab`
  - *구현 메모*: 죽은 `wordRepository` 주입 제거, 퀴즈 재개 `wordMap` 키를 `id.uuidString`으로 정합(`currentQuizWordIds`가 `[String]`)
- [x] **Quiz** (중) — `incorrectWords: [Word]`→`[Vocab]`, `ObjectId(string:)` 가드 제거→`addHistory(vocabId: word.id, isCorrect:)` · repo→`VocabLearningHistoryRepository`, `currentIncorrectWordIds` 저장 시 `.uuidString`
  - *선결조건 해소*: 이 전환으로 MyBookDetail 정답률이 실제 값으로 표시됨
- [x] **CompleteQuiz** (경) — `import RealmSwift` 제거(VM+VC), `ActionType.retryIncorrect(words:)` 타입 `[Vocab]`
- [x] **SearchThemeViewController** (중) — `DefaultVocabBookRepository(context: CoreDataStack.shared.viewContext)`로 교체, 온보딩 `readAll()`→`readAllBooks(type:.mine)`, `create()`+`readAll().last`→`createBook(...type:.mine)` 반환값 사용(빈 에러 분기 제거)

### ✅ 6-5. 코디네이터 delegate 시그니처 (`CreateWord` → `CreateVocab`) — 완료
- [x] `App/Coordinator/MainCoordinator.swift` — `exploreVocabDidTapEditWord(vocabItem:)`
- [x] `Presentation/Library/Coordinator/LibraryCoordinator.swift` — `myBookDetailDidTapCreateWord`/`...EditWord(with:)`

### ✅ 6-6. Firestore·네트워크 repo (CoreData 아님 — 반환 타입만 정렬) — 완료
- [x] `RecommendBookRepository.fetchRecommendBooks()` 반환 `[WordBook]` → `[VocabBook]` (`DefaultRecommendBookRepository` + `MockData/RecommendBooks.swift` 포함, `originBookId`에 고정 id 부여)
- [x] `SearchThemeRepository`는 `SearchPhotoEntity` 반환 → **변경 없음** (소비 VC 온보딩 생성은 6-4 SearchTheme에서 처리)

### ✅ 6-7. 매직 스트링 정책 — 완료 (대상 3화면 한정)
- [x] 조회/분기용 `"나의 단어장"` 비교 → `type: .mine` 로 대체 (MyBookDetail·Library — CreateWord VM은 호출부가 넘긴 `vocabBookId` 직접 사용이라 비교 없음)
- [x] 단, **생성 title** 로서의 `"나의 단어장"` 과 UI 라벨(`MyBookCollectionViewCell`)은 그대로 둔다

## Phase 7. Realm 제거 + 마무리 — 코드/문서 완료, SPM 제거만 남음
> Phase 6 전환이 끝나 소비처에서 옛 타입이 모두 사라진 뒤 일괄 삭제.
- [x] 옛 도메인 삭제: `Word` / `WordBook` / `LearningHistoryModel` / `CreateWord` (+ `toObject`)
- [x] 옛 Realm Object 3종 삭제: `WordObject` / `WordBookObject` / `LearningHistoryTable`
- [x] 옛 Realm repo/프로토콜 삭제: `WordRepository`·`WordBookRepository`·`LearningHistoryRepository` + `Default*` 3종
- [x] `AppDelegate` Realm 블록 제거(`import RealmSwift`, `#if DEBUG try? Realm()`)
- [x] grep 검증: `import RealmSwift` 0건 / `ObjectId` 0건 / `Realm` 0건
- [x] `AGENTS.md` / `docs/architecture.md`(+ `environment.md` / `conventions.md`)의 "Realm" 및 도메인 용어(`Word`/`WordBook`) → CoreData·`Vocab`/`VocabBook` 갱신
- [x] 최종 빌드 검증 → **BUILD SUCCEEDED** (사용자 확인)
- [x] **Xcode SPM `realm-swift` 패키지 제거** — pbxproj의 Link/Embed·`XCRemoteSwiftPackageReference`·`Package.resolved`에 얽혀 있어 **Xcode GUI에서 제거**(PROJECT → Package Dependencies → `−`). *코드에 Realm 참조 0건이라 미제거 상태로도 빌드는 통과.*

### ⚠️ Phase 7 후속 — 런타임 이슈(발견): 기존 데이터 상태에서 "나의 단어장" 미표시
> **증상**: 나의 단어장 목록이 안 보이고 `MyBookDetail`에서 단어 추가 화면 진입 불가.
> **원인**: 두 증상 모두 `readAllBooks(type: .mine)`가 빈 배열 → CoreData에 나의 단어장 없음. 나의 단어장 생성 경로는 **온보딩(`SearchTheme`) 단 한 곳**인데, 진입 조건이 `AppFlowCoordinator.start()`의 `currentThemeUrl != nil`(UserDefaults). **이전 Realm 빌드에서 온보딩 완료 → `themeUrl` 잔존 → 온보딩 스킵 → clean start라 CoreData엔 나의 단어장 미생성**. 특정 코드 라인 버그 아님(신규 설치는 정상).
- [x] **1차 검증**: 앱 삭제 후 재설치(또는 시뮬레이터 Erase) → 온보딩부터 → 정상 여부 확인 *(clean start 정상 절차)*
- [x] *(선택/이연)* 자동 복구용 bootstrap 검토: 메인 진입 시 `readAllBooks(type:.mine).isEmpty`면 `createBook(type:.mine)` — clean start 정책과 별개 방어 로직, 별도 논의

---

## ⏸️ 이연 (다음 스프린트) — 신규 기능: 북마크("나의 단어에 저장")
> Realm 제거와 무관한 신규 기능이라 이번 스프린트 범위에서 제외. 스키마에 `originWordId`가 이미 있어 독립적으로 착수 가능.
- [ ] `originWordId` 기준 저장/해제 **토글** 구현
- [ ] 활성 단어장 `type`에 따라 북마크 표시/숨김 + 저장여부 파생 판정

---

### 참고: 영향 범위
- `import RealmSwift`: 23파일 → **0** / `ObjectId`: 18파일 → **0** (Phase 6~7 정리 완료)
- Realm 기반 repo 3종 → CoreData 재구현 완료 / Firestore(`RecommendBook`)·네트워크(`SearchTheme`) repo 2종 → CoreData 변경 없음(RecommendBook 반환 타입만 `VocabBook` 정렬)

