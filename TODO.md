# TODO — 캐릭터(펫) 기능

**스프린트 목표**: 테마 선택 뒤 펫을 만들고, 캐릭터 화면에서 시간에 따라 변하는 상태를 돌보며 학습 경험치로 수동 레벨업한다.

**진행**: A 도메인 규칙 · B CoreData/저장소 · C 온보딩 완료(단위 테스트 69개) · 다음은 D-1 캐릭터 ViewModel

## 현재 상태

- 캐릭터 화면은 테스트 레이블과 닫기 버튼만 있고 ViewModel이 없다. `MainCoordinator.didTapCharacter()`가 진입마다 새 인스턴스를 만들어 full-screen present 한다.
- ~~온보딩은 현재 `관심사 → 테마 → 완료`이며,~~ → C에서 `관심사 → 테마 → 알 선택 → 이름 지정 → 완료`가 됐고, 완료 여부는 `currentThemeUrl != nil && 펫 존재`로 판단한다.
- ~~퀴즈 경험치는 `ExperienceRepository`를 통해 UserDefaults의 `experienceTotalPoint`에 이미 적립되고 있다.~~ → B-4에서 `PetEntity.totalExperience`로 이관, `ExperienceRepository` 삭제.
- 알·펫 이미지 에셋은 아직 없다. C-1 알 선택 셀은 **이미지를 그리지 않고** 테두리와 가운데 텍스트만 표시하므로 `PetType.eggImageName`은 현재 참조하는 곳이 없다. `imageName`은 D-2 캐릭터 화면에서 쓴다.
- **출시는 됐지만 실사용자가 없다.** 보존할 사용자 데이터가 없으므로 CoreData 모델 버저닝과 기존 경험치 이관은 전부 하지 않고, 검증은 앱 삭제 후 재설치로 처리한다.

## 구현 기본안

- 앱에는 펫이 1마리만 존재한다. `PetEntity`가 없으면 캐릭터 온보딩 미완료로 본다.
- 돌봄 수치는 모두 `0...100`의 긍정 방향으로 통일한다: `satiety`(포만감), `hydration`(수분), `fun`(즐거움), `cleanliness`(청결). `0`은 나쁨, `100`은 좋음이다.
- 초기 돌봄 수치는 `100`, HP는 `40`, 시작 레벨과 누적 경험치는 `0`이다.
- 경험치는 기존처럼 퀴즈 완료 시에만 지급한다. 돌보기 경험치, 재화, 쿨다운은 이번 범위에 넣지 않는다.
- 레벨업은 자동 처리하지 않는다. 경험치 게이지가 100%일 때 버튼을 눌러 한 레벨씩 올린다.
- 건강(`health`)은 이번 범위에서 컬럼조차 만들지 않는다. 이번 스프린트에 읽는 곳이 한 군데도 없고, 속성 추가는 나중에 lightweight migration으로 처리되므로 HealthKit 연동 시점에 넣는다.
- HP는 생명력이다. 위험 상태에 머문 시간에 따라 감소하고 `0`이 되면 사망하며, 부활해야 다시 회복할 수 있다.
- 기분은 저장하지 않고 최신 돌봄 수치에서 계산한다. 날씨는 데이터 연동 시점에 기분 정책의 입력으로 추가한다.
- **모든 화면 로직은 UseCase를 경유한다.** ViewModel은 `PetRepository`를 직접 참조하지 않는다 — 기존 UseCase 10개와 동일한 패턴(`docs/conventions.md`).

> **시간 관리 권장안**: 로그인 시각과 최종 체류 시각은 별도로 저장하지 않는다. iOS 종료 콜백은 강제 종료 시 보장되지 않으므로, 저장된 수치와 `stateUpdatedAt` 하나로 돌봄 수치와 HP를 같은 패스에서 정산한다.

---

## A. 도메인 규칙

### A-1. 펫 모델

- [x] `Shared/Domain/Entities/Pet.swift` 정의: `id / type / name / level / totalExperience / satiety / hydration / fun / cleanliness / hp / stateUpdatedAt / createAt`
  - 정산 때마다 변형되는 유일한 엔티티라 변하는 필드는 `var`로 둔다. `id / type / name / createAt`만 `let`.
- [x] `PetType`은 선택 가능한 첫 번째 펫 1종만 정의하고 에셋 이름을 연결한다. 개발 중인 8칸의 미래 타입은 미리 만들지 않는다.
  - 임시로 `case sprout`(새싹이) / `imageName = "pet_sprout"`. 실제 에셋이 없으므로 호출부에서 `UIImage(named:) ?? UIImage(systemName: "pawprint")`로 대체한다.
- [x] `PetCareStat`을 `satiety / hydration / fun / cleanliness`으로 정의해 네 돌보기 버튼이 같은 처리 경로를 사용하게 한다.
- [x] `PetMood`를 `happy / satisfied / hungry / thirsty / bored / unpleasant / refreshed / sad / depressed`로 정의한다.
- [ ] 레벨, 누적 경험치, HP는 저장하고 기분·게이지 진행률·사망 여부·하트 표시 상태는 파생값으로 둔다.
  - `isDead`·`mood`·`progress` 완료. 하트 표시 상태만 → **D-2**
- [ ] 화면 표시 모델 `PetDisplayInfo`는 `Shared/Domain/Entities/`에 둔다. Shared의 UseCase가 반환하므로 `Feature/Character`에 두면 의존 방향이 역전된다 (`VocabDisplayInfo` 패턴).
  - 배치 규칙만 확정. 생성은 → **B-3 `FetchPetStateUseCase`** (하트 상태가 정해져야 필드가 확정된다)

### A-2. 시간 경과와 돌보기 정책

