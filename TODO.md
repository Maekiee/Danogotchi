# TODO — CoreData 신규 구현 (Realm 비의존 클린 빌드)

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
- [x] `makeLibraryViewModel` / `makeMyBookDetailViewModel` / `makeCreateWordViewModel(vocabItem:)` 을 Vocab repo 주입으로 전환
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

