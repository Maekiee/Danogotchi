# TODO — 학습하기 재설계 (활성 단어장 기반 출제)

**스프린트 목표**: 단어장 상세에서 "학습하기" → 활성 단어장 지정 → 출제  
**진행**: A-1/A-2/A-3/B-1/B-2 완료 · 남은 C~D 13h

---

## ✅ 완료분 (A-1 ~ B-2)
- [x] A-1. 이어하기 제거 (2h)
- [x] A-2. UUID 단일화 (3h)
- [x] A-3. CoreData `isActive` 필드 이전 · 커밋 `e9b71db` (4h)
- [x] B-1. 단어장 상세의 학습하기 → 활성 단어장 지정 · 커밋 `365418e` (1.5h)
- [x] B-2. "학습중" 표시 (단어장 목록 카드 체크 아이콘) · 커밋 `ce07b37` (2h)
  - `FetchVocabBooksUseCase` 신설 + `VocabBookCardInfo` 엔티티, Library를 DB 조회 기반으로 전환
  - 활성 단어장 카드 제목 옆 `checkmark.circle.fill`, 다른 단어장 지정 시 하나만 이동 — 동작 확인 완료

> ⚠️ A-3 in-place 수정으로 기존 스토어 마이그레이션 불가 → **앱 삭제 후 재설치 필수** (팀원 기기도 동일)

---

## C-1. `StartQuizUseCase` 신설 — 출제 세트 선정 — **4h**
- [ ] 활성 단어장 기반으로 출제 세트 결정 (20개 이하: 전체 셔플 / 초과: 가중 랜덤 20개)
- [ ] 단어 4개 미만 시 실패 반환 (보기 4개 필수)

## C-2. 출제 진입점 VC → ViewModel/UseCase 이동 — **2h**
- [ ] 로직을 `ExploreVocabViewModel`으로 이관, ViewController는 delegate 호출만

## C-3. 학습 이력 집계 중복 제거 — **1.5h**
- [ ] 두 곳(`ExploreVocabViewModel:41~` / `DefaultFetchVocabsUseCase:47~`)의 중복 구현을 한 곳으로

## C-4. 학습 완료 화면 재출제 정책 — **2h**
- [ ] 전체 재시작 제거 → `StartQuizUseCase` 재호출 (20개 상한 유지)

---

## D-1. 중단 시 이력 보존 검증 + 알럿 문구 — **1h**
- [ ] 수동 검증 (5문제 풀고 X 종료 → 기록 반영 확인)
- [ ] `QuizCoordinator:95` 알럿 문구 수정 (이어하기 제거 반영)

## D-2. Domain 유닛테스트 + 선정 로직 검증 — **2.5h**
- [ ] 테스트 타깃 신설 · `StartQuizUseCase` 케이스 (4개 미만 실패 / 정확히 20개 / 21개 → 20개 / 가중치 방향성)

---

## 시간 산정 (누적)

| 구간 | 시간 |
|---|---|
| 완료 (A-1/A-2/A-3/B-1/B-2) | 12.5h |
| **C-1 + C-2 + C-3 + C-4** | 9.5h |
| **D-1 + D-2** | 3.5h |
| **남은 작업** | **13h** |

---

## 참고: 확정 필요 항목 (개발 전)

- **C-1 가중 랜덤 정책**: `w = (1 - accuracy) + 1/(total + 1)` 확률 추출 vs 다른 방식 검토
- **C-4 재출제**: 새로 20개 재선정 vs 같은 20개 셔플 정책 확인

## 이연 (다음 스프린트)

신규 기능: 북마크("나의 단어에 저장") — `originWordId` 토글 + UI 표시/숨김

온보딩에서 추천 단어장 선택 → 활성 단어장 지정 (현재 `OnboardingCoordinator` 는 테마 선택만 한다)
- 이 작업이 "활성 단어장 미선택 상태" 처리를 대체한다 — 정상 플로우에서 nil이 발생하지 않으므로 B-3을 폐기했다

---

## 📝 아카이브: Realm → CoreData 전환 (Phase 1~7) ✅

**완료**: Phase 1~7 모두 마무리 (Realm 제거 완료)
- ✅ 데이터 모델/스택 신규 구현
- ✅ 깨끗한 도메인 모델 정의 (`Vocab`/`VocabBook`/`LearningHistory`)
- ✅ Repository 프로토콜 + CoreData 구현
- ✅ 소비처 전환 (ViewModel/ViewController)
- ✅ Realm 잔재 제거 (코드 0건, SPM GUI로 제거)
- ✅ 문서 갱신

**검증**: `import RealmSwift` / `ObjectId` / `Realm` 모두 0건, BUILD SUCCEEDED

**알려진 이슈**: 기존 데이터 + 온보딩 스킵 → 나의 단어장 미생성 (clean start 정책에 따른 동작, 신규 설치는 정상)