- [x] `PetStatePolicy`에서 `elapsedHours = max(0, now - stateUpdatedAt) / 3600`으로 경과 시간을 계산한다.
- [x] 정책 함수는 현재 시각을 인자로 받아 테스트 가능하게 하고 별도 `Clock` 추상화는 만들지 않는다.
- [x] 최신 수치는 `savedValue - elapsedHours * hourlyDecay`로 계산하고 `0...100`으로 제한한다.
- [x] 초기 밸런스값을 한곳에 둔다: 포만감 `-0.8/h`, 수분 `-1.0/h`, 즐거움 `-0.6/h`, 청결 `-0.4/h`.
- [x] 밥주기·물주기·놀아주기·청소하기는 먼저 같은 경과 구간의 네 돌봄 수치와 HP를 정산한 뒤 대상 수치만 `+25`하고 `100`으로 제한한다.
- [x] 대상 수치가 정산 후 이미 `100`이면 다른 수치와 HP 정산 결과만 저장하고 "이미 충분히 좋아요" 결과를 반환한다.
  - `PetCareResult.alreadyFull(Pet)` — 어느 결과든 정산된 `Pet`을 동봉해 호출부가 항상 저장하게 한다.
- [x] 현재 시각이 `stateUpdatedAt`보다 과거면 경과 시간을 `0`으로 보되 **`stateUpdatedAt`은 현재 시각으로 재동기화한다.** 되돌리지 않으면 기기 시각을 미래로 옮겼다 원복했을 때 그 미래 시점까지 상태가 완전히 얼어붙는다. 재동기화하면 시각을 과거로 돌려 감소를 회피하는 것도 원복 시 한 번에 정산된다.
- [ ] 화면 조회·포그라운드 복귀·돌보기·레벨업 시에만 한 번 계산하고 저장한다. 백그라운드 작업과 상시 타이머는 사용하지 않는다.
  - `settle` 완료. 호출 시점 결선은 → **B-3 · D-1**

### A-3. 기분 정책

- [x] 기분 판정 순서를 아래와 같이 고정해 임계값과 동점 결과를 결정적으로 만든다.
  1. 수치가 2개 이상 `45 이하`면 `depressed`(우울함)
  2. 수치가 2개 이상 `65 이하`면 `sad`(슬픔)
  3. 수치가 1개만 `65 이하`면 그 수치에 따라 `satiety → hungry / hydration → thirsty / fun → bored / cleanliness → unpleasant`
  4. 네 수치가 모두 `80 이상`이면 `happy`(행복함)
  5. 위 규칙에 해당하지 않고 청결이 `95 이상`이면 `refreshed`(상쾌함). 3번 규칙이 이미 네 수치 모두 `65 초과`를 보장하므로 나머지 수치의 별도 하한은 두지 않는다.
  6. 나머지는 `satisfied`(만족함)
- [x] 자연 방치 중에는 `refreshed`가 나타나지 않고, 청결을 높은 상태로 회복하면서 나머지 돌봄 수치도 양호할 때만 나타나는지 확인한다.
  - 200시간을 0.5시간 간격으로 훑어 미발생을 확인했다. 청결이 `95` 이상인 12.5h까지는 규칙 4가 `happy`로 선점한다.
- [x] HP·날씨는 이번 기분 산출식에서 제외한다. 사망 상태에서는 기분 대신 사망 UI를 표시한다.
  - `mood`는 사망 상태에서도 그냥 계산해 돌려준다. 사망 UI로 갈아치우는 분기는 D-2 몫.
- [x] 돌봄 수치가 `20 이하`인 위험 상태도 기분에는 반영하지 않는다. 한 수치만 바닥이면 기분은 `hungry` 수준에 머무르므로, HP가 깎이고 있다는 사실은 D-2의 위험 표시로 알린다.

### A-4. 경험치와 수동 레벨업 정책

> A-5 부활 페널티가 아래 두 공식에 의존해 함께 구현했다.

- [x] `PetLevelPolicy`에 레벨별 요구량을 `requiredExperience(level) = 100 * (level + 1)`로 정의한다. 레벨 0→1은 100, 1→2는 200, 2→3은 300 EXP가 필요하다.
- [x] 현재 레벨 시작 전 누적 요구량을 `levelStartExperience(level) = 100 * level * (level + 1) / 2`로 계산한다.
- [x] 게이지는 `(totalExperience - levelStartExperience) / requiredExperience`를 `0...1`로 제한해 계산한다.
- [ ] 누적 경험치가 다음 경계 이상일 때만 레벨업 버튼을 활성화하고, 탭 시 조건을 다시 검사한 뒤 `level += 1`만 저장한다.
  - `canLevelUp` 완료. 버튼 상태 → **D-3**, 재검사 후 저장 → **B-3 `LevelUpPetUseCase`**
- [x] 레벨업 시 누적 경험치는 차감하지 않는다. 초과 경험치는 다음 레벨 게이지로 이월하고, 여러 레벨 분량이면 한 번 승급한 뒤에도 조건을 만족하는 동안 버튼을 유지한다. 부활 페널티만 A-5의 차감 예외로 둔다.

### A-5. HP · 사망 · 부활 정책

