# TODO — 캐릭터(펫) 기능 추가

**스프린트 목표**: 온보딩에서 캐릭터를 만들고, 캐릭터 탭에서 상태를 돌보며 학습으로 레벨을 올린다
**진행**: 착수 전 · 총 26h

> 이월: 이전 스프린트(학습하기 재설계)의 D-1(중단 시 이력 보존 수동 검증 + 알럿 문구), D-2(`StartQuizUseCase` 유닛테스트)는 미완료 상태로 남아 있다. D-2는 이번 C-5 테스트 타깃 신설과 같이 처리한다.

---

## 현재 상태 (착수 지점)

- `Feature/Character/View/CharacterViewController.swift` — 테스트 레이블 + 닫기 버튼만 있는 빈 껍데기. ViewModel 없음
- `MainCoordinator.didTapCharacter()`가 직접 present (Coordinator 없음)
- 경험치는 **이미 있다** — `ExperienceRepository`(UserDefaults 정수 1개) / `ExperiencePolicy` / `EarnExperienceUseCase.commit()`. 퀴즈 정답 시 적립까지 동작 중
- CoreData 모델에 캐릭터 엔티티 없음. 캐릭터 이미지 에셋 없음

---

## A. 도메인 · 저장소 — **9h**

### A-1. 캐릭터 도메인 모델 정의 — 2h
- [ ] `Shared/Domain/Entities/PetCharacter.swift` — `id / type / name / hunger / thirst / boredom / cleanliness / experience / lastCaredAt / createAt`
- [ ] `CharacterType` enum — 선택 가능한 캐릭터 종류 + 에셋 이름
- [ ] `CareStat` enum (`hunger` / `thirst` / `boredom` / `cleanliness`) — 4개 버튼이 같은 코드 경로를 타게 해서 액션별 중복 제거
- [ ] 스탯은 전부 `0...100` clamp. 0 = 나쁨(배고픔/목마름/심심함/더러움), 100 = 좋음

> **레벨과 기분은 저장하지 않는다** — 누적 경험치와 4개 스탯에서 파생시킨다. 저장하면 원본과 어긋날 수 있는 값이 하나 더 늘 뿐이다.

### A-2. `LevelPolicy` — 1.5h
- [ ] `level(forTotalExperience:) -> Int` / `progress(forTotalExperience:) -> Double`(0~1) / `requiredExperience(for level:) -> Int`
- [ ] 시작 레벨 0. 레벨별 필요 경험치는 증가 곡선(예: `100 * (level + 1)`) — 테이블이 아니라 공식으로 둔다
- [ ] `ExperiencePolicy`(정답당 지급량)와는 별도 파일. 지급 규칙과 소비 규칙을 섞지 않는다

### A-3. `Mood` enum + 산출 규칙 — 1.5h
- [ ] `Mood` — 행복함 / 만족함 / 배고픔 / 목마름 / 심심함 / 불쾌함 / 상쾌함 / 슬픔 / 우울함
- [ ] `Mood.from(character:)` — 가장 낮은 스탯을 기준으로 결정, 전부 높으면 행복함/만족함, 전부 낮으면 우울함
- [ ] 우선순위를 명시적으로 고정 (동점일 때 어느 기분이 이기는지)

### A-4. CoreData `CharacterEntity` + Mapper — 2h
- [ ] `Model.xcdatamodel`에 엔티티 추가 (id / type / name / hunger / thirst / boredom / cleanliness / experience / lastCaredAt / createAt)
- [ ] `CharacterMapper` — 기존 `VocabMapper` 패턴 그대로
- [ ] 캐릭터는 앱 전체에서 **1마리**. `readCharacter()`가 nil이면 온보딩 미완료로 본다

> ⚠️ in-place 모델 수정이라 기존 스토어와 호환되지 않는다 → **앱 삭제 후 재설치 필수** (팀원 기기 포함)

### A-5. `CharacterRepository` + 경험치 저장소 이전 — 2h
- [ ] `Shared/Domain/Interfaces/Repositories/CharacterRepository.swift` — `createCharacter(type:name:)` / `readCharacter()` / `updateStat(_:by:)` / `characterChanged: Observable<Void>`
- [ ] `DefaultCharacterRepository` (CoreData). 변경 신호는 값 캐시가 아니다 — 받으면 `readCharacter()`로 다시 읽는다
- [ ] `DefaultExperienceRepository`를 UserDefaults → `CharacterEntity.experience`로 이전. **`ExperienceRepository` 프로토콜은 그대로 두면 퀴즈 쪽 코드는 손대지 않는다** (해당 파일의 `ponytail:` 주석이 예고한 시점)
- [ ] `AppDIContainer`에 `characterRepository` 등록 — 변경 신호를 갖고 있으므로 `vocabBookRepository`처럼 **lazy 싱글 인스턴스**

---

## B. 온보딩 (테마 선택 이후) — **7h**

현재 플로우: 관심사 선택 → 테마 선택 → 완료. 여기에 **캐릭터 선택 → 이름 지정**을 뒤에 붙인다.

### B-1. 캐릭터 에셋 — 1h *(디자인 의존)*
- [ ] `Assets.xcassets`에 캐릭터 종류별 이미지 추가
- [ ] 종류 개수 확정 전까지는 SF Symbol 임시 대체로 진행 가능

### B-2. 캐릭터 선택 화면 — 2h
- [ ] `Feature/Onboarding/View/OnboardingCharacterViewController` + ViewModel
- [ ] `OnboardingInterestViewController`의 선택 카드 구조를 그대로 재사용 (컬렉션뷰 + 단일 선택 + 다음 버튼 활성화)

