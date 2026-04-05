# Danogotchi 리팩토링 체크리스트

> **목표**: iOS 16+, Swift 5.5+, RxSwift, Clean Architecture, Coordinator 패턴, MVVM Input/Output 패턴
> **진행 방법**: 각 항목 완료 시 `- [ ]` → `- [x]` 로 변경

---

## 목표 아키텍처

```
Presentation/
├── Coordinators/     ← 네비게이션 책임
├── ViewControllers/  ← UI 바인딩만
└── ViewModels/       ← Input/Output 변환만

Domain/               ← 프레임워크 독립
├── Entities/         ← 순수 Swift 구조체
├── UseCases/         ← 비즈니스 로직 단위
└── Interfaces/       ← Repository 추상 프로토콜

Data/
├── Repositories/     ← Interface 구현체
├── DataSources/Local/  ← Realm
├── DataSources/Remote/ ← API, Firestore
├── DTOs/             ← 네트워크 응답 모델
└── Mappers/          ← Object ↔ Entity 변환

App/
└── DI/               ← AppDIContainer
```

---

## Phase 1 — 프로젝트 구조 및 Domain 계층 수립

### 1-1. Xcode 프로젝트 그룹 구조 재편

- [ ] `Presentation/` 그룹 생성
  - [ ] `Presentation/Coordinators/` 그룹 생성
  - [ ] `Presentation/ViewControllers/` 그룹 생성 후 기존 `ViewControllers/` 파일 이동
  - [ ] `Presentation/ViewModels/` 그룹 생성 후 기존 `ViewModels/` 파일 이동
  - [ ] `Presentation/Components/` 그룹 생성 후 기존 `Components/` 파일 이동
- [ ] `Domain/` 그룹 생성
  - [ ] `Domain/Entities/` 그룹 생성
  - [ ] `Domain/UseCases/` 그룹 생성
  - [ ] `Domain/Interfaces/` 그룹 생성
- [ ] `Data/` 그룹 생성
  - [ ] `Data/Repositories/` 그룹 생성 후 기존 `Repositories/` 파일 이동
  - [ ] `Data/DataSources/Local/` 그룹 생성 후 기존 `RealmObjects/` 파일 이동
  - [ ] `Data/DataSources/Remote/` 그룹 생성
  - [ ] `Data/DTOs/` 그룹 생성 후 기존 `DTOs/` 파일 이동
  - [ ] `Data/Mappers/` 그룹 생성
- [ ] `Infrastructure/` 그룹 생성
  - [ ] `Infrastructure/Network/` 그룹 생성 후 `ApiService.swift`, `ApiRouter.swift`, `FirestoreService.swift` 이동
  - [ ] `Infrastructure/Database/` 그룹 생성
- [ ] `App/DI/` 그룹 생성
- [ ] 이동 후 `xcodebuild -scheme Danogotchi-dev build` 빌드 성공 확인

---

### 1-2. Domain Entity — Word, WordBook

- [ ] `Domain/Entities/Word.swift` 작성
  - [ ] `struct Word: Hashable` (id: String, thumbnail: String, word: String, meaning: String, createdAt: Date)
  - [ ] id 타입 `ObjectId` → `String` 변경 (Realm 의존 제거)
  - [ ] `CardDisplayable` 프로토콜 의존 여부 검토 (UI 관련이면 Presentation 계층으로 이동)
- [ ] `Domain/Entities/WordBook.swift` 작성
  - [ ] `struct WordBook: Hashable` (id: String, title: String, words: [Word], createdAt: Date)
- [ ] 기존 `ViewData/Word.swift`, `ViewData/WordBook.swift` 참조 목록 파악 (grep)
- [ ] 각 참조처에서 새 Entity 사용으로 변경 준비 (Phase 6 이후 순차 교체)

---

### 1-3. Domain Entity — LearningHistory, QuizQuestion, ActiveBookIdentifier, ThemeImage

- [ ] `Domain/Entities/LearningHistory.swift` 작성
  - [ ] `struct LearningHistory` (id: String, wordId: String, isCorrect: Bool, learnedAt: Date)
- [ ] `Domain/Entities/QuizQuestion.swift` 작성
  - [ ] `struct QuizQuestion` (word: Word, choices: [String], correctAnswer: String)
- [ ] `Domain/Entities/ActiveBookIdentifier.swift` 작성
  - [ ] `struct ActiveBookIdentifier` (id: String, source: Source)
  - [ ] `enum Source: String { case local, recommended }`
- [ ] `Domain/Entities/ThemeImage.swift` 작성 (기존 `SearchPhotoEntity` 대체)
  - [ ] `struct ThemeImage: Hashable` (id: String, thumbnailUrl: String, fullUrl: String, authorName: String)
- [ ] `Domain/Entities/QuizResult.swift` 작성
  - [ ] `struct QuizResult` (totalCount: Int, correctCount: Int, incorrectWords: [Word])
  - [ ] `var accuracy: Double { Double(correctCount) / Double(totalCount) }` 계산 프로퍼티

---

### 1-4. Domain Entity — AppError

- [ ] `Domain/Entities/AppError.swift` 작성
  ```swift
  enum AppError: LocalizedError {
      case database(String)
      case network(String)
      case notFound
      case invalidInput(String)
      case unauthorized
      case unknown(Error)
  }
  ```
- [ ] 각 케이스별 `errorDescription` 한국어 메시지 작성
- [ ] 기존 코드의 임시 에러 처리 방식(force try, NSError 등) 목록 파악

---

### 1-5. Domain Interface — Word / WordBook / LearningHistory Repository

- [ ] `Domain/Interfaces/WordRepositoryInterface.swift` 작성
  - [ ] `fetchAll() -> Single<[Word]>`
  - [ ] `fetch(id: String) -> Single<Word?>`
  - [ ] `save(_ word: Word, toBookId bookId: String) -> Completable`
  - [ ] `update(_ word: Word) -> Completable`
  - [ ] `delete(id: String) -> Completable`
- [ ] `Domain/Interfaces/WordBookRepositoryInterface.swift` 작성
  - [ ] `fetchAll() -> Single<[WordBook]>`
  - [ ] `fetch(id: String) -> Single<WordBook?>`
  - [ ] `create(title: String) -> Single<WordBook>`
  - [ ] `update(id: String, title: String) -> Completable`
  - [ ] `delete(id: String) -> Completable`
  - [ ] `addWord(_ word: Word, toBookId bookId: String) -> Completable`
