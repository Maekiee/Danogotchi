# 코딩 컨벤션 (현재 코드 기준)

## 네이밍 / 파일

- 클래스는 기본 `final class` (상속 명시적으로 허용할 때만 비-final)
- ViewModel: `*ViewModel` / Repository: 프로토콜은 접미사 없이 도메인명 그대로(`VocabBookRepository`) + 구현체는 `Default` 접두사(`DefaultVocabBookRepository`) / Coordinator: `*Coordinator` + `*CoordinatorDelegate`
- 폴더 구조 단위는 **Feature(도메인)** > **View / ViewModel / Components / Coordinator** > 파일.

## Swift 스타일

- 의존성은 `private let`으로 보유, 생성자 주입.
- 옵셔널: 안전한 분기는 `guard let`. 강제 언래핑은 현재 코드에 없으니 새로 도입하지 않는다(ID는 전부 `UUID`).
- MARK 주석 적극 사용: `// MARK: - <영역>` 으로 코드 섹션 분리.
- 한국어 주석 허용 (예: `// "나의 단어장"이 없는 경우 빈 배열 처리`). 의도/도메인 맥락 설명에 집중.

## 로깅 컨벤션

- **`print` / `NSLog` / `debugPrint` 금지.** 로그는 전부 `Core/Utils/AppLogger`(OSLog `Logger` 래퍼)를 경유한다. 쓰는 파일에 `import OSLog`를 추가한다.
- subsystem은 번들 ID라서 Dev(`com.maekie.Danogotchi.dev`)/Release 로그가 Console.app에서 자동 분리된다.
- 카테고리는 5종. 새로 만들지 말고 아래에서 고른다:
  | 카테고리 | 용도 |
  |---|---|
  | `AppLogger.lifecycle` | 화면 생성/해제 트레이스 (`BaseViewController`) |
  | `AppLogger.database` | CoreData 저장·시드 |
  | `AppLogger.network` | Unsplash 등 원격 통신 |
  | `AppLogger.push` | FCM 토큰·푸시 |
  | `AppLogger.ui` | 탭·메일 컴포저 등 UI 이벤트 |
- 레벨: 개발용 트레이스는 `.debug`, 실패는 `.error`. `.debug`은 릴리스에서 기본 수집되지 않으므로 **`#if DEBUG` 가드를 따로 두지 않는다**.
- privacy: OSLog는 문자열·객체 보간을 기본 `<private>`로 가린다. 진단에 필요한 **에러 상세만 `privacy: .public`** 을 붙이고, 사용자 데이터(단어·검색어 등)는 기본값을 유지한다.
- 에러는 `\(error)`를 직접 보간할 수 없다(OSLog 보간 오버로드 없음). `\(String(describing: error), privacy: .public)`을 쓴다 — `localizedDescription`은 CoreData `NSError`의 validation 상세를 잃는다.
- **토큰·자격증명은 값 자체를 로그에 남기지 않는다.** 성공/실패 여부만 기록한다.

## Rx 컨벤션

- Output 외부 노출: `Driver<T>` (메인 스레드 + 에러 X 보장).
- 내부 상태/뮤터블: `BehaviorRelay<T>`.
- 구독은 `bind(with: self) { owner, value in ... }` 패턴 (강한 참조 회피).
- `DisposeBag`은 ViewModel/VC 단위 1개씩 보유.

## DesignSystem 컨벤션

- 색/폰트/여백/반경 하드코딩 금지. `Shared/DesignSystem/Tokens/`의 `AppColor` / `AppFont` / `AppSpacing` / `AppRadius` / `AppBorder`만 쓴다.
- `AppColor`는 3층 — Palette(원시) / Semantic(`background`·`textPrimary`·`card`·`primary`) / Legacy.
  **화면·컴포넌트는 Semantic만 참조**한다. Legacy는 점진 교체 대상이라 신규 사용 금지.
- 폰트는 Pretendard. 역할 토큰(`AppFont.body` 등)을 쓰고 `.systemFont(ofSize:)`는 새로 도입하지 않는다.
- 2개 이상 화면에서 쓰는 UI 컴포넌트는 `Shared/DesignSystem/Components/`(`PrimaryButton`·`RoundedTextField` 등)에 둔다.

## MVVM 컨벤션

- ViewModel은 `BaseViewModel` 채택 + `Input` / `Output` struct 정의 + `transform(input:) -> Output` 단일 진입점.
- ViewController는 ViewModel 인스턴스를 **생성자 주입**으로만 받는다(스토리보드/세그웨이 X).
- ViewController는 `BaseViewController`를 상속하고 `UIConfigurationLayout`의 `configHierarchy()` / `configLayout()` / `configView()`를 override한 뒤 `viewDidLoad`에서 이 순서로 호출한다 (addSubview → SnapKit 제약 → 속성 설정).
- 화면 전환은 ViewController에서 직접 하지 않고 delegate를 통해 Coordinator에 위임.

## Coordinator 컨벤션

- `Coordinator` 프로토콜: `navigationController`, `childCoordinators`, `start()` 필수 구현.
- `addChild` / `removeChild` 헬퍼는 protocol extension 제공 — 직접 배열 조작 금지.
- 화면 흐름 메서드는 `show*` / `start*Flow` 명명.

## Repository 컨벤션

- 프로토콜은 `Shared/Domain/Interfaces/Repositories/`, `Default*` 구현체는 `Shared/Data/Repositories/`에 둔다.
- ViewModel은 Repository를 직접 받지 않고 UseCase 프로토콜을 경유한다. 외부 의존성이 없는 UI 상태 로직과 상태 없는 Domain Policy에는 형식적인 UseCase를 만들지 않는다.
- CRUD 메서드 네이밍: `readAll()` / `fetch*` / `create*` / `update*` / `delete(id:)`.
- CoreData Entity → Domain은 `toDomain()`, Domain 전체 반영은 필요한 경우 `apply(_:)`, 네트워크 DTO → Domain은 현재 `toEntity()`를 쓴다. 사용하지 않는 역방향 Mapper는 만들지 않는다.
- 새 Repository/UseCase를 만들면 반드시 `AppDIContainer`에 `make*()` 추가.

## DI 컨벤션

- `AppDIContainer` 본체 init에는 Manager 싱글턴 보유까지만, 도메인별 팩토리는 `extension`으로 분리 (`// MARK: - Explore/Library/Quiz/Setting`).
- ViewModel/Repository/UseCase 생성은 반드시 `AppDIContainer.make*` 경유.