### B-3. 이름 지정 화면 — 2h
- [ ] `Feature/Onboarding/View/OnboardingCharacterNameViewController` + ViewModel
- [ ] 입력 검증: 공백만 입력 불가 / 길이 상한 (trust boundary라 생략하지 않는다)
- [ ] 완료 시 `CharacterRepository.createCharacter(type:name:)`

### B-4. Coordinator 연결 + **진입 판정 수정** — 2h
- [ ] `OnboardingCoordinator`: `didSelectTheme()` → 완료가 아니라 `showCharacterSelection()`으로 변경. 이름 지정 완료에서 `onboardingDidComplete()`
- [ ] `AppFlowCoordinator.start()`의 분기 조건 변경 — **현재 `currentThemeUrl != nil`이라, 캐릭터 온보딩 중 앱을 종료하면 캐릭터 없이 메인으로 진입한다.** `characterRepository.readCharacter() != nil` 기준으로 바꾼다
- [ ] 기존 사용자(테마는 있고 캐릭터는 없음)도 이 조건이면 자연스럽게 캐릭터 온보딩으로 들어온다 — 별도 마이그레이션 코드 불필요

---

## C. 캐릭터 탭 — **8h**

### C-1. `CharacterViewModel` (Input/Output) — 2h
- [ ] Input: `viewWillAppear` / `careTapped: Observable<CareStat>` / `closeTapped`
- [ ] Output: `characterInfo: Driver<CharacterDisplayInfo>` (이름·종류·레벨·경험치 진행률·스탯 4개·기분)
- [ ] `CharacterDisplayInfo`는 파생값까지 조립해서 내려보낸다 — VC에서 레벨/기분 계산 금지

### C-2. 상태 표시 UI — 3h
- [ ] 캐릭터 이미지 + 이름 + 기분 텍스트
- [ ] 레벨 + 경험치 게이지바 (0~100%) — `Feature/Quiz/Components/CustomProgressView` 재사용 검토, 안 맞으면 그때 새로 만든다
- [ ] 스탯 4종 게이지 (배고픔 / 목마름 / 심심함 / 청결)
- [ ] 현재의 반투명 글래스 배경 위에서 대비가 확보되는지 확인

### C-3. 돌보기 액션 4개 — 2h
- [ ] `CareForCharacterUseCase.execute(stat:) -> PetCharacter` — 버튼 4개가 `CareStat`만 바꿔 같은 UseCase를 탄다
- [ ] 버튼 4개 (밥주기 / 물주기 / 놀아주기 / 청소하기), 각각 해당 스탯 상승 후 100 clamp
- [ ] 이미 100이면 토스트로 안내 (`ToastPresentable` 이미 있음)

### C-4. 스탯 감소 — 1h *(정책 확정 후)*
- [ ] `lastCaredAt` 기준 경과 시간 × 시간당 감소량을 **읽을 때 계산**. 타이머·백그라운드 태스크 없음
- [ ] 아래 "결정 필요" 1번 참고

### C-5. 유닛테스트 — 미정 *(D-2와 합산)*
- [ ] 테스트 타깃 신설 (이전 스프린트 D-2 이월)
- [ ] `LevelPolicy` (레벨 0 시작 / 경계값 / 진행률 0~1) · `Mood.from` (스탯 조합별) · 스탯 clamp (0 미만·100 초과) · 경과 시간별 감소량
- [ ] 이월분: `StartQuizUseCase` (4개 미만 실패 / 정확히 20개 / 21개 → 20개 / 토너먼트 선정)

---

## 결정 필요 (착수 전 확답 필요)

1. **스탯 감소 정책** — 올리는 버튼만 있으면 스탯은 영원히 100에 머문다. 감소가 없으면 돌보기 자체가 무의미해진다.
   - 제안: 시간당 일정량 감소, 읽는 시점에 `lastCaredAt` 기준으로 계산. 감소 속도(예: 시간당 5)만 정하면 된다
2. **캐릭터 종류 개수와 에셋** — B-1이 디자인에 막혀 있다. 개수만 확정되면 임시 이미지로 선행 가능
3. **레벨업 연출** — 레벨이 오를 때 알럿/애니메이션이 필요한지. 필요 없으면 게이지바가 리셋되는 것으로 끝난다
4. **돌보기로도 경험치를 주는지** — 현재 경험치는 학습(퀴즈 정답)에서만 나온다. 돌보기에도 준다면 A-5에 지급 경로 추가

---

## 시간 산정

| 구간 | 시간 |
|---|---|
| A. 도메인 · 저장소 | 9h |
| B. 온보딩 | 7h |
| C. 캐릭터 탭 | 8h |
| D. 이월 (D-1 검증 + 알럿) | 1h |
| **합계** | **25h** |

---

## 이연 (이번 스프린트 범위 밖)

- `CharacterCoordinator` 신설 — 캐릭터 탭이 내부 화면 전환을 갖게 되는 시점에 만든다. 현재는 단일 화면이라 `MainCoordinator` 직접 present로 충분
- 캐릭터 탭이 `.overFullScreen`이라 닫아도 `ExploreVocabViewController`가 `viewWillAppear`를 받지 않는다 → 캐릭터 화면에서 메인에 반영될 상태를 바꾸게 되면 dismiss 완료 콜백이나 Repository 신호로 갱신을 걸어야 한다
- `ExploreVocabViewControllerDelegate.didTapCharacter()` → `exploreVocabDidTapCharacter()` 개명 (형제 메서드와 네이밍 불일치)
- `ExploreVocabViewController.swift:272`의 `print("캐릭터 탭 오픈")` 제거
- 북마크("나의 단어에 저장") — `sourceWordId` 토글 + UI 표시/숨김