- [ ] `Domain/Interfaces/LearningHistoryRepositoryInterface.swift` 작성
  - [ ] `save(_ history: LearningHistory) -> Completable`
  - [ ] `fetchAll(wordId: String) -> Single<[LearningHistory]>`
  - [ ] `deleteAll(wordId: String) -> Completable`
  - [ ] `fetchAccuracy(wordId: String) -> Single<Double>`
- [ ] 기존 `Protocols/WordRepositoryProtocol.swift` 등 구 프로토콜과 역할 비교 후 대체 계획 수립

---

### 1-6. Domain Interface — UserPreferences / ImageSearch / Translation / RecommendBook

- [ ] `Domain/Interfaces/UserPreferencesInterface.swift` 작성
  - [ ] `var activeBookIdentifier: Observable<ActiveBookIdentifier?> { get }`
  - [ ] `func setActiveBook(_ identifier: ActiveBookIdentifier) -> Completable`
  - [ ] `func getUsername() -> Single<String?>`
  - [ ] `func setUsername(_ name: String) -> Completable`
  - [ ] `func getThemeUrl() -> Single<String?>`
  - [ ] `func setThemeUrl(_ url: String) -> Completable`
  - [ ] `func getUserId() -> String?` / `func setUserId(_ id: String)`
- [ ] `Domain/Interfaces/ImageSearchRepositoryInterface.swift` 작성
  - [ ] `func search(query: String, page: Int) -> Single<[ThemeImage]>`
- [ ] `Domain/Interfaces/TranslationRepositoryInterface.swift` 작성
  - [ ] `func translate(text: String, targetLanguage: String) -> Single<String>`
- [ ] `Domain/Interfaces/RecommendBookRepositoryInterface.swift` 작성
  - [ ] `func fetchAll() -> Single<[WordBook]>`
  - [ ] `func fetch(id: String) -> Single<WordBook?>`
- [ ] `Domain/Interfaces/BaseViewModel.swift` 이동 (기존 `Protocols/BaseViewModel.swift`)

---

## Phase 2 — UseCase 계층 구현

### 2-1. UseCase — 단어 CRUD

- [ ] `Domain/UseCases/Word/FetchWordsUseCase.swift`
  - [ ] 프로토콜 `FetchWordsUseCaseInterface` 정의
  - [ ] `execute(identifier: ActiveBookIdentifier) -> Single<[Word]>` 구현
  - [ ] `local` → wordBookRepo.fetch, `recommended` → recommendRepo.fetch 분기 처리
- [ ] `Domain/UseCases/Word/SaveWordUseCase.swift`
  - [ ] word, meaning 빈 문자열 검증 → `AppError.invalidInput`
  - [ ] `wordRepo.save` + `wordBookRepo.addWord` 순서 처리 (Completable 체이닝)
- [ ] `Domain/UseCases/Word/UpdateWordUseCase.swift`
  - [ ] 입력 유효성 검사 포함
  - [ ] `wordRepo.update` 래핑
- [ ] `Domain/UseCases/Word/DeleteWordUseCase.swift`
  - [ ] `wordRepo.delete` 래핑
  - [ ] 관련 `learningHistoryRepo.deleteAll(wordId:)` 함께 호출

---

### 2-2. UseCase — 단어장 CRUD

- [ ] `Domain/UseCases/WordBook/FetchWordBooksUseCase.swift`
  - [ ] `wordBookRepo.fetchAll()` 래핑
  - [ ] 생성일 기준 내림차순 정렬
- [ ] `Domain/UseCases/WordBook/CreateWordBookUseCase.swift`
  - [ ] title 공백/빈 문자열 검증 → `AppError.invalidInput`
  - [ ] `wordBookRepo.create(title:)` 래핑, `Single<WordBook>` 반환
- [ ] `Domain/UseCases/WordBook/DeleteWordBookUseCase.swift`
  - [ ] `wordBookRepo.delete(id:)` 래핑
  - [ ] 내부 Word들의 LearningHistory 일괄 삭제 처리
- [ ] `Domain/UseCases/WordBook/CopyWordBookUseCase.swift` (기존 북 다운로드 로직)
  - [ ] `wordBookRepo.create(title: source.title)` 로 새 단어장 생성
  - [ ] `source.words` 순회하며 `wordRepo.save` + `wordBookRepo.addWord`
  - [ ] DispatchQueue 중첩 제거 → RxSwift `flatMap` 체이닝으로 대체
  - [ ] `Single<WordBook>` 반환

---

### 2-3. UseCase — 퀴즈

- [ ] `Domain/UseCases/Quiz/GenerateQuizUseCase.swift`
  - [ ] `execute(words: [Word]) -> [QuizQuestion]`
  - [ ] words shuffle
  - [ ] 각 word에 정답 1개 + words에서 랜덤 오답 3개 (중복 없이) 선택
  - [ ] `[QuizQuestion]` 반환
- [ ] `Domain/UseCases/Quiz/SubmitAnswerUseCase.swift`
  - [ ] `execute(question: QuizQuestion, selectedAnswer: String) -> Single<Bool>`
  - [ ] `isCorrect` 판정
  - [ ] `LearningHistory` 생성 후 `learningHistoryRepo.save()` 호출
  - [ ] `Single<Bool>(isCorrect)` 반환
- [ ] `Domain/UseCases/Quiz/GetQuizResultUseCase.swift`
  - [ ] `execute(questions: [QuizQuestion], answers: [String]) -> QuizResult`
  - [ ] correctCount, incorrectWords 집계
  - [ ] UserInfoManager의 퀴즈 상태 저장 로직 완전 제거 (UserDefaults 저장 안 함)

---

### 2-4. UseCase — 이미지 검색 / 번역 / 활성 단어장

- [ ] `Domain/UseCases/Search/SearchImagesUseCase.swift`
  - [ ] `execute(query: String, page: Int) -> Single<[ThemeImage]>`
  - [ ] 빈 query → `AppError.invalidInput("검색어를 입력해주세요.")`
  - [ ] `imageSearchRepo.search` 래핑