- [x] `PetStatePolicy`에서 `hp`를 `Double`, 범위를 `0...40`, 초기값을 `40`으로 정의한다. `maxHP = 40`은 정책 상수로만 두고 CoreData 컬럼으로 저장하지 않는다.
- [x] HP는 단순 시간 경과로 감소하지 않는다. 각 돌봄 수치가 `20 이하`였던 시간당 `-0.25`를 합산한다: 위험 수치가 1개면 4시간에 1칸, 2개면 2시간에 1칸 감소한다.
- [x] 최저 수치가 `20 초과 65 이하`인 동안은 HP가 변하지 않는다.
- [x] 네 돌봄 수치가 모두 `65 초과`인 동안은 HP를 시간당 `+0.5` 회복하고 `40`으로 제한한다.
- [x] 경과 구간 안에서 각 수치가 `65`와 `20`을 통과한 시각을 구해 HP 회복·정지·감소를 시간순으로 적용한다. 조회 시점의 최종 수치 하나로 전체 경과시간을 소급 계산하지 않는다.
- [x] 구간 경계를 넘을 때마다 HP를 `0...40`으로 제한한다. 전체 회복량과 피해량을 상계한 뒤 마지막에 한 번만 제한하지 않는다.
- [x] 돌봄 수치와 HP는 같은 `stateUpdatedAt` 기준으로 한 번에 정산하고 마지막에 타임스탬프를 갱신한다. 별도 `hpUpdatedAt`은 두지 않는다.
- [x] `hp <= 0`이면 사망으로 판정하고 `0`으로 제한한다. 사망 후에는 자동 회복하지 않으며 부활만 HP를 복구한다.
- [x] 돌보기나 레벨업 직전 정산에서 HP가 `0`이 되면 요청한 액션은 적용하지 않되, **정산 결과(돌봄 수치·HP·`stateUpdatedAt`)는 저장하고** 부활 필요 결과를 반환한다.
  - 돌보기는 `PetCareResult.dead(Pet)`로 완료. **레벨업 경로는 B-3 `LevelUpPetUseCase`에서 같은 처리를 한다.**
- [ ] 표시용 칸 수는 `hp <= 0`이면 `0`, 그 외에는 `max(1, floor(hp))`로 계산한다. 완전한 하트 수는 `floor(표시용 칸 / 4)`, 남은 칸은 `표시용 칸 % 4`로 파생한다. → **D-2**
- [ ] 남은 칸 `3 / 2 / 1`은 각각 `2/3 / 1/2 / 1/3` 하트로 표시한다. `0 < hp < 1`에서도 최소 1칸인 `1/3` 하트 하나를 보장하고 `hp == 0`에서만 모두 소멸한다. → **D-2**
- [x] 부활은 사망 상태에서만 실행하고 HP를 `40`으로 복구한다. 별도 재화·쿨다운·부활 횟수 제한은 두지 않는다.
- [x] **부활 시 `50` 미만인 돌봄 수치를 `50`으로 올린다.** 사망 시점 수치를 그대로 두면 네 수치가 전부 `20` 이하라 부활 직후 `-1.0/h`로 깎여 40시간 뒤 재사망하고 페널티만 반복된다. `50`은 HP 정지 구간이라 돌볼 여유가 생긴다.
- [x] 현재 레벨의 경험치가 `0%`보다 크면 부활 시 해당 레벨 요구 경험치의 `10%`를 누적 경험치에서 차감하고 현재 레벨 시작 경험치 아래로 내려가지 않게 한다: `50% → 40%`, `5% → 0%`.
- [x] 현재 레벨의 경험치가 이미 `0%`이면 부활 시 레벨을 한 단계 내리고 낮아진 레벨의 `0%`로 맞춘다. 레벨 0에서는 더 낮추지 않고 `0%`를 유지한다.
- [x] 수동 레벨업을 미룬 초과 경험치 상태에서도 현재 레벨 요구량의 `10%`만 차감한다. 초과분 때문에 차감 후 게이지가 계속 `100%`일 수 있음을 허용한다.
- [x] 부활은 먼저 현재 시각까지 상태를 정산한 뒤 HP·돌봄 수치를 복구한다. HP·돌봄 수치 복구와 경험치 차감 또는 레벨 하락, `stateUpdatedAt` 갱신을 한 CoreData 저장으로 처리한다.
  - 정책이 완성된 `Pet` 하나를 돌려주므로 저장은 한 번이면 된다. **실제 CoreData 저장은 B-3.**
- [x] 사망 중에도 기존 학습·경험치 적립 흐름은 막지 않고 부활 버튼을 누른 시점의 값으로 페널티를 계산한다. 중복 부활 요청은 첫 저장 후 `hp > 0` 검사로 추가 차감을 막는다.
  - 중복 요청 차단은 `PetReviveResult.alive`로 완료. **학습 흐름을 막지 않는 것은 B-4 경험치 연결에서 확인한다.**

> **무돌봄 기준**: A-2 기본 감소율에서는 80시간까지 HP `40`을 유지하고(가장 빠른 수분이 80h에 `20` 도달) 그 뒤부터 감소한다. 단순히 앱에 접속하는 것만으로 돌봄 수치나 경과 시간이 초기화되지는 않는다.

> **검증 기준**: 순수 정책 테스트에서 시간 감소·돌보기 순서·0/100 제한·기분 우선순위·경험치 경계·HP 구간 정산·사망·부활 페널티를 재현할 수 있어야 한다.

---

## B. CoreData와 저장소

### B-1. CoreData 엔티티

- [x] 기존 `Model.xcdatamodel`에 `PetEntity`를 직접 추가한다. 보존할 사용자 데이터가 없으므로 모델 버전을 새로 만들지 않는다 — 기존 스토어와 해시가 어긋나면 앱을 삭제 후 재설치한다.
  - `NSPersistentStoreDescription`의 자동 경량 마이그레이션이 기본 `true`라 엔티티 추가는 대개 그냥 열린다. 실패하면 `CoreDataStack`이 `fatalError`로 죽으므로 앱 삭제 후 재실행.
- [x] `PetEntity` 필드: `id(UUID) / type(String) / name(String) / level(Int64) / totalExperience(Int64) / satiety(Double) / hydration(Double) / fun(Double) / cleanliness(Double) / hp(Double, 기본값 40) / stateUpdatedAt(Date) / createAt(Date)`.
- [x] `maxHP`·`isDead`·하트 표시 상태는 저장하지 않는다. `health`도 이번에는 만들지 않고 HealthKit 도입 시 속성으로 추가한다.
- [x] `PetEntity+CoreDataClass.swift`, `PetEntity+CoreDataProperties.swift`, `PetMapper.swift`를 기존 수동 관리 패턴에 맞춰 추가한다.
  - `PetMapper`에는 기존 매퍼에 없는 `apply(_ pet: Pet)`(도메인 → 엔티티)도 넣었다. `createPet`·`updatePet` 두 곳이 12개 필드 대입을 공유한다.

