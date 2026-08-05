# 절대 규칙
> **허락 없이 코드 수정 금지.**
> Claude는 사용자의 명시적 승인이 있기 전까지 어떤 소스 파일도 수정·생성·삭제하지 않는다.
- 파일 읽기, 검색(`grep`/`Read`), 분석, 빌드 명령 확인은 자유롭게 수행 가능하다.
- 수정 제안은 **diff 또는 설계안 형태로 먼저 제시**하고, 사용자가 "적용해줘", "고쳐줘" 등 명시적으로 승인한 뒤에만 `Edit`/`Write` 도구를 사용한다.
- 리팩토링 범위가 모호하거나 여러 파일에 걸친 변경이 필요한 경우, 먼저 계획을 보여주고 합의한 뒤 진행한다.
- 단, **CLAUDE.md / 문서 파일 수정**과 같이 사용자가 직접 요청한 작업은 위 규칙의 예외다.

# 프로젝트 개요
**Danogotchi (단어고치)** — iOS 단어 학습 앱 (iOS 16.0+, iPhone only)
- Swift 5.0 / UIKit 기반 프로그래매틱 UI (스토리보드 없음)
- 데이터는 전부 로컬 CoreData(추천 단어장 포함 시드). 원격 호출은 테마 이미지용 Unsplash REST 뿐이며, Firestore는 `AppDelegate`에서 초기화만 하고 미사용.

# 빌드
```bash
xcodebuild -scheme Danogotchi-dev build   # Debug — 단어고치[DEV]
xcodebuild -scheme Danogotchi build        # Release — com.maekie.Danogotchi
```

Xcode: 시뮬레이터 또는 실기기 선택 후 ⌘R.
**신규 클론은 `Danogotchi/App/Secret/`(gitignore)에 `Secret.swift`·`Secrets.xcconfig`·환경별 `GoogleService-Info.plist`를 배치해야 빌드된다** — 상세는 `docs/environment.md`.

> 현재 스프린트 계획·진행률은 루트 `TODO.md`.

# 아키텍처 / 도메인

@docs/architecture.md

# 참고 문서 (필요 시 Read)
- `docs/conventions.md` — 코딩 컨벤션 (네이밍 / Swift 스타일 / Rx / MVVM / Coordinator / Repository / DI). **코드 작성·리뷰 시 참조.**
- `docs/environment.md` — 빌드 환경(Dev/Release 스킴), 로컬 DB(CoreData), 테스트 상태, SPM 의존성, 컬렉션뷰/UI 메모. **환경·의존성·셀 레이아웃 작업 시 참조.**