- [ ] `Domain/UseCases/Translation/TranslateWordUseCase.swift`
  - [ ] `execute(text: String) -> Single<String>` (targetLanguage 기본값 "KO")
  - [ ] 빈 text → `AppError.invalidInput`
  - [ ] `translationRepo.translate` 래핑
- [ ] `Domain/UseCases/ActiveBook/GetActiveBookUseCase.swift`
  - [ ] `execute() -> Observable<(WordBook, ActiveBookIdentifier)?>`
  - [ ] `userPreferences.activeBookIdentifier` 구독
  - [ ] identifier 변경 시 WordBook 자동 로드 (local/recommended 분기)
  - [ ] 기존 `ActiveLearningManager`의 핵심 로직 대체
- [ ] `Domain/UseCases/ActiveBook/SetActiveBookUseCase.swift`
  - [ ] `execute(identifier: ActiveBookIdentifier) -> Completable`
  - [ ] `userPreferences.setActiveBook` 래핑

---

## Phase 3 — Data 계층 구현

### 3-1. Mapper — WordMapper, WordBookMapper

- [ ] `Data/Mappers/WordMapper.swift`
  - [ ] `toDomain(_ object: WordObject) -> Word`
    - [ ] `object.id.stringValue` → `Word.id` (String 변환)
    - [ ] `object.createAt` → `Word.createdAt`
  - [ ] `toObject(_ domain: Word) -> WordObject`
    - [ ] 신규 insert용: 새 `ObjectId()` 생성
    - [ ] update용: 기존 id 파싱 (`try? ObjectId(string: domain.id)`)
- [ ] `Data/Mappers/WordBookMapper.swift`
  - [ ] WordMapper 의존성 주입 (생성자)
  - [ ] `toDomain(_ object: WordBookObject) -> WordBook`
    - [ ] `object.wordList.map { wordMapper.toDomain($0) }` 변환
  - [ ] `toObject(_ domain: WordBook) -> WordBookObject`
- [ ] 기존 `WordObject.toStruct()`, `WordBookObject.toStruct()` extension 사용처를 Mapper로 대체 준비

---

### 3-2. Mapper — LearningHistoryMapper, ThemeImageMapper

- [ ] `Data/Mappers/LearningHistoryMapper.swift`
  - [ ] `toDomain(_ object: LearningHistoryObject) -> LearningHistory`
    - [ ] `object.wordObjectId.stringValue` → `LearningHistory.wordId`
    - [ ] `object.createAt` → `LearningHistory.learnedAt`
  - [ ] `toObject(_ domain: LearningHistory) -> LearningHistoryObject`
    - [ ] **버그 수정**: `obj.createAt = domain.learnedAt` (기존 `self.createAt = createAt` 자기 자신 할당 버그)
- [ ] `Data/Mappers/ThemeImageMapper.swift`
  - [ ] `toDomain(_ dto: SearchPhotoDTO) -> [ThemeImage]`
    - [ ] `dto.results.map { ThemeImage(id: $0.id, thumbnailUrl: $0.urls.thumb, ...) }`
  - [ ] 기존 `SearchPhotoDTO.toEntity()` extension 대체 후 삭제 준비

---

### 3-3. Infrastructure — NetworkService 래퍼

- [ ] `Infrastructure/Network/NetworkServiceInterface.swift`
  - [ ] `protocol NetworkServiceInterface`
  - [ ] `func request<T: Decodable>(_ router: ApiRouter, type: T.Type) -> Single<T>`
- [ ] `Infrastructure/Network/NetworkService.swift`
  - [ ] Alamofire `AF.request` 래핑
  - [ ] `.validate().responseDecodable` 처리
  - [ ] 실패 시 `AppError.network(error.localizedDescription)` 반환
- [ ] 기존 `ApiRouter.swift` 는 `Infrastructure/Network/` 로 이동 후 유지
- [ ] 기존 `ApiService.swift` 정적 메서드들을 NetworkService로 대체 준비

---

### 3-4. Repository 구현 — WordRepositoryImpl, WordBookRepositoryImpl

- [ ] `Data/Repositories/WordRepositoryImpl.swift`
  - [ ] `WordRepositoryInterface` 채택
  - [ ] WordMapper 생성자 주입
  - [ ] `fetchAll()`: `realm.objects(WordObject.self)` → Mapper → `Single<[Word]>`
  - [ ] `fetch(id:)`: id String → ObjectId 변환, `realm.object(ofType:)` → `Single<Word?>`
  - [ ] `save(_ word:, toBookId:)`: Mapper → `realm.write` → `Completable`
  - [ ] `update(_ word:)`: `realm.write { object.word = ..., object.meaning = ... }` → `Completable`
  - [ ] `delete(id:)`: `realm.write { realm.delete(object) }` → `Completable`
  - [ ] **`try!` 완전 제거** → `do { let realm = try Realm() } catch { observer(.error(AppError.database(...))) }`
- [ ] `Data/Repositories/WordBookRepositoryImpl.swift`
  - [ ] `WordBookRepositoryInterface` 채택
  - [ ] WordMapper, WordBookMapper 생성자 주입
  - [ ] `fetchAll()`, `fetch(id:)`, `create(title:)`, `update(id:title:)`, `delete(id:)`, `addWord(_:toBookId:)` 구현
  - [ ] `addWord`: `realm.write { wordBookObject.wordList.append(wordObject) }`
  - [ ] **`try!` 완전 제거**

---

### 3-5. Repository 구현 — LearningHistoryRepositoryImpl

- [ ] `Data/Repositories/LearningHistoryRepositoryImpl.swift`
  - [ ] `LearningHistoryRepositoryInterface` 채택
  - [ ] LearningHistoryMapper 생성자 주입
  - [ ] `save(_ history:)`: Mapper → `realm.write { realm.add(obj) }` → `Completable`
  - [ ] `fetchAll(wordId:)`: `filter("wordObjectId == %@", objectId)` → Mapper → `Single<[LearningHistory]>`
  - [ ] `deleteAll(wordId:)`: 해당 wordId 전체 삭제 → `Completable`
  - [ ] `fetchAccuracy(wordId:)`: isCorrect 비율 계산 → `Single<Double>` (기록 없으면 0.0)
  - [ ] **`LearningHistoryObject` 버그 확인**: `createAt = learningDate` 올바르게 처리됐는지 검증

---