### B-2. `PetRepository`

- [x] `Shared/Domain/Interfaces/Repositories/PetRepository.swift`와 `DefaultPetRepository`를 추가한다.
- [x] Repository는 CRUD만 맡는다: 펫 생성, 조회, 전체 저장, 경험치 가산. **정산·조건 판단·페널티 계산은 넣지 않는다** — 정책 판단은 B-3의 UseCase 책임이다.
  - `createPet`은 완성된 `Pet`을 받는다. 초기 수치 `100`·HP `40`은 `PetStatePolicy` 상수라서 `CreatePetUseCase`가 조립해 넘긴다 — Repository는 밸런스값을 모른다.
  - **C-2에서 `createPet`을 `-> Pet?`로 바꿨다.** 생성 실패만 화면에 안내해야 해서 `saveContext()`가 성공 여부를 돌려준다. `updatePet`·`addExperience`는 결과를 쓰지 않는다(`@discardableResult`).
  - `addExperience`를 따로 둔 이유: `readPet` → 수정 → `updatePet` 왕복으로도 되지만, "적립은 `stateUpdatedAt`·HP를 건드리지 않는다"를 주석이 아니라 구조로 못박는다.
- [x] 펫 생성 전에 기존 엔티티가 있는지 확인해 앱당 1마리 불변식을 지킨다.
  - 조회는 `createAt` 오름차순 + `fetchLimit 1` — 중복이 생겨도 항상 같은(가장 오래된) 한 마리를 본다.
- [x] 저장은 CoreData 동기 저장 한 번으로 처리한다. 돌봄 수치와 HP 저장을 별도 경로로 나누지 않는다.
- [x] 현재 단일 화면에는 변경 신호 소비자가 없으므로 `characterChanged` Relay는 추가하지 않는다.

### B-3. UseCase

- [x] `Shared/Domain/UseCases/`에 `protocol X` + `final class DefaultX: X` 쌍으로 추가하고 `AppDIContainer`에 `make*()`를 넣는다 (기존 10개와 동일 형태).
  - `FetchPetStateUseCase` — 조회 → `PetStatePolicy` 정산 → 저장 → `PetDisplayInfo` 반환
  - `CarePetUseCase` — `PetCareStat` 하나를 받아 정산 후 `+25`. 이미 `100`이면 정산분만 저장하고 안내 결과 반환
  - `LevelUpPetUseCase` — 정산 후 `PetLevelPolicy` 조건 재검사, 통과 시에만 `level += 1`
  - `RevivePetUseCase` — 정산 후 사망 확인, HP·돌봄 수치 복구와 페널티를 한 저장으로 처리
  - `CreatePetUseCase` — 온보딩에서 이름·타입으로 생성, 중복 생성 차단
- [x] 사망 · `100` 도달 · 조건 미충족 같은 액션 결과는 UseCase가 결과 타입으로 돌려주고 ViewModel은 표시만 한다.
  - 세 액션의 payload가 전부 `PetDisplayInfo`로 같아서 거의 동일한 enum 3개 대신 `PetActionResult`(`info` + `rejection?`) 하나로 만들었다. `rejection == nil`이 성공이고, 화면은 rejection과 무관하게 항상 `info`를 다시 렌더링한다.
  - `PetDisplayInfo`는 `VocabDisplayInfo`처럼 도메인 엔티티(`pet`)를 품고 파생값(`mood`·게이지·`canLevelUp`)만 더한다. 하트 표시 상태는 → **D-2**.
  - 액션 3종은 옵셔널을 반환한다 — `info`가 non-optional이라 "펫 없음"을 `rejection`으로 표현할 수 없다. 정상 경로에는 없는 상태라 VM이 `guard let`으로 흘려보낸다.
- [x] ~~동기 로직은 `.just()`로 감싸 Rx 스트림으로 반환한다.~~ → `StartQuizUseCase`처럼 **평범한 값을 반환**한다. 전부 동기 CoreData 작업이라 Rx 랩핑이 VM에서 `flatMapLatest` 잡음만 만들고, 테스트 타깃에 RxSwift를 링크해야 한다.

### B-4. 기존 경험치 연결

- [x] `EarnExperienceUseCase`가 `ExperienceRepository` 대신 `PetRepository`를 받아 `PetEntity.totalExperience`를 올리게 한다. 프로토콜 하나에 구현이 하나뿐이므로 `ExperienceRepository`와 `DefaultExperienceRepository`(UserDefaults)는 제거한다.
  - `record()`는 손대지 않았다 — 학습 이력만 쓰고 펫을 건드리지 않아 사망 중에도 학습·적립이 막히지 않는다(A-5 요구사항).
- [x] 경험치 적립은 HP를 정산하거나 `stateUpdatedAt`을 갱신하지 않아 미정산 경과시간을 유실하지 않게 한다.
- [x] 적립 시 펫이 없으면 ~~`assertionFailure`~~ **`AppLogger` 기록** 후 `0`을 반환한다. 온보딩이 펫 생성을 강제하므로 정상 경로에서는 발생하지 않지만, 반환값이 정의되지 않으면 경험치가 조용히 증발한다.
  - `assertionFailure`는 펫 생성(C-2)이 붙기 전까지 퀴즈 완료마다 Debug 빌드를 트랩시키고, E-1의 "`0`을 반환하는 것도 확인한다" 테스트를 불가능하게 만든다.
- [x] `AppDIContainer`에 `DefaultPetRepository` 단일 인스턴스를 두고 온보딩·캐릭터·퀴즈 UseCase에 주입한다.
- [x] 기존 `experienceTotalPoint` 키는 이관하지 않는다. 보존할 사용자가 없고 재설치하면 UserDefaults도 함께 사라진다.
- [x] 펫 이름은 `UserInfoManager.username`을 재사용하지 않고 `PetEntity.name`에 저장한다.
- [x] 퀴즈 완료 화면(`CompleteQuizViewModel.totalPointText`)의 누적 포인트 단위를 `P`가 아닌 `EXP`로 표시한다.

