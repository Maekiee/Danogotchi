# 코딩 컨벤션 (현재 코드 기준)

## 네이밍 / 파일

- 클래스는 기본 `final class` (상속 명시적으로 허용할 때만 비-final)
- ViewModel: `*ViewModel` / Repository: 프로토콜은 접미사 없이 도메인명 그대로(`WordBookRepository`) + 구현체는 `Default` 접두사(`DefaultWordBookRepository`) / Coordinator: `*Coordinator` + `*CoordinatorDelegate`
- 폴더 구조 단위는 **Feature(도메인)** > **MVVM 폴더(View/ViewModel/Model)** > 파일.
- 폴더명 `Presentaion` 오타는 그대로 유지(전수 변경 전까지).

## Swift 스타일

- 의존성은 `private let`으로 보유, 생성자 주입.
- 옵셔널: 안전한 분기는 `guard let`, 강제 언래핑(`try!`, `!`)은 ID 변환 등 불변 보장 영역에서만 (`try! ObjectId(string:)` 패턴 존재).
- MARK 주석 적극 사용: `// MARK: - <영역>` 으로 코드 섹션 분리.
- 한국어 주석 허용 (예: `// "나의 단어장"이 없는 경우 빈 배열 처리`). 의도/도메인 맥락 설명에 집중.

## Rx 컨벤션

- Output 외부 노출: `Driver<T>` (메인 스레드 + 에러 X 보장).
- 내부 상태/뮤터블: `BehaviorRelay<T>`.
- 구독은 `bind(with: self) { owner, value in ... }` 패턴 (강한 참조 회피).
- `DisposeBag`은 ViewModel/VC 단위 1개씩 보유.

## MVVM 컨벤션

- ViewModel은 `BaseViewModel` 채택 + `Input` / `Output` struct 정의 + `transform(input:) -> Output` 단일 진입점.
- ViewController는 ViewModel 인스턴스를 **생성자 주입**으로만 받는다(스토리보드/세그웨이 X).
- 화면 전환은 ViewController에서 직접 하지 않고 delegate를 통해 Coordinator에 위임.

## Coordinator 컨벤션

- `Coordinator` 프로토콜: `navigationController`, `childCoordinators`, `start()` 필수 구현.
- `addChild` / `removeChild` 헬퍼는 protocol extension 제공 — 직접 배열 조작 금지.
- 화면 흐름 메서드는 `show*` / `start*Flow` 명명.

## Repository 컨벤션

- 프로토콜은 `Shared/Domain/Interfaces/Repositories/`, `Default*` 구현체는 `Shared/Data/Repositories/`. ViewModel은 항상 프로토콜에 의존.
- CRUD 메서드 네이밍: `readAll()` / `fetch*` / `create*` / `update*` / `delete(id:)`.
- 새 Repository를 만들면 반드시 `DIContainer`에 `make*Repository()` 추가.

## DI 컨벤션

- `DIContainer` 본체 init에는 Manager 싱글턴 보유까지만, 도메인별 팩토리는 `extension`으로 분리 (`// MARK: - Word/Library/Quiz/Setting`).
- ViewModel/Repository 생성은 반드시 `DIContainer.make*` 경유.