### 3-6. Repository 구현 — UserPreferencesImpl

- [ ] `Data/Repositories/UserPreferencesImpl.swift`
  - [ ] `UserPreferencesInterface` 채택
  - [ ] `UserDefaultsKey` enum으로 키 상수 관리
  - [ ] `init()`: UserDefaults에서 초기 `ActiveBookIdentifier` 복원 → `BehaviorRelay` 초기화
  - [ ] `var activeBookIdentifier: Observable<ActiveBookIdentifier?>` — `activeBookRelay.asObservable()`
  - [ ] `setActiveBook`: UserDefaults 저장 + Relay accept (동기화 보장)
  - [ ] `getUsername()`, `setUsername()` 구현
  - [ ] `getThemeUrl()`, `setThemeUrl()` 구현
  - [ ] `getUserId()`, `setUserId()` 구현
  - [ ] 기존 `UserInfoManager`의 UserDefaults 키 이름과 동일하게 설정 (데이터 마이그레이션 없이 호환)

---

### 3-7. Repository 구현 — ImageSearchRepositoryImpl, TranslationRepositoryImpl, RecommendBookRepositoryImpl

- [ ] `Data/Repositories/ImageSearchRepositoryImpl.swift`
  - [ ] `ImageSearchRepositoryInterface` 채택
  - [ ] NetworkService, ThemeImageMapper 생성자 주입
  - [ ] `search(query:page:)` → `networkService.request(ApiRouter.searchPhoto(...), type: SearchPhotoDTO.self)` → Mapper → `Single<[ThemeImage]>`
  - [ ] 에러 시 `AppError.network`로 변환
- [ ] `Data/Repositories/TranslationRepositoryImpl.swift`
  - [ ] `TranslationRepositoryInterface` 채택
  - [ ] `translate(text:targetLanguage:)` → `networkService.request(ApiRouter.translate(...))` → `Single<String>`
- [ ] `Data/Repositories/RecommendBookRepositoryImpl.swift`
  - [ ] `RecommendBookRepositoryInterface` 채택
  - [ ] 기존 Mock 데이터 유지
  - [ ] 반환 타입만 `Single<[WordBook]>` / `Single<WordBook?>` 으로 변경

---

## Phase 4 — Coordinator 패턴 구현

### 4-1. Coordinator 프로토콜 및 AppCoordinator

- [ ] `Presentation/Coordinators/CoordinatorProtocol.swift`
  ```swift
  protocol Coordinator: AnyObject {
      var childCoordinators: [Coordinator] { get set }
      var navigationController: UINavigationController { get set }
      func start()
  }
  ```
  - [ ] `addChild(_ coordinator:)` default 구현
  - [ ] `removeChild(_ coordinator:)` default 구현
- [ ] `Presentation/Coordinators/AppCoordinator.swift`
  - [ ] `childCoordinators`, `navigationController`, `diContainer` 프로퍼티
  - [ ] `start()`: `userPreferences.getThemeUrl()` 로 온보딩 완료 여부 확인 후 분기
  - [ ] `showOnboarding()`: OnboardingCoordinator 생성 → `onCompleted` 콜백에서 removeChild + showMain
  - [ ] `showMain()`: MainCoordinator 생성 후 start
- [ ] `App/SceneDelegate.swift` 수정
  - [ ] 기존 `Coordinator enum` 삭제
  - [ ] 기존 `changeRootVC()` 메서드 삭제
  - [ ] `AppDIContainer()` 생성 → `UINavigationController()` 생성 → `AppCoordinator` 생성 → `start()`
  - [ ] `window?.rootViewController = navigationController`
  - [ ] `appCoordinator` 프로퍼티로 강한 참조 유지

---

### 4-2. OnboardingCoordinator

- [ ] `Presentation/Coordinators/OnboardingCoordinator.swift`
  - [ ] `var onCompleted: (() -> Void)?` 콜백 프로퍼티
  - [ ] `start()`: SearchThemeViewModel 생성 (`diContainer.makeSearchThemeViewModel()`) → SearchThemeViewController push
  - [ ] `vm.onThemeSelected` 콜백에서 `showSetUserName()` 호출
  - [ ] `showSetUserName()`: SetUserNameViewModel 생성 → SetUserNameViewController push
  - [ ] `vm.onCompleted` 콜백에서 `self.onCompleted?()` 호출
- [ ] `SearchThemeViewController`에서 직접 push/present 하던 코드 제거
- [ ] `SetUserNameViewController`에서 직접 화면 전환하던 코드 제거

---

### 4-3. MainCoordinator (TabBar)

- [ ] `Presentation/Coordinators/MainCoordinator.swift`
  - [ ] 탭별 `UINavigationController` 3개 생성 (wordNav, libraryNav, settingNav)
  - [ ] `UITabBarController` 설정 (viewControllers, tabBarItem 아이콘/타이틀)
  - [ ] `UITabBarAppearance` 로 탭바 스타일 적용 (iOS 15+ 대응)
  - [ ] `WordCoordinator`, `LibraryCoordinator`, `SettingCoordinator` 각각 생성 후 `addChild` + `start()`
  - [ ] `navigationController.setViewControllers([tabBarController], animated: false)`
- [ ] 기존 `MainTabViewController` 역할 검토 후 제거 또는 축소

---

### 4-4. WordCoordinator

- [ ] `Presentation/Coordinators/WordCoordinator.swift`
  - [ ] `start()`: WordTabViewModel 생성 → 콜백 설정 → WordTabViewController 설정
    - [ ] `vm.onStartQuiz`: `showSelectQuiz(wordBook:)` 호출
    - [ ] `vm.onAddWord`: `showAddWord(wordBook:)` 호출
    - [ ] `vm.onSelectWordBook`: `showMyBookList()` 호출
  - [ ] `showSelectQuiz(wordBook:)`: SelectQuizViewModel 생성 → SelectQuizViewController push
    - [ ] `vm.onModeSelected`: QuizCoordinator 생성 후 start
  - [ ] `showAddWord(wordBook:)`: AddWordViewController modal present
  - [ ] `showMyBookList()`: LibraryCoordinator의 내 단어장으로 이동 또는 별도 처리

---

### 4-5. QuizCoordinator / LibraryCoordinator / SettingCoordinator