> **검증 기준**: 퀴즈 완료 시 `PetEntity.totalExperience`가 증가하고 캐릭터 화면 게이지·레벨업 버튼에 그대로 반영되어야 한다.
> 단위 테스트로는 확인 완료. **수동 검증은 펫 생성(C-2)·화면(D-1) 이후** — 지금은 펫이 없어 `AppLogger`에 기록만 남는다.

---

## C. 온보딩 — 테마 선택 이후

### C-1. 알 선택 화면

- [x] `EggSelectionViewController`와 Input/Output 방식 ViewModel, 3×3 전용 셀을 추가한다.
  - 관심사 화면(`OnboardingInterestViewController` + `OnboardingInterestItem`)과 같은 4파일 구성.
  - **온보딩 전용이 아니라 `Feature/EggSelection/`으로 분리했다.** 앞으로 온보딩 밖에서도 알을 고르게 되고, 이 화면은 `PetType`과 Base 타입에만 의존해 Onboarding의 다른 두 화면과 결합이 0이다. 흐름은 여전히 `OnboardingCoordinator`가 소유하므로 전용 Coordinator는 만들지 않았다(Coordinator를 갖는 Feature는 모달 다화면 플로우의 루트뿐).
  - 칸은 **정사각형**이다. 한 변을 `floor((컨테이너 너비 - 간격×2) / 3)`으로 직접 계산해 아이템의 폭·높이에 `.absolute`로 못박고, 그룹은 `subitems: [item, item, item]`로 세운다. 컨테이너 너비가 필요해 클로저 기반 `UICollectionViewCompositionalLayout`을 쓴다.
    - `repeatingSubitem:count: 3`은 **그룹을 3등분해주지 않는다.** 아이템에 선언된 크기 그대로 3번 반복하므로, 아이템을 `fractionalWidth(1)`로 두면 그룹 폭이 컨테이너의 3배가 돼 2·3번째 칸이 화면 밖으로 밀린다(`fractionalWidth(1/3)`도 간격을 빼지 못해 그만큼 넘친다). 처음에 이걸 "3등분해준다"로 잘못 읽어 한 줄에 한 칸만 보였다.
    - `floor`는 부동소수점 오차로 `한 변×3 + 간격×2`가 컨테이너를 아주 조금 넘겨 세 번째 칸이 잘리는 것을 막는다. 버려지는 최대 2pt는 오른쪽 여백으로 흡수된다.
    - 좌우 여백은 `collectionView` 제약(`space20`, 제목·버튼과 동일) **한 곳에서만** 준다. 섹션 인셋까지 주면 이중으로 밀린다.
  - 그리드는 영역보다 짧아 위에 붙고 아래가 남는다. 컴포지셔널 레이아웃이 위에서부터 채우므로 별도 정렬 코드는 없다.
  - ViewModel에 의존성이 없지만 `makeEggSelectionViewModel()`은 컨벤션대로 `// MARK: - EggSelection` 섹션에 추가했다.
- [x] 알 슬롯은 항상 9개를 표시한다. 첫 번째만 선택 가능하고 나머지 8개는 딤 처리와 `개발중` 문구를 표시하며 탭을 무시한다.
  - 무시는 셀·`shouldSelectItemAt`이 아니라 ViewModel의 `compactMap { $0.petType }`에서 처리한다.
  - `isSelected`에 `type != nil` 가드가 필요하다 — `type == selected`만 쓰면 초기 상태(둘 다 `nil`)에서 개발중 8칸이 전부 선택돼 보인다.
- [x] 첫 번째 알을 선택해야 다음 버튼이 활성화되고 단일 선택 상태가 화면에 드러나게 한다.
- [x] 개발 중 슬롯에는 미래 `PetType`을 만들지 않고 화면용 `comingSoon` 상태만 사용한다.
  - `EggItem.petType == nil`이 개발중이다. 슬롯 인덱스가 `PetType.allCases.count` 미만이면 선택 가능하므로 알이 늘어나도 화면 코드는 그대로다.
- [x] 첫 번째 알·펫 에셋이 준비되지 않았으면 임시 표현을 쓰되 교체 지점을 `PetType`의 에셋 이름 한곳으로 제한한다.
  - ~~셀에서 `UIImage(named:) ?? UIImage(systemName: "oval.portrait.fill")`~~ → **셀은 이미지를 그리지 않는다.** 알 에셋 없이 SF Symbol을 채우면 칸마다 실루엣이 달라 격자가 지저분해진다. 지금은 `cornerRadius16` 테두리로 칸이 차지하는 공간만 드러내고 가운데에 이름(`새싹이`) 또는 `개발중` 한 줄만 둔다. 배경은 `clear`, 테두리 두께는 선택 여부와 무관하게 고정이고 선택은 테두리 **색**으로만 표시한다(두께를 바꾸면 칸 크기가 흔들린다).
  - `PetType.eggImageName`은 남아 있지만 **현재 참조하는 곳이 없다.** 에셋이 붙는 시점에 셀에 다시 연결한다.
- [x] 접근성: 셀을 `isAccessibilityElement`로 두고 개발중 슬롯에 `.notEnabled`, 선택된 슬롯에 `.selected` traits와 한국어 `accessibilityLabel`을 준다. 알파·색만으로 상태를 전달하지 않는다.
- [x] `OnboardingCoordinator.didSelectTheme()`이 알 선택 화면을 push한다. 화면을 열어볼 수 없으면 검증이 C-3까지 밀리므로 이번에 함께 연결했다 — 알 선택 완료는 **임시로** `onboardingDidComplete()`를 호출한다(C-2가 그 사이에 이름 화면을 끼운다).