- [ ] `Presentation/Coordinators/QuizCoordinator.swift`
  - [ ] `var onCompleted: (() -> Void)?`
  - [ ] `start()`: ChoiceQuizViewModel 생성 → ChoiceQuizViewController push
  - [ ] `vm.onQuizCompleted`: CompleteQuizViewController push
  - [ ] `CompleteQuizViewModel.onRetry`: 퀴즈 재시작 (start() 재호출)
  - [ ] `CompleteQuizViewModel.onFinish`: `onCompleted?()` 호출 후 pop
- [ ] `Presentation/Coordinators/LibraryCoordinator.swift`
  - [ ] `start()`: LibraryTabViewController 설정
  - [ ] `showBookList()`: BookListViewController push (추천 단어장)
  - [ ] `showMyBookList()`: MyBookListViewController push
  - [ ] `showMyBookDetail(book:)`: MyBookDetailViewController push
  - [ ] `showCreateBook(existing:)`: CreateBookViewController modal present
  - [ ] `showAddWord(wordBook:)`: AddWordViewController modal present
  - [ ] Modal dismiss 시 `removeChild` 처리
- [ ] `Presentation/Coordinators/SettingCoordinator.swift`
  - [ ] `start()`: SettingTabViewController 설정
  - [ ] `showOpenSourceLicenses()`: OpenSourceLicenseListViewController push

---

## Phase 5 — DI Container 구현

- [ ] `App/DI/AppDIContainer.swift` 작성
  - [ ] **Infrastructure** lazy 프로퍼티
    - [ ] `networkService: NetworkServiceInterface`
  - [ ] **Mappers** lazy 프로퍼티
    - [ ] `wordMapper: WordMapper`
    - [ ] `wordBookMapper: WordBookMapper` (wordMapper 주입)
    - [ ] `learningHistoryMapper: LearningHistoryMapper`
    - [ ] `themeImageMapper: ThemeImageMapper`
  - [ ] **Repositories** lazy 프로퍼티 (앱 생명주기 동안 단일 인스턴스)
    - [ ] `userPreferences: UserPreferencesInterface`
    - [ ] `wordRepository: WordRepositoryInterface`
    - [ ] `wordBookRepository: WordBookRepositoryInterface`
    - [ ] `learningHistoryRepository: LearningHistoryRepositoryInterface`
    - [ ] `imageSearchRepository: ImageSearchRepositoryInterface`
    - [ ] `translationRepository: TranslationRepositoryInterface`
    - [ ] `recommendBookRepository: RecommendBookRepositoryInterface`
  - [ ] **ViewModel Factory 메서드** (매 호출 시 새 인스턴스)
    - [ ] `makeWordTabViewModel() -> WordTabViewModel`
    - [ ] `makeAddWordViewModel(wordBook:) -> AddWordViewModel`
    - [ ] `makeChoiceQuizViewModel(wordBook:) -> ChoiceQuizViewModel`
    - [ ] `makeCompleteQuizViewModel(result:) -> CompleteQuizViewModel`
    - [ ] `makeSelectQuizViewModel(wordBook:) -> SelectQuizViewModel`
    - [ ] `makeBookListViewModel() -> BookListViewModel`
    - [ ] `makeMyBookListViewModel() -> MyBookListViewModel`
    - [ ] `makeMyBookDetailViewModel(wordBook:) -> MyBookDetailViewModel`
    - [ ] `makeCreateBookViewModel(existing:) -> CreateBookViewModel`
    - [ ] `makeSearchThemeViewModel() -> SearchThemeViewModel`
    - [ ] `makeSetUserNameViewModel() -> SetUserNameViewModel`
    - [ ] `makeSettingTabViewModel() -> SettingTabViewModel`
    - [ ] `makeWordImageListViewModel() -> WordImageListViewModel`

---

## Phase 6 — ViewModel 리팩토링

### 공통 적용 원칙 (전체 ViewModel)
- [ ] 모든 ViewModel에서 `UserInfoManager.shared` 참조 제거
- [ ] 모든 ViewModel에서 `ActiveLearningManager.shared` 참조 제거
- [ ] 모든 ViewModel에서 `ToastManager.shared.show(...)` 직접 호출 제거
- [ ] 모든 ViewModel Output에 `errorMessage: Signal<String>` 추가
- [ ] 모든 ViewModel에 Coordinator 콜백 프로퍼티 추가 (`var onXxx: (() -> Void)?`)
- [ ] `DispatchQueue` 사용 전면 제거 → RxSwift 스케줄러로 대체

---

### 6-1. WordTabViewModel

- [ ] 생성자 의존성 변경
  - [ ] `fetchWordsUseCase: FetchWordsUseCaseInterface`
  - [ ] `getActiveBookUseCase: GetActiveBookUseCaseInterface`
- [ ] Coordinator 콜백 추가
  - [ ] `var onStartQuiz: ((WordBook) -> Void)?`
  - [ ] `var onAddWord: ((WordBook) -> Void)?`
  - [ ] `var onSelectWordBook: (() -> Void)?`
- [ ] Input 정리
  - [ ] `viewWillAppear: Observable<Void>`
  - [ ] `quizButtonTapped: Observable<Void>`
  - [ ] `addWordButtonTapped: Observable<Void>`
  - [ ] `selectWordBookTapped: Observable<Void>`
  - [ ] `deleteLearningHistoryTapped: Observable<Word>`
- [ ] Output 정리
  - [ ] `wordItems: Driver<[Word]>`
  - [ ] `activeBookTitle: Driver<String>`
  - [ ] `isEmpty: Driver<Bool>`
  - [ ] `errorMessage: Signal<String>`
- [ ] `transform` 구현
  - [ ] `getActiveBookUseCase.execute().share(replay: 1)` 로 활성 책 스트림
  - [ ] `quizButtonTapped` → `withLatestFrom(activeBook)` → `onStartQuiz?(wordBook)` 호출
  - [ ] `addWordButtonTapped` → `onAddWord?(wordBook)` 호출
  - [ ] `selectWordBookTapped` → `onSelectWordBook?()` 호출

---

### 6-2. AddWordViewModel

- [ ] 생성자 의존성 변경
  - [ ] `saveWordUseCase: SaveWordUseCaseInterface`
  - [ ] `updateWordUseCase: UpdateWordUseCaseInterface`
  - [ ] `searchImagesUseCase: SearchImagesUseCaseInterface`
  - [ ] `translateWordUseCase: TranslateWordUseCaseInterface`
  - [ ] `wordBook: WordBook`
  - [ ] `existingWord: Word?` (수정 모드)
- [ ] Coordinator 콜백: `var onCompleted: (() -> Void)?`
- [ ] Input 정리
  - [ ] `wordTextField: Observable<String>`
  - [ ] `meaningTextField: Observable<String>`
  - [ ] `selectedImage: Observable<ThemeImage?>`
  - [ ] `saveButtonTapped: Observable<Void>`
  - [ ] `translateButtonTapped: Observable<Void>`
  - [ ] `searchImageTapped: Observable<String>`
- [ ] Output 정리
  - [ ] `translatedMeaning: Driver<String>`
  - [ ] `imageSearchResults: Driver<[ThemeImage]>`
  - [ ] `isSaveEnabled: Driver<Bool>`
  - [ ] `saveCompleted: Signal<Void>`
  - [ ] `errorMessage: Signal<String>`
  - [ ] `isLoading: Driver<Bool>`
- [ ] `ApiService` 정적 메서드 참조 완전 제거
- [ ] 번역 자동실행: `wordTextField.debounce(.milliseconds(300), scheduler: MainScheduler.instance)`
- [ ] 수정 모드: `existingWord != nil` 이면 update, nil이면 save

---

### 6-3. ChoiceQuizViewModel

- [ ] 생성자 의존성 변경
  - [ ] `generateQuizUseCase: GenerateQuizUseCaseInterface`
  - [ ] `submitAnswerUseCase: SubmitAnswerUseCaseInterface`
  - [ ] `wordBook: WordBook`
- [ ] Coordinator 콜백: `var onCompleted: ((QuizResult) -> Void)?`
- [ ] 내부 상태 이동 (UserInfoManager에서 제거)
  - [ ] `questions: [QuizQuestion]` (GenerateQuizUseCase로 초기화)
  - [ ] `currentIndex: BehaviorRelay<Int>(value: 0)`
  - [ ] `answers: [String]` (제출 답변 누적)
- [ ] Input 정리
  - [ ] `viewDidLoad: Observable<Void>`
  - [ ] `choiceSelected: Observable<String>`
  - [ ] `nextButtonTapped: Observable<Void>`
- [ ] Output 정리
  - [ ] `currentQuestion: Driver<QuizQuestion>`
  - [ ] `progress: Driver<Float>`
  - [ ] `choices: Driver<[String]>`
  - [ ] `answerResult: Signal<Bool>`
  - [ ] `quizCompleted: Signal<QuizResult>`
- [ ] `quizCompleted` Signal 발생 시 `onCompleted?(result)` 호출
- [ ] `UserInfoManager` 퀴즈 상태 저장 로직 완전 제거

---

### 6-4. CompleteQuizViewModel

- [ ] 생성자 의존성 변경
  - [ ] `result: QuizResult` (ChoiceQuizViewModel에서 직접 전달)
  - [ ] UserInfoManager 참조 완전 제거
- [ ] Coordinator 콜백
  - [ ] `var onRetry: (() -> Void)?`
  - [ ] `var onFinish: (() -> Void)?`
- [ ] Input 정리
  - [ ] `retryButtonTapped: Observable<Void>`
  - [ ] `finishButtonTapped: Observable<Void>`
- [ ] Output 정리
  - [ ] `totalCount: Driver<Int>`
  - [ ] `correctCount: Driver<Int>`
  - [ ] `accuracy: Driver<String>` ("75%" 형식)
  - [ ] `incorrectWords: Driver<[Word]>`
- [ ] `retryButtonTapped` → `onRetry?()` 호출
- [ ] `finishButtonTapped` → `onFinish?()` 호출
- [ ] UserDefaults 결과 저장 로직 완전 제거

---

### 6-5. BookListViewModel

- [ ] 생성자 의존성 변경
  - [ ] `fetchRecommendBooksUseCase: FetchRecommendBooksUseCaseInterface`
  - [ ] `fetchMyBooksUseCase: FetchWordBooksUseCaseInterface`
  - [ ] `copyWordBookUseCase: CopyWordBookUseCaseInterface`
  - [ ] `setActiveBookUseCase: SetActiveBookUseCaseInterface`
- [ ] Coordinator 콜백: `var onBookSelected: ((WordBook) -> Void)?`
- [ ] Input 정리
  - [ ] `viewWillAppear: Observable<Void>`
  - [ ] `downloadBookTapped: Observable<WordBook>`
  - [ ] `selectBookTapped: Observable<WordBook>`
- [ ] Output 정리
  - [ ] `recommendItems: Driver<[WordBook]>`
  - [ ] `myBooks: Driver<[WordBook]>`
  - [ ] `isLoading: Driver<Bool>`
  - [ ] `downloadCompleted: Signal<String>`
  - [ ] `errorMessage: Signal<String>`
- [ ] `DispatchQueue.main.async` 중첩 완전 제거
  - [ ] `copyWordBookUseCase.execute()` → `.subscribe(on: ConcurrentDispatchQueueScheduler)` → `.observe(on: MainScheduler.instance)`
- [ ] `ActiveLearningManager.shared` 제거 → `setActiveBookUseCase` 사용

---

### 6-6. MyBookListViewModel, MyBookDetailViewModel

- [ ] **MyBookListViewModel** 리팩토링
  - [ ] 생성자: `fetchWordBooksUseCase`, `deleteWordBookUseCase`, `setActiveBookUseCase`
  - [ ] Coordinator 콜백: `onBookSelected`, `onCreateBook`
  - [ ] Input: `viewWillAppear`, `deleteTapped: Observable<WordBook>`, `selectTapped: Observable<WordBook>`
  - [ ] Output: `bookList: Driver<[WordBook]>`, `deleteError: Signal<String>`
- [ ] **MyBookDetailViewModel** 작성 (기존 ViewController 내 로직 분리)
  - [ ] 생성자: `fetchWordsUseCase`, `deleteWordUseCase`, `wordBook: WordBook`
  - [ ] Coordinator 콜백: `onStartQuiz`, `onAddWord`, `onEditWord`
  - [ ] Input: `viewWillAppear`, `deleteWordTapped`, `quizTapped`, `addWordTapped`
  - [ ] Output: `words: Driver<[Word]>`, `bookTitle: Driver<String>`, `errorMessage: Signal<String>`