> 단위 테스트는 넣지 않았다. 슬롯 생성이 "앞의 `PetType` 개수만 선택 가능" 한 줄이고 ViewModel 테스트는 테스트 타깃에 RxSwift 링크가 필요하다. E-1에도 C-1 항목이 없다 — 검증은 E-2 육안.

### C-2. 이름 지정 화면

- [x] `OnboardingPetNameViewController`와 Input/Output 방식 ViewModel을 추가하고 `CreatePetUseCase`를 주입한다.
  - `PetType`은 알 선택 화면에서 `makeOnboardingPetNameViewModel(petType:)`으로 넘어온다. ViewModel이 보관하므로 Input에는 없다.
- [x] 앞뒤 공백과 줄바꿈을 제거한 이름만 저장하고, 빈 문자열 및 기본 상한 10자를 차단한다.
  - 검증은 `PetNamePolicy.validate`(순수 타입)에 두고 ViewModel은 호출만 한다. ViewModel 안에 두면 테스트 타깃에 RxSwift 링크가 없어 E-1의 이름 테스트가 불가능하다.
  - 결과는 `PetNameValidation`(`empty` / `tooLong(Int)` / `valid(String)`) 세 상태다. **"아직 안 썼다"와 "너무 길다"를 구분해야** 입력 전부터 빨간 문구가 뜨지 않는다.
  - 길이는 `Character` 기준이라 한글 조합 문자·이모지가 1자다.
- [x] 유효한 이름일 때만 완료 버튼을 활성화하고 중복 탭으로 펫이 두 번 생성되지 않게 한다.
  - 상한 초과 시 입력을 막지 않고 **텍스트필드 아래 빨간 문구**와 버튼 비활성으로만 알린다. 텍스트필드에 잘린 값을 되돌려 쓰면 한글 조합 중 커서가 튄다.
  - 안내 문구("1~10자로 지어주세요")와 글자수 카운터는 두지 않는다 — 규칙을 미리 늘어놓는 대신 실제로 넘겼을 때만 알린다.
  - 빨간색은 `AppColor.error`(Semantic). Legacy `appRed`를 승격해 퀴즈 오답 색과 톤을 맞췄다 — `coral`은 light에서 연한 피치라 글자 대비가 부족하고 이미 감정 토픽 색이다.
  - 중복 탭 플래그는 두지 않았다. 동기 호출이라 같은 런루프에서 화면이 넘어가고, 두 번 들어와도 `createPet`이 기존 펫을 돌려준다.
- [x] 저장 성공 후에만 온보딩 완료 이벤트를 전달하고, 실패하면 현재 화면에서 안내한다.
  - 이를 위해 `PetRepository.createPet`과 `CreatePetUseCase.execute`를 **옵셔널 반환으로 바꿨다**(B-2 항목의 시그니처 변경). `saveContext()`가 성공 여부를 돌려주고, 실패하면 미저장 엔티티를 `context.delete`로 걷어낸다 — 남기면 다음 조회가 "이미 있음"으로 오판해 재시도가 막힌다.
  - 실패 시 `AlertPresenter.showNotificationAlert`로 "잠시 후 다시 시도해주세요"를 띄우고 화면에 머문다.

### C-3. Coordinator와 재진입

- [x] `OnboardingCoordinator` 흐름을 `관심사 → 테마 → 알 선택 → 이름 지정 → 완료`로 연결한다.
- [x] `AppFlowCoordinator`의 완료 조건을 `currentThemeUrl != nil && pet != nil`로 변경한다.
  - 펫 조회는 `IsPetCreatedUseCase`를 새로 만들어 경유한다. `FetchPetStateUseCase`는 조회할 때마다 정산하고 저장하므로 존재 확인에 쓸 수 없다.
- [x] `currentThemeUrl`은 있지만 펫이 없는 상태(테마 선택 직후 강제 종료, 개발 중인 기기)에서는 관심사·테마를 반복하지 않고 알 선택부터 시작하게 한다.
  - 이때 알 선택이 첫 화면이라 push할 대상이 없다 — `showEggSelection(asRoot:)`가 `setViewControllers`로 세운다.
- [x] `currentThemeUrl`이 없으면 기존 관심사 화면부터 시작한다. 테마 선택 뒤 이미 펫이 있으면 중복 생성 없이 바로 완료하고, 없으면 알 선택으로 이동한다.
- [x] 알 선택 상태는 한 종류뿐이므로 별도 온보딩 진행 상태를 저장하지 않는다.
- [ ] 알 선택 → 이름 지정은 push이므로 스와이프 back으로 돌아올 수 있다. 되돌아온 뒤 재선택해도 펫이 중복 생성되지 않는지 확인한다.
  - 코드상 되돌아가는 시점에는 아직 펫이 없어 재선택이 안전하다. 육안 확인은 → **E-2**. `nav.isNavigationBarHidden = true`라 back 버튼 없이 스와이프만 된다(기존 온보딩과 동일).

> **검증 기준**: 신규 설치 전체 흐름, 테마 선택 직후 강제 종료, 이름 입력 중 강제 종료, 기존 `currentThemeUrl 있음 / pet 없음` 상태에서 모두 올바른 화면으로 복귀해야 한다.

---

## D. 캐릭터 화면

### D-1. ViewModel과 화면 진입

- [ ] `CharacterViewModel`을 Input/Output 방식으로 추가하고 B-3의 UseCase들을 주입한다. `PetRepository`를 직접 참조하지 않는다.
- [ ] Input은 화면 표시·앱 활성화·돌보기 종류·레벨업 탭·부활 탭으로 제한한다. Output은 이름·이미지·레벨·경험치 진행률·네 돌봄 수치·기분·HP·하트 표시 상태·사망 여부·버튼 상태·안내 메시지를 제공한다.
- [ ] `viewWillAppear`와 `UIApplication.didBecomeActiveNotification`에서 상태를 다시 조회한다. 화면을 계속 켜 둔 동안의 분 단위 타이머는 넣지 않는다.
- [ ] `MainCoordinator`가 `AppDIContainer.makeCharacterViewModel()`로 ViewModel을 생성해 기존 full-screen 화면에 주입한다. 지금은 진입마다 `CharacterViewController`가 새로 생성되므로 Relay 없이도 퀴즈 경험치가 재조회로 반영된다 — 나중에 진짜 `UITabBarController`로 바꾸면 뷰컨이 살아남아 이 전제가 깨진다.
- [ ] 캐릭터 화면이 하나뿐이므로 별도 `CharacterCoordinator`는 만들지 않는다.