---

### 6-7. CreateBookViewModel, SelectQuizViewModel

- [ ] **CreateBookViewModel** 리팩토링
  - [ ] 생성자: `createWordBookUseCase`, `updateWordBookUseCase`, `existingBook: WordBook?`
  - [ ] Coordinator 콜백: `var onCompleted: ((WordBook) -> Void)?`
  - [ ] Input: `titleTextField: Observable<String>`, `saveButtonTapped: Observable<Void>`
  - [ ] Output: `isCreateButtonEnabled: Driver<Bool>`, `saveCompleted: Signal<WordBook>`, `errorMessage: Signal<String>`
  - [ ] 수정/생성 모드 분기 처리
- [ ] **SelectQuizViewModel** 리팩토링
  - [ ] 생성자: `wordBook: WordBook`
  - [ ] Coordinator 콜백: `var onModeSelected: ((QuizMode) -> Void)?`
  - [ ] Input: `modeSelected: Observable<QuizMode>`
  - [ ] Output: `wordBookInfo: Driver<WordBook>`

---

### 6-8. SearchThemeViewModel

- [ ] 생성자 의존성 변경
  - [ ] `searchImagesUseCase: SearchImagesUseCaseInterface`
  - [ ] `userPreferences: UserPreferencesInterface`
- [ ] Coordinator 콜백: `var onThemeSelected: (() -> Void)?`
- [ ] Input 정리
  - [ ] `searchText: Observable<String>` (debounce 500ms)
  - [ ] `loadNextPage: Observable<Void>`
  - [ ] `selectedTheme: Observable<ThemeImage>`
  - [ ] `confirmButtonTapped: Observable<Void>`
- [ ] Output 정리
  - [ ] `themeImageList: Driver<[ThemeImage]>`
  - [ ] `isConfirmEnabled: Driver<Bool>`
  - [ ] `isLoading: Driver<Bool>`
  - [ ] `errorMessage: Signal<String>`
- [ ] `ThemeImageViewData` DTO → `ThemeImage` Domain Entity 사용으로 변경
- [ ] `confirmButtonTapped` → `userPreferences.setThemeUrl` 저장 → `onThemeSelected?()` 호출
- [ ] `SearchThemeRepoProtocol` 사용 → `SearchImagesUseCase` 로 대체

---

### 6-9. SettingTabViewModel (신규), WordImageListViewModel, SetUserNameViewModel

- [ ] **SettingTabViewModel** 신규 작성
  - [ ] 생성자: `userPreferences: UserPreferencesInterface`
  - [ ] Coordinator 콜백: `onOpenSourceLicense`, `onChangeTheme`
  - [ ] Input: `viewWillAppear`, `openSourceLicenseTapped`, `changeThemeTapped`
  - [ ] Output: `username: Driver<String>`, `themeImageUrl: Driver<String?>`
- [ ] **WordImageListViewModel** 정리
  - [ ] 생성자: `searchImagesUseCase: SearchImagesUseCaseInterface`
  - [ ] Coordinator 콜백: `var onImageSelected: ((ThemeImage) -> Void)?`
  - [ ] Input: `searchText`, `loadNextPage`, `imageSelected`
  - [ ] Output: `imageList: Driver<[ThemeImage]>`, `isLoading: Driver<Bool>`
- [ ] **SetUserNameViewModel** 분리 (기존 ViewController 내 로직)
  - [ ] 생성자: `userPreferences: UserPreferencesInterface`
  - [ ] Coordinator 콜백: `var onCompleted: (() -> Void)?`
  - [ ] Input: `usernameTextField: Observable<String>`, `confirmButtonTapped: Observable<Void>`
  - [ ] Output: `isConfirmEnabled: Driver<Bool>`

---

## Phase 7 — 싱글턴 Manager 제거

### 7-1. UserInfoManager 완전 제거

- [ ] `grep -r "UserInfoManager" Danogotchi/` 로 모든 참조 파악
- [ ] 참조처별 교체
  - [ ] `.currentThemeUrl` → `userPreferences.getThemeUrl()`
  - [ ] `.username` → `userPreferences.getUsername()`
  - [ ] `.activeBookIdentifier` → `userPreferences.activeBookIdentifier` (Observable)
  - [ ] `.setActiveBook()` → `setActiveBookUseCase.execute()`
  - [ ] `.notifyWordBookUpdate()` → 제거 (RxSwift Observable 체인으로 자동 전파)
  - [ ] `.wordBookRefreshObservable` → `getActiveBookUseCase.execute()` 로 대체
  - [ ] 퀴즈 상태 (`currentQuizIndex`, `currentCorrectCount`, `currentIncorrectWordIds`) → ChoiceQuizViewModel 내부 상태로 완전 이동
- [ ] `Protocols/UserInfoProtocol.swift` 삭제
- [ ] `Managers/UserInfoManager.swift` 삭제
- [ ] 빌드 에러 0개 확인

---

### 7-2. ActiveLearningManager 완전 제거

- [ ] `grep -r "ActiveLearningManager" Danogotchi/` 로 모든 참조 파악
- [ ] 참조처별 교체
  - [ ] `.activeBook` → `getActiveBookUseCase.execute()`
  - [ ] `.activeBookSource` → `ActiveBookIdentifier.source` 로 대체
  - [ ] `.setActiveBook()` → `setActiveBookUseCase.execute()`
- [ ] `WordBookSource` enum 제거 (`ActiveBookIdentifier.Source` 로 통일)
- [ ] `Managers/ActiveLearningManager.swift` 삭제
- [ ] 빌드 에러 0개 확인

---

### 7-3. ToastManager → Output Signal 바인딩 대체

- [ ] `grep -r "ToastManager" Danogotchi/ViewModels/` 로 ViewModel 내 직접 호출 파악
- [ ] 각 ViewModel의 Toast 메시지를 `errorMessage: Signal<String>` 또는 `toastMessage: Signal<String>` Output으로 노출
- [ ] `BaseViewController` 또는 각 ViewController에서 Output Signal 구독 → Toast 표시
  ```swift
  output.errorMessage
      .emit(onNext: { [weak self] message in
          ToastManager.shared.show(message)  // UI 처리는 ViewController에서
      })
      .disposed(by: disposeBag)
  ```
- [ ] ViewModel에서 `import` 및 `ToastManager` 참조 완전 제거

---

### 7-4. TTSManager 프로토콜화

- [ ] `Domain/Interfaces/TTSServiceInterface.swift` 또는 `Infrastructure/TTSServiceInterface.swift` 작성
  ```swift
  protocol TTSServiceInterface {
      func speak(_ text: String, language: String, rate: Float)
      func stop()
      func pause()
      func resume()
  }
  ```
- [ ] `TTSManager: TTSServiceInterface` 채택 추가 (싱글턴 유지)
- [ ] `AppDIContainer`에 `lazy var ttsService: TTSServiceInterface = TTSManager.shared` 추가
- [ ] TTSManager를 직접 호출하는 ViewController/ViewModel에서 생성자 주입으로 변경

---

## Phase 8 — 최종 정리 및 검증

### 8-1. 불필요 파일 삭제

- [ ] 삭제 전 각 파일에 대해 `grep -r "파일명"` 으로 참조 없음 확인
- [ ] `Danogotchi/Managers/UserInfoManager.swift` 삭제
- [ ] `Danogotchi/Managers/ActiveLearningManager.swift` 삭제
- [ ] `Danogotchi/Protocols/WordRepositoryProtocol.swift` 삭제 (Interface로 대체)
- [ ] `Danogotchi/Protocols/WordBookRepositoryProtocol.swift` 삭제
- [ ] `Danogotchi/Protocols/LearningHistoryRepositoryProtocol.swift` 삭제
- [ ] `Danogotchi/Protocols/SearchThemeRepoProtocol.swift` 삭제
- [ ] `Danogotchi/Protocols/RecommendBookRepoProtocol.swift` 삭제
- [ ] `Danogotchi/Protocols/UserInfoProtocol.swift` 삭제
- [ ] `Danogotchi/ViewData/Word.swift` 삭제 (Domain/Entities로 대체)
- [ ] `Danogotchi/ViewData/WordBook.swift` 삭제
- [ ] `Danogotchi/ViewData/LearningHistoryModel.swift` 삭제
- [ ] `Danogotchi/Entities/SearchPhotoEntity.swift` 삭제 (ThemeImage로 대체)
- [ ] 구 `Utils/ApiService.swift` 삭제 (NetworkService로 대체)

---

### 8-2. 에러 처리 전수 검사

- [ ] `grep -r "try!" Danogotchi/` → 0개 목표 (SystemAPI 등 불가피한 경우 제외)
- [ ] `grep -r "try?" Danogotchi/Repositories/` → Completable.error 로 전환
- [ ] `Single<Result<T, Error>>` 반환 타입 → `Single<T>` 로 통일 (에러는 onError)
- [ ] 모든 ViewModel Output에 `errorMessage: Signal<String>` 존재 확인
- [ ] 모든 ViewController에서 `errorMessage` 구독 및 사용자 노출 확인
- [ ] `AppError` 의 모든 케이스가 실제로 사용되는지 확인

---

### 8-3. GCD 완전 제거

- [ ] `grep -r "DispatchQueue" Danogotchi/ViewModels/` → 0개 목표
- [ ] `grep -r "DispatchQueue" Danogotchi/Repositories/` → 0개 목표
- [ ] 남은 DispatchQueue 사용처 RxSwift 스케줄러로 전환
  - [ ] `DispatchQueue.main.async` → `.observe(on: MainScheduler.instance)`
  - [ ] `DispatchQueue.global().async` → `.subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background))`

---

### 8-4. 전체 빌드 및 화면별 동작 테스트

- [ ] `xcodebuild -scheme Danogotchi-dev build` 에러 0개
- [ ] `xcodebuild -scheme Danogotchi build` (Release) 에러 0개
- [ ] **온보딩 플로우**
  - [ ] 앱 첫 실행 → SearchThemeViewController → SetUserNameViewController → WordTabViewController
  - [ ] 온보딩 완료 후 재실행 → 바로 WordTabViewController 진입
- [ ] **단어 탭**
  - [ ] 활성 단어장의 단어 목록 정상 표시
  - [ ] 단어장 없을 때 빈 상태 표시
- [ ] **단어 추가**
  - [ ] 단어 입력 → 번역 자동입력 (debounce)
  - [ ] 이미지 검색 → 선택
  - [ ] 저장 완료 후 목록 자동 갱신
- [ ] **단어 수정** — 기존 데이터 로드, 수정 후 저장
- [ ] **퀴즈**
  - [ ] 단어장 선택 → 모드 선택 → 문제 풀기 → 결과 확인
  - [ ] 재시작 버튼 동작
  - [ ] 정답/오답 LearningHistory 저장 확인
- [ ] **추천 단어장** — 목록 표시 → 내 단어장에 추가
- [ ] **내 단어장** — 생성 → 단어 추가 → 삭제
- [ ] **단어장 활성화** — 선택 시 WordTab에 즉시 반영
- [ ] **설정 탭** — 사용자명, 테마 표시
- [ ] **오픈소스 라이선스 화면** 정상 표시
- [ ] **Coordinator 메모리 누수 확인**
  - [ ] 뒤로가기 후 childCoordinators에서 제거 확인
  - [ ] Modal dismiss 후 메모리 해제 확인
  - [ ] `deinit` 로그로 ViewController, ViewModel, Coordinator 해제 확인

---

## 진행 현황 요약

| Phase | 설명 | 상태 |
|-------|------|------|
| Phase 1 | 프로젝트 구조 + Domain 계층 수립 | ⬜ 대기 |
| Phase 2 | UseCase 계층 구현 | ⬜ 대기 |
| Phase 3 | Data 계층 (Mapper + Repository) | ⬜ 대기 |
| Phase 4 | Coordinator 패턴 구현 | ⬜ 대기 |
| Phase 5 | DI Container 구현 | ⬜ 대기 |
| Phase 6 | ViewModel 리팩토링 (9개) | ⬜ 대기 |
| Phase 7 | 싱글턴 Manager 제거 | ⬜ 대기 |
| Phase 8 | 최종 정리 및 검증 | ⬜ 대기 |

> 완료된 Phase는 `⬜ 대기` → `✅ 완료` 로 변경