### D-2. 상태 UI

- [ ] 캐릭터 이미지, 펫 이름, 현재 기분, 레벨을 표시한다.
- [ ] `UIProgressView`로 현재 레벨 경험치 게이지와 `현재 EXP / 필요 EXP`를 표시한다. 게이지는 `0...1`로 제한하지만 텍스트는 초과분을 그대로 보여준다 (`250 / 100`).
- [ ] 포만감·수분·즐거움·청결 수치와 게이지를 표시한다.
- [ ] 돌봄 수치가 `20 이하`면 위험 표시와 함께 HP가 감소 중임을 텍스트로 알린다. 기분만으로는 사망이 임박한 것을 알 수 없고 푸시 알림도 이번 범위 밖이다.
- [ ] HP를 최대 10개의 하트로 표시한다. 표시용 칸 `4 / 3 / 2 / 1`을 각각 `가득 참 / 2/3 / 1/2 / 1/3` 이미지로 표현하고, 남은 칸이 `0`이면 부분 하트를 제거한다.
  - A-5의 칸 수 계산과 E-1의 하트 테스트도 여기서 함께 만든다 (`hp`만으로 끝나는 계산이지만 UI와 같이 보는 편이 낫다).
- [ ] `0 < hp < 1`이면 `1/3` 하트 하나를 표시하고 `hp == 0`이면 하트를 모두 소멸시킨다. 빈 하트는 HP 단계가 아니라 빈 배경 슬롯 또는 소멸 전환 표현으로만 사용한다.
- [ ] Quiz Feature 전용 `CustomProgressView`는 직접 참조하지 않는다.
- [ ] 게이지와 비활성·개발 중 상태가 색상만으로 전달되지 않도록 텍스트와 VoiceOver 값을 함께 제공한다.
- [ ] 사망 시 캐릭터 사망 상태와 부활 버튼을 표시하고 VoiceOver에 현재 HP와 사망 여부를 전달한다.

### D-3. 액션

- [ ] 밥주기 → 포만감, 물주기 → 수분, 놀아주기 → 즐거움, 청소하기 → 청결을 회복한다.
- [ ] 돌보기 결과를 즉시 다시 렌더링하고 이미 100이면 토스트로 안내한다.
  - 감소가 계속 일어나므로 `PetActionRejection.alreadyFull`은 경과 시간이 `0` 이하일 때만 뜬다. `99.99`에서 눌러도 성공 처리라 토스트가 사실상 안 나온다 — 안내가 필요하면 "`100`에 근접" 기준을 여기서 정한다.
- [ ] 경험치 게이지가 100% 미만이면 레벨업 버튼을 비활성화한다.
- [ ] 레벨업 성공 후 레벨·게이지·버튼 상태를 다시 렌더링하고 초과 경험치를 보존한다.
- [ ] 사망 상태에서는 돌보기·레벨업 버튼을 비활성화하고 부활 버튼만 활성화한다. 학습 화면 진입과 퀴즈 경험치 적립은 막지 않는다.
- [ ] 부활 성공 후 HP 40, 하트 10개, 돌봄 수치 `50`, 경험치 차감 또는 레벨 하락 결과를 즉시 다시 렌더링한다.

> **검증 기준**: 앱을 닫아 둔 시간만큼 상태와 HP가 한 번만 정산되고, 경험치가 부족할 때는 저장소를 직접 호출해도 레벨이 오르지 않으며, 살아 있는 펫은 부활할 수 없어야 한다.

---

## E. 테스트와 완료 검증

### E-1. 최소 테스트 기반

> **현재 69개 통과** — `PetStatePolicyTests`(34) · `PetPersistenceTests`(21) · `PetLevelPolicyTests`(7) · `PetNamePolicyTests`(7).
> 실행: `xcodebuild -scheme Danogotchi-dev -destination 'platform=iOS Simulator,name=iPhone 17' test`
> 공용 픽스처는 `DanogotchiTests/PetTestSupport.swift`(`makePet` / `hoursLater` / `hoursAgo` / `petAfterCare` / `makeInMemoryContext`).
> 정책 테스트는 고정 시각(`testBase`), 저장소·UseCase 테스트는 UseCase가 내부에서 `Date()`를 쓰므로 `hoursAgo`로 경과를 심는다.

- [x] 현재 없는 `DanogotchiTests` 단위 테스트 타깃을 추가한다.
- [x] `PetStatePolicy`: 0시간·1시간·장시간 경과, 감소 후 돌보기, 돌봄 수치 0/100과 HP 0/40 제한을 테스트한다.
- [x] 기기 시각을 미래로 옮겼다 되돌린 경우 경과 시간이 `0`이면서 `stateUpdatedAt`이 현재 시각으로 재동기화되어 상태가 얼어붙지 않는지 테스트한다.
- [x] `PetMood`: `45 / 65 / 80 / 95` 경계, 복수 저하 우선순위, 자연 방치 중 상쾌함 미발생, 행복·상쾌·만족을 테스트한다.
- [x] 무돌봄 기분 전이를 `20 / 35 / 43.75 / 68.75h`의 직전·경계·직후에서 테스트한다.
- [x] `PetLevelPolicy`: 레벨 0의 99/100 EXP, 레벨 1의 200 EXP, 초과 경험치 이월, 연속 승급 가능 상태를 테스트한다.
- [x] HP 정산은 전 구간 `>65` 회복, `20 초과 65 이하` 정지, 위험 수치 1·2·여러 개의 시간당 감소, 한 경과 구간 안의 임계값 통과, 회복 후 피해 적용 순서를 테스트한다.
- [x] 무돌봄 `24 / 48 / 72 / 80 / 84 / 100 / 133⅓ / 157 7/9h`의 HP와 사망 경계를 검증하고, 한 번 정산한 결과와 같은 구간을 나눠 정산한 결과가 일치하는지 확인한다.
  - 사망 경계는 `157 7/9h` **직후**(`157.78h`)에서 확인한다. 정확값에서는 `Double` 누적 오차로 HP가 `1e-15` 남을 수 있어 `accuracy`로 `0` 근사만 본다. 정책에 epsilon은 넣지 않았다 — 다음 정산에서 곧바로 죽는다.
- [x] 24시간마다 접속만 한 4회 정산이 96시간 연속 방치와 같은 HP `36`인지, 반대로 매일 네 돌보기를 각각 한 번 수행하면 7일 뒤에도 HP `40`인지 테스트한다.
- [ ] HP 표시 파생값을 `40 / 39 / 38 / 37 / 36 / 0.5 / 0`에서 검증해 하트 10개, `2/3 · 1/2 · 1/3`, 최소 1칸, 전멸 상태를 확인한다. → **D-2**
- [x] 부활 시 `50% → 40%`, `5% → 0%`, 레벨 진행률 0%에서 한 단계 하락, 레벨 0 하한, 초과 경험치 차감, 살아 있는 펫의 부활·중복 요청 거부를 테스트한다.
- [x] 부활 직후 네 돌봄 수치가 `50` 이상이고 곧바로 HP가 감소하지 않는지 테스트한다.
- [x] 경험치 적립이 `stateUpdatedAt`을 갱신하지 않아 적립 전후로 미정산 경과시간이 보존되는지 테스트한다. 펫이 없을 때 `0`을 반환하는 것도 확인한다.
- [x] 인메모리 CoreData로 펫 1마리 생성, 중복 생성 차단, 돌보기·HP 정산 저장, 경험치 적립, 조건부 레벨업·부활의 원자적 저장을 테스트한다.
  - `alreadyFull`은 경과 시간이 `0` 이하일 때만 성립한다(감소가 계속 일어나므로) — 테스트도 `stateUpdatedAt`을 미래로 심는 기기 시각 되돌림 상황으로 잡았다. 실사용 UX는 **D-3에서 판단**한다.
- [x] 이름의 앞뒤 공백 제거·빈 값·10자 경계를 테스트한다.
  - `PetNamePolicyTests`(7). `empty` / `tooLong` / `valid` 세 상태와 중간 공백 보존, 이모지·조합 문자 1자 계산을 함께 본다.

### E-2. 통합·수동 검증

- [ ] fresh install에서 관심사 → 테마 → 알 → 이름 → 메인 흐름을 확인한다.
- [ ] 알 9개, 첫 번째 단일 선택, 개발 중 8개 비활성·접근성 문구를 확인한다. 칸이 정사각형이고 3×3 격자가 상단에 붙는지 좁은 기기·넓은 기기 양쪽에서 본다.
- [ ] 이름 화면에서 10자까지는 안내가 없다가 11자부터 빨간 문구가 뜨고 완료 버튼이 잠기는지, 다시 줄이면 풀리는지, 공백만 입력하면 문구 없이 버튼만 잠기는지 확인한다.
- [ ] 앱 백그라운드·강제 종료 후 돌봄 수치와 HP가 같은 경과시간으로 한 번만 정산되고 온보딩 재진입에 영향이 없는지 확인한다.
- [ ] 퀴즈 완료 경험치가 캐릭터 게이지와 레벨업 버튼에 반영되는지 확인한다.
- [ ] 24시간·48시간·72시간·80시간 방치 후 HP가 40으로 유지되고, 80시간 초과부터 하트가 단계적으로 감소해 157시간 46분 40초(`157 7/9h`)에 사망하는지 확인한다.
- [ ] 사망 중에도 퀴즈 학습과 경험치 적립이 가능하고 부활 시점의 경험치에 페널티가 적용되는지 확인한다.
- [x] `xcodebuild -scheme Danogotchi-dev build`와 `xcodebuild -scheme Danogotchi build`를 모두 통과시킨다.

---

## 착수 전 확인 — 미확정 시 기본안 사용

1. 첫 번째 알과 펫의 실제 이미지·타입명: 미제공 시 SF Symbol 임시 이미지와 단일 `PetType`을 사용한다.
2. 이름 최대 길이: 별도 정책이 없으면 앞뒤 공백 제거 후 1~10자로 제한한다.
3. 레벨 곡선: 별도 표가 없으면 레벨마다 요구량이 100씩 증가하는 A-4 공식을 사용한다.
4. 부활 시 돌봄 수치 처리: 별도 정책이 없으면 `50` 미만인 수치를 `50`으로 올린다 (재사망 나선 방지).
5. 부화·진화 표현: 별도 요구가 없으면 선택한 알의 1단계 이미지 표시까지만 구현하고 부화 애니메이션과 진화 단계는 이연한다.

## 이번 범위에서 이연

- HealthKit·만보기 연동과 복합 건강 점수 계산 (`health` 컬럼 자체를 이번에 만들지 않음)
- 날씨 조회와 날씨 기반 기분 보정
- 로그인·로그아웃·마지막 체류 시각 및 돌보기 이력 저장
- 백그라운드 작업, 푸시 알림, 화면 상시 갱신 타이머
- 돌보기 재화·경험치·횟수 제한·쿨다운
- 추가 알 8종의 도메인 타입과 에셋
- 부화·진화 단계와 레벨업 애니메이션
- 레벨별 최대 HP·하트 개수 증가 (`maxHP` 컬럼 없이 `level`에서 파생)
- 다른 화면의 펫 상태 실시간 표시 및 Repository 변경 Relay
