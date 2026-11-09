# 학습 통계 리뉴얼 기획안 (캘린더 + 학습 통계)

- 버전: v3.1 (2026-11-05)
- 디자인 시안: `docs/study-calendar-wireframe.html`. 색·글꼴·크기·굵기·간격·모서리는 시안의 토큰표와 컴포넌트 스펙(C1–C16)을 기준으로 한다.
- v3(2026-11-04) 대비 변경 (이름)
  - `StudyReport*` → `StudyStats*`. 화면과 모달 이름은 "학습 통계"다. 저장소·마이그레이션 타입 이름까지 바꾸고, 저장된 키·Core Data 모델은 그대로 둔다.
  - `StudyCalendar*` → `Calendar*`. 도메인 모델 `StudyCalendar`만 Foundation `Calendar`와 겹치지 않게 유지한다.
  - `StudyStatsComponents`의 컴포넌트는 학습 통계에서만 쓴다. 캘린더는 같은 수치로 자기 컴포넌트를 만든다(§8.3).
  - `StudyStats.Word` → 최상위 `VocabStats`. 캘린더와 같이 쓰는 원본 단어 기준 풀이 통계다. 카드(`vocabId`)별 수치인 `LearningStats`와는 별개다.
- v2(2026-11-03) 대비 변경
  - 캘린더 기획을 학습 통계 리뉴얼과 하나로 묶었다.
  - 통계 진입 화면을 **캘린더**로 바꾸고, 기존 통계 화면은 **학습 통계**로 다시 구성해 캘린더 우측 상단 "학습 통계 ›" 버튼으로 연다.
  - 캘린더 기능(§4)은 v2 그대로 확정한다. 바뀐 것은 내비게이션 바(§4.1), 진입 흐름(§3), 초록 색(§4.3·§4.4·§4.6)이다.
  - 잔디·달력 농도, 칩, 오늘 테두리를 파랑(`primary`)에서 새 초록 토큰 `grass`로 바꾼다(§6).
  - 다크 모드 카드가 배경과 구분되도록 `StudyStatsCard`를 `AppColor.card`로 바꾼다(§6, §8.3).

## 1. 배경과 목표

캘린더를 따로 기획하고 보니 기존 학습 통계와 겹치는 부분이 많다.

| 겹치는 정보 | 학습 통계(현재) | 캘린더 |
|---|---|---|
| 연속 학습 | "N일 연속 학습" + 최근 7일 체크 행 | "N일 연속" 칩 |
| 기간별 학습량 | 최근 7일·이번 달 카드, 학습한 단어 수 막대 그래프 | 잔디(53주), 월 달력 농도 |
| 날짜·기간의 단어 | 많이 맞힌 단어, 기간별 전체 보기 | 선택 날짜의 단어 목록 |

그래서 두 화면의 역할을 나눈다.

- **캘린더 (진입 화면)**: 언제, 얼마나 공부했는지. 날짜를 골라 그날 학습한 단어를 본다.
- **학습 통계**: 지금까지 전체로 무엇을 공부했고 무엇이 약한지. 누적 수치, 주제·품사 비중, 많이 틀린 단어.
- 정답률이 낮은 단어를 기준별로 모아 복습할 단어를 바로 찾게 한다.

## 2. 범위

### 2.1 기존 학습 통계 항목 처리

| 기존 항목 | 처리 | 새 위치 |
|---|---|---|
| 누적 학습 단어 | 남김 | 학습 통계 요약 카드 (§5.2) |
| 총 정답률 | 남김 | 학습 통계 요약 카드 (§5.2) |
| 연속 학습 (최근 7일 체크 행) | UI 변경, 옮김 | 캘린더 "N일 연속" 칩 (§4.3). 학습 통계에서는 뺀다 |
| 주제별 학습 비중 | 남김, 막대 → 도넛 | 학습 통계 (§5.3) |
| 학습 단어의 품사 | 남김 (그대로) | 학습 통계 (§5.4) |
| 분석 기간 선택 (최근 7일·이번 달·전체) | 버림 | 학습 통계는 전체 기간 고정 |
| 최근 7일 학습 단어 | 버림 | |
| 이번 달 학습 단어 | 버림 | |
| 학습한 단어 수 막대 그래프 | 버림 | 날짜별 학습량은 잔디·달력이 맡는다 |
| 회차별 정답률 | 버림 | |
| 많이 틀린 종류 (주제·품사별 오답 막대) | 버림 | 많이 틀린 단어가 대신한다 |
| 많이 맞힌 단어 | 버림 | |
| **많이 틀린 단어** | 신규 | 학습 통계 (§5.5) |

### 2.2 제외

- 날짜별 노트, 학습 목표·빈도 설정, 편집·설정 버튼 (v2와 같음)
- 잔디 범례, 잔디 기간 변경, 위젯, 알림 (v2와 같음)
- 학습 통계의 기간 선택
- 많이 틀린 단어로 바로 퀴즈 풀기

## 3. 화면 구조와 흐름

```
단어 탐색 ─(차트 아이콘)→ 캘린더 ········ 모달 루트
                           ├─ 날짜의 단어 카드 → 단어 상세 ········ 시트, "이날" 수치
                           └─ 우측 상단 "학습 통계 ›" → 학습 통계 ········ push
                                  ├─ 누적 학습 단어 › → 학습한 단어 (전체) ········ push
                                  └─ 많이 틀린 단어 행 / 목록의 단어 카드 → 단어 상세 ········ 시트, 전체 수치
```

1. 단어 탐색의 차트 아이콘(`chart.line.uptrend.xyaxis`, 기존 그대로) → 캘린더가 전체 화면 모달로 열린다. 현재 달, 오늘 선택 상태.
2. 캘린더 안의 동작은 v2와 같다(잔디 탭, 날짜 탭, 월 이동, 오늘, 단어 상세).
3. 우측 상단 "학습 통계 ›" → 학습 통계 push.
4. 학습 통계에서
   - 누적 학습 단어 › → 전체 학습 단어 목록 push
   - 많이 틀린 단어 기준 세그먼트 → 목록 바뀜
   - 많이 틀린 단어 행 탭 → 단어 상세 시트
5. 뒤로가기: 학습 통계 → 캘린더, 단어 목록 → 학습 통계. ✕는 어느 화면에서든 모달 전체를 닫는다.
6. 학습 통계에서 캘린더로 돌아오면 보던 달과 선택한 날짜가 그대로 남는다.

## 4. 캘린더 (v2 확정)

### 4.1 레이아웃

위에서 아래로 한 화면 스크롤(`ScrollView`)에 둔다.

| 순서 | 영역 | 내용 |
|---|---|---|
| 1 | 내비게이션 바 | 왼쪽 ✕, 타이틀 "캘린더", 오른쪽 "학습 통계 ›". 모달 루트라 뒤로가기는 없다 |
| 2 | 잔디 카드 | §4.2 |
| 3 | 칩 | §4.3 |
| 4 | 달력 카드 | 요일 머리글, 6행 그리드, 하단 컨트롤, 안내 문구. §4.4 |
| 5 | 선택 날짜 영역 | 요약 + 단어 카드 목록. §4.5 |

- 참고 이미지의 아이콘·제목 헤더는 넣지 않는다. 내비게이션 타이틀과 겹치기 때문이다.
- ✕
  - 왼쪽(`topBarLeading`)에 둔다. 누르면 모달 전체를 닫는다. 44pt 터치 영역, 접근성 라벨 "학습 통계 닫기"(지금 그대로)다.
  - 하위 화면(학습 통계, 학습한 단어)은 왼쪽이 뒤로가기라서 ✕를 지금처럼 오른쪽에 둔다.
- "학습 통계 ›"
  - 오른쪽(`topBarTrailing`)에 텍스트 버튼으로 둔다. 글자 "학습 통계" 뒤에 `chevron.right`를 붙인다. 높이 44pt, 접근성 라벨 "학습 통계"이다.
  - 로딩·실패·기록 0건 상태에서도 누를 수 있다. 학습 통계는 따로 읽고 자기 상태를 직접 보여 준다.

### 4.2 학습 잔디 카드

- **기간**
  - 이번 주를 포함한 최근 53주를 보여 준다(깃허브와 같음).
  - 첫 기록보다 앞선 칸도 빈 칸으로 그린다. 이번 주의 미래 날짜 칸은 그리지 않는다.
- **배치**
  - 열은 주, 행은 요일이다. 가장 최근 주가 오른쪽 끝에 온다.
  - 행 순서는 `calendar.firstWeekday`를 따른다(한국 기본은 일요일 시작).
- **머리글**
  - 위쪽 월 라벨("1월"…)은 그 달 1일이 들어 있는 열 위에 표시한다.
  - 왼쪽 요일 라벨은 2·4·6번째 행에만 표시한다(일요일 시작이면 월·수·금).
- **셀**: 정사각형 12pt, 간격 3pt, 모서리 3pt. 농도는 그날 학습한 **고유 단어 수**에 따라 4단계로 칠한다(§4.6).
- **스크롤**
  - 53주는 화면 폭을 넘으므로 가로로 스크롤한다. 처음 열 때 오른쪽 끝(이번 주)이 보이게 한다.
  - 왼쪽 끝에 카드 배경색 페이드를 둬서 더 있다는 것을 알린다.
  - 요일 라벨은 스크롤하지 않고 고정한다.
- **선택**: 선택한 날짜의 셀에 안쪽 1.5pt(`AppBorder.regular`) `textPrimary` 테두리를 그린다. 선택 상태는 달력과 공유한다.
- **탭**
  - 미래가 아닌 셀을 탭하면 그 날짜를 선택하고 달력을 그 달로 옮긴다.
  - 셀이 12pt라서 터치 영역을 행·열 간격까지 넓힌다(15pt). 그래도 44pt에 못 미치므로 정확한 선택은 달력이 맡는다.
- **기록 0건**: 빈 칸으로 그대로 그린다(§4.7).

### 4.3 칩

달력 카드 위에 왼쪽 정렬로 두며, 탭할 수 없다.

| 칩 | 아이콘 | 값 | 출처 |
|---|---|---|---|
| 연속 학습 | `flame` | "N일 연속" | 기존 통계의 연속일 계산을 옮겨 쓴다(학습 통계에서는 뺀다) |
| 총 학습일 | `calendar` | "총 N일 학습" | 기록이 있는 날 수 |

- 색: 배경은 `grass` 12%, 글자와 아이콘은 `grass`다. 0일이어도 같은 모양으로 보여 준다("0일 연속").
- VoiceOver: "연속 학습 5일", "총 학습일 42일".

### 4.4 달력 카드

- **요일 머리글**: `calendar.firstWeekday`를 반영한다. 접근성 글자 크기에서도 한 글자, 7열을 유지한다.
- **그리드**
  - 항상 6행이다. 달마다 행 수가 바뀌어 아래 영역이 밀리는 문제를 막는다.
  - 앞뒤 빈칸은 이웃 달 날짜로 채운다. 숫자만 `gray45` 50%로 흐리게 그리고, 농도와 탭은 없다.
- **셀**: 높이 44pt, 모서리 `radius8`. 숫자 아래에 4pt 점 자리를 둔다(선택 시 표시).
  - 농도는 4단계다(§4.6).
  - 오늘은 1.5pt `grass` 테두리를 그린다.
  - 미래 날짜는 흐리게 그리고 탭할 수 없다.
  - 선택한 날짜는 숫자를 굵게 하고 점을 표시한다.
- **하단 컨트롤** (왼쪽부터)
  - 월 선택 메뉴: "2026년 11월 ⌄" 캡슐 버튼. 누르면 `earliestMonth`부터 현재 달까지 최신순 목록이 열린다(`Menu`).
  - 오늘: 현재 달로 이동하고 오늘을 선택한다. 이미 현재 달에서 오늘이 선택돼 있으면 비활성.
  - ‹ ›: 44pt 원형 버튼, 라벨 "이전 달"/"다음 달". 현재 달이면 ›, `earliestMonth`면 ‹가 비활성.
- **안내 문구**: 카드 맨 아래에 "날짜를 누르면 그날 학습한 단어를 볼 수 있어요"를 둔다(footnote, `textSecondary`). 기록이 0건이면 숨긴다.

### 4.5 선택 날짜 영역

- **요약**: `CalendarHeading`(C4)으로 그린다. 제목 "10월 7일 (화)", 부제 "단어 12개 · 정답률 83% · 퀴즈 2회".
- **단어 목록**
  - 카드는 단어장 상세 카드(`VocabBookDetailCollectionViewCell`)와 같은 모양으로 그린다. 오른쪽 위 북마크·더보기 아이콘은 넣지 않는다(조회 전용).
    - 높이 168, 모서리 20, 파스텔 배경, 품사 캡슐, 단어(최대 2줄), "뜻 · N번 학습", 큰 숫자 + 작은 "%". 세부 수치는 시안 C10.
  - 카드 사이 16. 정렬은 정답 횟수순(학습한 단어 목록과 같음)이다.
  - 수치는 **그날** 풀이만 집계한다. N은 그날 그 단어를 푼 횟수, 정답률은 그날 정답 ÷ 풀이다.
- **단어 카드 탭**: 단어 상세 시트를 연다(§8.4). 시트에서는 "이날 정답 c / t회"로 표기해 기간을 구분한다.
- **선택 없음**(달 이동 직후): 이 영역을 비운다. 행동 안내는 달력 카드의 안내 문구가 맡는다.

### 4.6 농도 기준

잔디와 달력이 같은 기준을 쓴다. 구간 값은 `StudyCalendar.Day.level` 한 곳에서 관리한다.

| 단계 | 고유 단어 수 | 잔디 셀 | 달력 셀 |
|---|---|---|---|
| 0 | 0 | `gray45` 15% | 배경 없음, 숫자 `textSecondary` |
| 1 | 1~20 | `grass` 25% | `grass` 25% |
| 2 | 21~40 | `grass` 50% | `grass` 50% |
| 3 | 41~60 | `grass` 75% | `grass` 75% |
| 4 | 61 이상 | `grass` 100% | `grass` 100%, 숫자 흰색 |

### 4.7 상태별 문구

| 상황 | 선택 날짜 영역 | 기타 |
|---|---|---|
| 오늘 선택, 오늘 기록 없음 | `CalendarSelection` "오늘은 아직 학습 기록이 없어요" | |
| 과거 날짜 선택, 기록 없음 | `CalendarSelection` "이날은 학습 기록이 없어요" | |
| 표시 중인 달에 기록 없음 | `CalendarSelection` "이 달에는 학습 기록이 없어요" | 선택이 없을 때만 |
| 기록 0건 | 빈 상태 카드: `book.closed` + "학습을 시작하면 잔디와 달력이 채워져요" | 잔디는 빈 칸, 칩은 0일, 달 이동·오늘 비활성, 안내 문구 숨김 |
| 첫 로드 중 | 잔디·달력 자리에 스켈레톤 | 학습 통계와 같은 모양, `CalendarStateCard` |
| 첫 로드 실패 | 실패 카드(학습 통계와 같은 아이콘·문구) + "다시 시도" | 잔디·칩·달력을 그리지 않는다. `CalendarStateCard` |
| 다시 읽기 실패 | 기존 화면을 유지하고 선택 날짜 영역 위에 실패 카드 | 학습 통계와 같은 정책 |

### 4.8 접근성

- 잔디 카드는 셀 371개를 하나씩 읽지 않도록 **하나의 요소**로 묶는다.
  - 라벨: "최근 1년 학습 기록"
  - 값: "42일 학습, 가장 많이 학습한 날 10월 15일 20개"
  - 날짜별 탐색은 달력이 맡는다.
- 달력 셀 라벨은 "10월 7일 화요일, 학습 단어 12개" 또는 "학습 안 함"이다. 선택과 오늘은 trait와 값으로 알린다.
- 잔디 셀 크기는 글자 크기와 상관없이 고정한다. 월·요일 라벨만 글자 크기를 따르되 `xxxLarge`에서 멈춘다.
- 접근성 글자 크기에서는 하단 컨트롤을 두 줄로 나눈다(월 메뉴 / 오늘·‹ ›).

## 5. 학습 통계 (리뉴얼)

지금 `StudyStatsView`를 고쳐 만든다. 모든 카드가 **전체 기간** 기준이고 기간 선택은 없다.

### 5.1 레이아웃

| 순서 | 영역 | 내용 |
|---|---|---|
| 1 | 내비게이션 바 | 시스템 뒤로가기(캘린더), 타이틀 "학습 통계", ✕ |
| 2 | 요약 카드 | 누적 학습 단어 ›, 총 정답률. §5.2 |
| 3 | 주제별 학습 비중 카드 | 도넛 + 범례. §5.3 |
| 4 | 학습 단어의 품사 카드 | 도넛 + 범례. §5.4 |
| 5 | 많이 틀린 단어 카드 | 기준 세그먼트 + 고른 기준의 단어 전부. §5.5 |

카드는 지금처럼 `StudyStatsCard`이고, 카드 간격은 `space16`, 화면 여백은 `space20`이다.

### 5.2 요약 카드

- 지금 통계의 상단 카드에서 구분선 아래 연속 학습 부분을 뺀 모양이다.
- 2열로 둔다.
  - 왼쪽: "누적 학습 단어 ›" N개. 탭하면 전체 학습 단어 목록(§5.6)으로 간다.
  - 오른쪽: "총 정답률" N%.
- 접근성 글자 크기에서는 세로로 쌓는다. 실패 상태에서는 누적 학습 단어 버튼을 비활성화한다. 둘 다 지금과 같다.
- 기록이 0건이면 이 카드를 그리지 않는다(§5.7).

### 5.3 주제별 학습 비중 (막대 → 도넛)

- **기준**: 지금과 같은 주제별 **풀이 횟수**(정답과 오답을 합친 수). 주제는 여행·비즈니스·감정·일상·미분류 5개다.
- **헤딩**: 제목 "주제별 학습 비중", 부제 "풀이 횟수 기준".
- **도넛**: 품사 차트와 같은 모양이다.
  - 126pt, `innerRadius` 0.68, `angularInset` 2.
  - 가운데에 총 풀이 수 "142"와 캡션 "회 풀이".
  - 0회인 주제는 도넛에서 뺀다.
- **색**: 앱의 주제 색(`BookTopic.color`)을 쓴다. 여행 `sky`, 비즈니스 `sage`, 감정 `coral`, 일상 `butter`, 미분류 `gray45`. 단어장 주제 카드와 같은 색이다.
- **범례**
  - 도넛 오른쪽에 5개 행을 고정 순서로 둔다. 0회인 주제도 남긴다.
  - 행 내용: 색 점, 이름, "42회 · 30%". 높이 44pt.
- **선택**
  - 섹터를 터치하거나 범례를 탭하면 그 주제를 강조한다. 나머지 섹터는 불투명도 45%, 범례 행은 굵게.
  - 터치가 끝나도 선택을 유지한다(품사와 같음).
  - 선택하면 아래에 `StudyStatsSelection`으로 "여행 · 42회 · 전체의 30%"를 보여 준다.

### 5.4 학습 단어의 품사

- 지금 도넛을 그대로 쓴다. 기간 선택이 없어져서 전체 기간의 **고유 단어 수** 기준이 된다.
- 헤딩은 제목 "학습 단어의 품사", 부제 "고유 단어 기준"이다.
- 도넛 가운데는 "N / 고유 단어"로 둔다(지금과 같음).
- 선택 문구는 주제 카드와 같은 형식("명사 · 12개 · 전체의 30%")으로 맞춘다.
- 주제와 품사는 같은 컴포넌트로 그린다(§8.3). 그래서 섹터 색 순서, 범례, 선택 동작이 같다.

### 5.5 많이 틀린 단어 (신규)

- **헤딩**: 제목 "많이 틀린 단어", 부제 "정답률 70% 이하 · 12개"(고른 기준과 개수).
- **기준 세그먼트**
  - "70% 이하 | 40% 이하 | 20% 이하" 중 하나를 고른다. 기본은 70% 이하다.
  - **누적 필터**다. 고른 기준 이하인 단어가 전부 나오므로, 20% 이하 단어는 세 탭 모두에 나온다.
  - 고른 기준은 저장하지 않는다. 학습 통계를 다시 열면 70% 이하로 돌아간다.
- **판정**
  - 단어별 전체 기간 정답률을 **화면에 표시하는 반올림 정수(%)**로 비교한다. `StudyStatsStyle.percent`와 같은 반올림이다.
  - 정답률 70.4%는 "70%"로 표시되므로 70% 이하에 들어간다. 70.5%는 "71%"로 표시되므로 빠진다.
  - 최소 풀이 횟수 조건은 없다. 1회 풀어 틀린 단어(0%)도 들어간다.
- **정렬**: 오답 횟수가 많은 순 → 정답률이 낮은 순(반올림 전 값) → 최근에 푼 순 → id. 지금 '많이 맞힌 단어' 정렬을 뒤집은 것이다.
- **목록**: 고른 기준에 맞는 단어를 **전부** 카드 안에 이어서 보여 준다(`LazyVStack`). 개수 제한과 "전체 보기"는 없다.
- **행**: 지금 '많이 맞힌 단어' 행에서 순위 번호와 막대를 뺀 모양이다.
  - 1줄: 단어(굵게) ··· "오답 4회"
  - 2줄: 뜻(`secondary`)
  - 3줄: "정답률 33% · 전체 6회 풀이"(footnote, `secondary`)
  - 행 사이는 `space12` 간격과 얇은 구분선으로 나눈다. 행 높이는 44pt 이상이다.
- **행 탭**: 단어 상세 시트를 연다. 전체 기간 수치("정답 2 / 6회")를 보여 준다.
- **기준에 맞는 단어 없음**: 목록 자리에 `StudyStatsSelection` "정답률 20% 이하인 단어가 없어요"를 보여 준다. 세그먼트는 그대로 둔다.

### 5.6 학습한 단어 목록 (기존 화면 재사용)

요약 카드의 "누적 학습 단어 ›"에서만 연다. `StudyStatsWordListView`를 그대로 쓰고, 카드는 `StudyStatsWordCard`(파스텔 카드)다.

- 헤딩: "전체 학습 단어", 부제 "2026.5.11 – 2026.11.3 · 중복 제외 120개". 지금 '전체' 기간 목록과 같은 문구다.
- 안내: "정답 횟수순 · 단어를 누르면 상세 내용을 볼 수 있어요."
- 내비게이션 타이틀 "학습한 단어"와 ✕는 지금 그대로 둔다.

### 5.7 상태별 표시

| 상황 | 표시 |
|---|---|
| 첫 로드 중 | 지금과 같다: "학습 기록을 불러오고 있어요." + 회색 스켈레톤 카드 3개 |
| 첫 로드 실패 | 지금과 같다: `exclamationmark.circle` "기록을 불러오지 못했어요" + "다시 시도" |
| 다시 읽기 실패 | 요약 카드는 유지하고 누적 학습 단어 버튼을 비활성화한다. 그 아래 카드들 대신 실패 카드를 둔다 |
| 기록 0건 | 요약 카드를 숨기고 빈 상태 카드만 보여 준다. `book.closed` "첫 학습을 기다리고 있어요" / "퀴즈에서 답변을 저장하면 학습량과 정답률을 확인할 수 있어요." |
| 기준에 맞는 단어 없음 | §5.5 |

### 5.8 접근성

- 도넛
  - 섹터마다 라벨과 값을 붙인다. 주제는 "여행", "42회, 30%"이고, 품사는 지금 그대로다.
  - 범례 행은 버튼으로 만들고, 선택된 행에 선택 trait를 붙인다.
  - 접근성 글자 크기에서는 도넛과 범례를 세로로 쌓는다.
- 기준 세그먼트는 Picker 라벨 "정답률 기준"을 쓴다.
- 많이 틀린 단어 행은 하나의 요소로 묶는다. 예: "apple, 오답 4회, 사과, 정답률 33%, 전체 6회 풀이"(화면 순서대로).
- 접근성 식별자

| 대상 | 식별자 |
|---|---|
| 캘린더의 "학습 통계 ›" 버튼 | `calendar.stats` |
| 기준 세그먼트 | `studyStats.mistakeThreshold` |
| 많이 틀린 단어 행 | `studyStats.mistake.<목록 순서, 1부터>` |
| 주제 범례 행 | `studyStats.topics.<id>` |

## 6. 다크 모드 (공통)

새 색은 `grass` 하나만 추가하고, 나머지는 기존 토큰의 다크 값을 쓴다.

| 토큰 | 라이트 | 다크 |
|---|---|---|
| `background` | #FCFAF4 | #1A1712 |
| `card` (`StudyStatsCard` 배경) | #FFFFFF | #2B2720 |
| `textPrimary` | #1E1B15 | #F4EEE2 |
| `textSecondary` | #6A6A6E | #ABABAE |
| `primary`(ocean) | #4E88DA | #1F7AD6 |
| `grass` (신규) | #1F883D | #2EA043 |
| `sage` | #ABD18C | #2E8F44 |
| `sky` | #93CCDE | #0E7E92 |
| `coral` | #F4A688 | #CC4A28 |
| `butter` | #EFCD6A | #BE8516 |
| `lavender` | #B9A3F0 | #6A3FD0 |
| `gray45` | #ABABAE | #ABABAE |
| 내비게이션 버튼 (시스템 tint) | #007AFF | #0A84FF |

- `grass` (신규 초록)
  - Assets에 `grass` 컬러셋(라이트 #1F883D / 다크 #2EA043)을 추가하고, `AppColor`에 `static let grass = named("grass")`로 둔다.
  - 잔디·달력 농도, 칩, 오늘 테두리에만 쓴다. 빈 상태 아이콘, 다시 시도 버튼, 품사 도넛은 지금처럼 `primary`다.
  - 기존 `sage`(#ABD18C)는 라이트에서 흰 숫자·칩 글자와의 대비가 약 1.7:1이라 쓰지 않는다. `grass`의 대비는 흰 숫자 4.5:1 / 3.4:1, 칩 글자 3.9:1 / 3.8:1(라이트 / 다크)로 지금 파랑과 비슷한 수준이다.
- 내비게이션 바는 꾸미지 않는다. `AccentColor`가 비어 있어 버튼은 시스템 파랑, 타이틀은 시스템 `label`이다.
- 보조 글자는 모두 `AppColor.textSecondary`로 칠한다. 지금 코드의 `.secondary`(현재 글자색을 흐리게 하는 시스템 단계)는 모드마다 결과가 달라 이 색으로 바꾼다.

- 카드는 `StudyStatsCard`를 쓰고, 두 모드 모두 `AppColor.card`를 칠한다.
  - 지금 이 컴포넌트는 다크에서 시스템 `secondarySystemGroupedBackground`(#1C1C1E)를 칠한다. 배경 #1A1712와 대비가 약 1.04:1이라 카드 경계가 보이지 않는다.
  - 그래서 이번 리뉴얼에서 `AppColor.card`로 바꾼다(§8.3). 캘린더 카드(`CalendarCard`)도 처음부터 `AppColor.card`를 칠한다.
- 농도 단계는 두 모드에서 같은 불투명도를 쓴다. 다크에서 0단계 잔디 셀은 `gray45` 15%라서 카드 배경과 구분된다.
- 3단계 달력 셀 숫자는 두 모드 모두 흰색이다.

## 7. 데이터와 집계

### 7.1 원천

- `LearningHistoryRepository.fetchStatsRecords()`를 화면마다 한 번씩 읽어 메모리에서 집계한다. 새 저장소·엔티티는 만들지 않고, 저장소 동작과 Core Data 모델도 바꾸지 않는다(타입·메서드 이름만 `StudyStats`로 바뀐다).
- 캘린더와 학습 통계는 각자 읽는다. 한 모달 안에서 같은 기록을 두 번 읽게 된다.
  - 학습 통계 진입이 느려질 만큼 기록이 늘면, 캘린더가 읽은 `StudyStatsRecords`를 넘기는 방식으로 바꾼다.

### 7.2 캘린더 모델 (v2와 같음)

```swift
struct StudyCalendar: Equatable, Sendable {
    struct Day: Equatable, Sendable {
        let date: Date                  // startOfDay
        let words: [VocabStats]   // 그날 풀이만 집계
        let answerCount: Int
        let correctCount: Int
        let quizCount: Int              // 그날 기록의 고유 sessionId 수
        var level: Int { ... }          // §4.6 구간
    }
    let now: Date
    let calendar: Calendar
    let days: [Date: Day]               // 기록 있는 날만
    let earliestMonth: Date             // 첫 기록의 달, 기록 0건이면 현재 달
    let streak: Int
    let studiedDayCount: Int
}
```

- 잔디 53주와 달력 6행은 뷰가 그릴 때마다 `days`에서 꺼낸다. 날짜 배열을 미리 만들어 두지 않는다.
- `VocabStats` 생성과 정답 횟수순 정렬은 `[LearningHistory].vocabStats()`(`VocabStats.swift`)를 함께 쓴다.
- 연속일 계산(`streak`)은 통계 유스케이스에서 캘린더 유스케이스로 옮긴다.

### 7.3 학습 통계 모델 (`StudyStats` 축소)

```swift
enum StudyStatsMistakeThreshold: Int, CaseIterable, Sendable {
    case seventy = 70, forty = 40, twenty = 20
    func contains(_ word: VocabStats) -> Bool   // 반올림 정답률 <= rawValue
}

struct StudyStats: Equatable, Sendable {
    struct Category { ... }        // wrong 제거
    let now: Date
    let calendar: Calendar
    let start: Date                // 첫 기록일 (단어 목록 부제의 기간), 기존 allStart
    let totalAnswers: Int
    let totalCorrect: Int
    let words: [Word]              // 전체 기간, 정답 횟수순 (기존 allWords)
    let mistakeWords: [Word]       // 정답률 70% 이하, 오답 횟수순
    let topics: [Category]         // 주제별 풀이 횟수
    let parts: [Category]          // 품사별 고유 단어 수
}
```

- 40%와 20% 목록은 `mistakeWords`를 `contains`로 걸러 만든다. 걸러도 순서가 유지되므로 다시 정렬하지 않는다.
- 빼는 것
  - `period`, `periodStart`, `streak`, `weekWordCount`, `monthWordCount`, `recentDays`
  - 기간 `words`, `periodAnswerCount`, `activity`, `sessions`, `mistakesByPart`, `hasActivity`
  - `Activity` 타입, `Session` 타입
- `StudyStatsPeriod`도 뺀다.

### 7.4 집계 규칙

- 날짜 경계는 `calendar.startOfDay`(기기 시간대)를 쓴다. `createAt > now`인 기록은 뺀다. 두 화면 모두 같다.
- 캘린더
  - 농도와 요약의 "단어 수"는 그날의 고유 `statsWordId` 수다.
  - 달 이동과 잔디 탭에서는 다시 읽지 않는다.
- 학습 통계: 전체 기간을 한 번에 집계한다.
- 두 화면 모두 화면 복귀(`scenePhase` active), 날짜 변경(`NSCalendarDayChanged`), 시간대 변경 때만 다시 읽는다.
- 학습 통계에서 캘린더로 돌아올 때는 다시 읽지 않는다. 다만 첫 로드가 끝나기 전에 학습 통계로 넘어갔다면 그 로드는 취소되고, 돌아올 때 다시 읽는다.

## 8. 구현 구조

### 8.1 `CalendarFeature` (신규, v2와 같음)

통계와 같은 SwiftUI + TCA 구조다. `UIHostingController` 서브클래스 없이 Coordinator가 Store를 만들어 감싼다.

- State: `calendar: StudyCalendar?`, `displayedMonth: Date`, `selectedDate: Date?`, `loadStatus`
- Action
  - 로드: `appeared`, `refresh`, `loaded`, `loadFailed`, `disappeared`
  - 달과 날짜: `monthMoved(Int)`, `monthPicked(Date)`, `todayTapped`, `dateTapped(Date)`, `heatmapTapped(Date)`
  - 이동: `wordTapped(UUID)`, `statsButtonTapped`(v3 추가), `closeButtonTapped`
- 동작 규칙
  - `dateTapped`와 `heatmapTapped`는 미래 날짜를 무시한다. `heatmapTapped`는 `displayedMonth`도 바꾼다.
  - `monthMoved`와 `monthPicked`는 `earliestMonth`~현재 달 범위로 제한하고 선택을 해제한다.
  - `statsButtonTapped`는 `onNavigate(.stats)`를 부른다. 로딩 상태와 상관없이 동작한다.
- 유스케이스: `FetchCalendarUseCase`(`MainDIContainer`에서 조립)
- 뷰 컴포넌트: `CalendarHeatmap`, `CalendarMonthGrid`, `CalendarChip`, `CalendarWordCard`, 공통 모양 컴포넌트(§8.3)
  - `CalendarWordCard`: UIKit 셀(`VocabBookDetailCollectionViewCell`)은 SwiftUI `LazyVStack`에 바로 넣을 수 없어, 같은 수치로 SwiftUI 뷰를 새로 만든다.

### 8.2 `StudyStatsFeature` (학습 통계로 수정)

화면 이름은 "학습 통계"이고, 타입과 파일 이름은 `StudyStats*`다(기존 `StudyReport*`에서 이름만 바꿈).

- **State**
  - 남김: `stats`, `loadStatus`, `selectedTopic`, `selectedPart`
  - 뺌: `period`, `selectedActivity`, `selectedSession`, `selectedMistake`, `mistakeKind`
  - 추가: `mistakeThreshold = .seventy`
- **Action**
  - 뺌: `periodChanged`, `activitySelected`, `sessionSelected`, `mistakeSelected`, `mistakeKindChanged`
  - 바꿈: `wordsTapped(StudyStatsPeriod)` → `wordsTapped`(전체 학습 단어)
  - 추가: `mistakeThresholdChanged(StudyStatsMistakeThreshold)`
  - `wordTapped(UUID)`: 전체 `words`에서 찾는다.
  - `topicSelected(String?)`: `nil`(터치 끝)을 무시한다. 품사와 같다.
- **기타 변경**
  - `fetch`: `(Date, Calendar)`. `FetchStudyStatsUseCase.execute(now:calendar:)`로 기간 인자를 뺀다.
  - `appeared`: `stats == nil`일 때만 읽는다.
  - 뷰: `navigationTitle("학습 통계")`. 기간 Picker와 버린 카드들을 지운다.

### 8.3 컴포넌트

`StudyStatsComponents.swift`의 컴포넌트와 스타일(`StudyStatsStyle` 포함)은 학습 통계에서만 쓴다. 캘린더는 같은 시안 수치로 `Feature/Calendar/Components`에 따로 만든다.

| 시안 | 학습 통계 | 캘린더 |
|---|---|---|
| 스타일 (글꼴·퍼센트·날짜) | `StudyStatsStyle` | `CalendarStyle` |
| C3 카드 | `StudyStatsCard` | `CalendarCard` |
| C4 제목 | `StudyStatsHeading` | `CalendarHeading` |
| C5 안내 | `StudyStatsSelection` | `CalendarSelection` |
| C15 빈·실패·로딩 | `StudyStatsView` 안 (지금 그대로) | `CalendarStateCard` |
| C16 단어 상세 카드 | `StudyStatsWordCard` | `CalendarWordDetailCard` ("이날" 접두어) |

학습 통계

- `StudyStatsPartsChart` → `StudyStatsDonutChart`로 일반화한다.
  - 인자: `categories`, `kind`, 가운데 숫자와 캡션, 값 단위("회"/"개").
  - 주제 카드와 품사 카드가 같이 쓴다.
  - 색: 주제는 `BookTopic(rawValue: id)?.color ?? AppColor.gray45`, 품사는 지금처럼 `StudyStatsStyle.color(index)`.
- `StudyStatsHeading`과 학습 통계의 보조 글자: `.secondary` → `Color(AppColor.textSecondary)`(§6). 캘린더 컴포넌트는 처음부터 `AppColor.textSecondary`를 쓴다.
- 많이 틀린 단어 행: 지금 `StudyStatsView`의 '많이 맞힌 단어' 행 코드에서 순위 번호와 `StudyStatsHorizontalBar`를 뺀다.
- `StudyStatsWordList`: `period`를 뺀다. 목록이 '전체 학습 단어' 하나뿐이라 헤딩 제목은 뷰에 고정 문구로 둔다.
- `StudyStatsCard`: 배경을 모드 분기 없이 `Color(AppColor.card)` 하나로 바꾼다(§6). 그러면 `colorScheme` 환경값이 필요 없어지므로 지운다.

### 8.4 내비게이션

```swift
enum StudyStatsDestination: Equatable, Sendable {
    case stats                                   // 캘린더 → 학습 통계
    case words(StudyStatsWordList)                // 학습 통계 → 단어 목록
    case word(VocabStats, isDaily: Bool)     // 단어 상세 시트, true면 "이날" 표기
}
```

- `.word`의 두 번째 값(목록)은 지금 코디네이터가 쓰지 않는다. 그래서 그날 집계 여부로 바꾼다. enum 모양과 학습 통계의 `isDaily: false` 전송은 계약 커밋에 반영했고, `isDaily: true` 처리는 캘린더 작업에서 추가한다.
- `MainCoordinator.didTapCalendarButton`
  - 모달 루트를 `CalendarView`로 바꾼다(전체 화면 모달, 같은 `nav`).
  - `.stats`를 받으면 `makeStudyStatsFeature`로 Store를 만들고, `StudyStatsView`를 같은 `nav`에 push한다.
  - 두 Feature의 `onClose`는 모두 모달을 dismiss한다.
- `.words`와 `.word`는 지금 `showStudyStats`가 그대로 처리한다. 상세는 `.pageSheet`, `[.medium(), .large()]`로 연다.
  - `.word(_, isDaily: true)`는 `CalendarWordDetailCard`로 그린 상세 시트, `false`는 `StudyStatsWordDetailView`를 연다.
- `MainDIContainer`: `makeCalendarFeature(onClose:onNavigate:)`를 추가하고, `UITestingSupport` 분기도 캘린더용으로 하나 더 둔다.
- 단어 탐색의 진입 버튼은 그대로 두고, 식별자만 `explore.studyStats`로 바꾼다.

### 8.5 지우는 코드

리뉴얼로 쓰이지 않게 되는 것만 지운다.

- 엔티티와 유스케이스
  - `StudyStatsPeriod`와 그 `title` 확장
  - `StudyStats`의 기간·연속·회차 필드, `Activity` 타입, `Session` 타입, `Category.wrong`
  - `DefaultFetchStudyStatsUseCase`의 기간 버킷 집계, `completedSessions`, `dates`
  - 여기서 `streak`는 지우지 않고 캘린더 유스케이스로 옮긴다.
- 컴포넌트
  - `StudyStatsActivityChart`, `StudyStatsSessionChart`
  - `StudyStatsCategoryBars`, `StudyStatsHorizontalBar`, `StudyStatsAnswerBar`
  - `StudyStatsCategoryKind.title`(오답 분류 세그먼트용)
- 남기는 것
  - `StudyStatsRecords.sessions`: 저장소가 계속 읽어 검증하고, 집계에서만 쓰지 않는다.
  - `StudyStatsDataError`: 저장소와 마이그레이션이 계속 쓴다.
- 미리보기와 UI 테스트 지원: `StudyStatsPreviews`, `StudyStatsUITestingSupport`를 새 모델에 맞게 고친다.

## 9. 엣지 케이스

- **자정 넘김**: `NSCalendarDayChanged`가 오면 다시 읽는다. 선택한 날짜가 어제의 "오늘"이면 새 오늘로 옮긴다.
- **1년보다 오래된 기록**: 잔디에는 안 보이지만 달력은 `earliestMonth`까지 이동할 수 있다. 학습 통계는 전체 기간이라 모두 포함된다.
- **주 시작 요일 변경**: 잔디 행 순서·요일 라벨과 달력 머리글이 함께 바뀐다.
- **이웃 달 날짜**: 달력에서는 흐리게만 표시하고 탭할 수 없다. 그 날짜는 잔디 탭이나 달 이동으로 고른다.
- **한 날짜나 한 기준에 단어가 많을 때**: 목록은 `LazyVStack`으로 전부 보여 준다.
- **정답률 경계**: 화면 표기와 같은 반올림으로 판정한다(§5.5). 이렇게 해야 "70%"로 보이는 단어가 70% 이하에서 빠지는 일이 없다.
- **풀이 1회 단어**
  - 1회 틀린 단어는 0%라서 세 기준 모두에 나온다.
  - 정렬은 오답 횟수가 먼저라서, 여러 번 틀린 단어가 이 단어보다 위에 온다.
- **단어 표시 정보**: 단어·뜻·품사는 마지막 풀이의 스냅샷을 쓴다(지금 규칙).
- **주제와 품사의 단위 차이**: 주제는 풀이 횟수, 품사는 고유 단어 수다. 각 카드의 부제와 도넛 가운데 캡션으로 구분한다.
- **캘린더 첫 로드 중 학습 통계로 이동**: 캘린더 로드는 취소된다. 학습 통계는 따로 읽고, 캘린더로 돌아오면 다시 읽는다.

## 10. 테스트

### 10.1 신규

- `FetchCalendarUseCaseTests`
  - 농도 경계 0/1/4/5/14/15
  - 같은 단어를 하루에 여러 번 풀면 단어 수는 1이고 풀이 수는 합산된다.
  - 자정 직전과 직후 기록이 다른 날로 나뉜다. 시간대가 다른 `Calendar`도 확인한다.
  - `earliestMonth`, 기록 0건일 때는 현재 달
  - `createAt > now` 제외
  - 연속일: 통계 테스트에서 옮겨 온다. 오늘 기록이 없으면 어제부터 센다.
- `CalendarFeatureTests`
  - 진입 시 현재 달과 오늘이 선택된다.
  - 달 이동 경계(현재 달의 ›, `earliestMonth`의 ‹)는 무시되고, 이동하면 선택이 해제된다.
  - `heatmapTapped`가 다른 달 날짜면 `displayedMonth`가 바뀐다.
  - 미래 날짜 탭은 무시된다.
  - `todayTapped`는 다른 달에서 현재 달로 돌아온다.
  - 다시 읽기에 실패해도 기존 `calendar`를 유지한다.
  - 로딩 중 `disappeared`로 취소된다.
  - `statsButtonTapped`가 `onNavigate(.stats)`를 부른다. 로딩 중에도 마찬가지다.

### 10.2 수정

- `StudyStatsAggregationTests`
  - 지움: 기간, 활동 막대, 회차, 최근 7일·이번 달, 연속일 케이스
  - 추가
    - `mistakeWords` 경계: 70.4% 포함, 70.5% 제외, 0% 포함, 100% 제외
    - 40%와 20% 기준 거르기
    - 정렬: 오답 횟수 → 정답률 → 최근 풀이 → id
    - `topics`는 전체 기간 풀이 수, `parts`는 전체 기간 고유 단어 수
- `StudyStatsFeatureTests`
  - 지움: 기간 변경, 활동·회차·오답 분류 선택
  - 추가
    - `mistakeThresholdChanged`
    - `wordTapped`가 전체 단어에서 찾는다. 40%·20% 기준 목록의 단어도 찾는다.
    - `appeared`는 `stats == nil`일 때만 읽는다.
- `StudyStatsViewTests`: 테스트 3개가 모두 `StudyStatsAnswerBar` 테스트라 파일째 지운다.
- `StudyStatsUITests`
  - 진입 경로가 '차트 아이콘 → 캘린더 → `calendar.stats`'로 바뀐다.
  - 지우는 식별자를 쓰는 케이스는 지우거나 새 카드 기준으로 바꾼다.
    - 지우는 식별자: `studyStats.period`, `studyStats.mistakeKind`, `studyStats.sessionChart`, `studyStats.rank.*`, `studyStats.mistakes.*`
    - 바꿀 대상: 많이 틀린 단어 행, 도넛 선택 유지
- `AppDIContainerTests`: 캘린더 Feature 조립을 추가로 확인한다.

## 11. 결정 사항

| 항목 | 결정 |
|---|---|
| 진입 화면 | 캘린더. 단어 탐색의 차트 아이콘은 그대로 |
| 학습 통계 진입 | 캘린더 내비 오른쪽 "학습 통계 ›" 텍스트 버튼 |
| 캘린더 닫기 | 캘린더 내비 왼쪽 ✕. 하위 화면의 ✕는 오른쪽 그대로 |
| 캘린더 강조 색 | 새 초록 토큰 `grass`(잔디·달력 농도, 칩, 오늘 테두리) |
| 연속 학습 | 캘린더 칩으로 옮기고 학습 통계에서는 뺀다 |
| 학습 통계 기간 | 기간 선택 없이 전체 기간 고정 |
| 많이 틀린 종류 | 버린다 |
| 주제별 학습 비중 | 도넛, 기준은 지금과 같은 풀이 횟수 |
| 많이 틀린 단어 기준 | 70%·40%·20% 이하 누적 필터, 기본 70%, 저장하지 않음 |
| 정답률 판정 | 화면 표기와 같은 반올림 정수 |
| 최소 풀이 횟수 | 없음 |
| 많이 틀린 단어 정렬 | 오답 횟수순 |
| 많이 틀린 단어 표시 | 고른 기준의 단어 전부. 전체 보기, 순위 번호, 막대 없음 |
| 학습 통계 기록 0건 | 요약 카드를 숨기고 빈 상태 카드만 |
| 학습 통계 카드 순서 | 요약 → 주제 → 품사 → 많이 틀린 단어 |
| 타입 이름 | `StudyReport*` → `StudyStats*`(저장소·마이그레이션 포함), `StudyCalendar*` → `Calendar*`(모델 `StudyCalendar`만 유지). `StudyStats.Word` → 최상위 `VocabStats`(`LearningStats`와 별개). 저장된 UserDefaults 키·Core Data 모델은 그대로 |
| 화면·모달 이름 | "학습 통계". ✕ 접근성 라벨은 "학습 통계 닫기" |
| 컴포넌트 공유 | `StudyStatsComponents`는 학습 통계 전용. 캘린더는 같은 시안 수치로 `Calendar*` 컴포넌트를 따로 만든다 |
| 날짜별 노트 | 제외 |
| 잔디 농도 | 4단계, 고유 단어 수 기준 |
| 달력 셀 | 잔디와 같은 4단계 농도 |
| 잔디 기간 | 최근 53주 고정 |
| 달력 행 수 | 6행 고정, 이웃 달 날짜 흐리게 |
| 캘린더 타이틀 | "캘린더" |
| 날짜별 단어 정렬 | 정답 횟수순 |
| 기록 0건 문구 우선순위 | 빈 상태 카드가 오늘 문구보다 우선 |
| 다크 모드 | 기존 토큰 다크 값, 새 색 없음 |
| 다크 카드 색 | `StudyStatsCard`를 시스템 색에서 `AppColor.card`(#2B2720)로 변경. `CalendarCard`도 같은 색 |
| 주제 도넛 색 | 앱의 주제 색(`BookTopic.color`) |
| 내비게이션 바 | 시스템 기본, 버튼은 시스템 파랑(코드 지정 없음) |
| 보조 글자 색 | `AppColor.textSecondary`, `.secondary` 쓰지 않음 |
| 잔디 선택 테두리 | 안쪽 1.5pt(`AppBorder.regular`) |
| 세부 수치 | 디자인 시안 C1–C16 |
| 날짜별 단어 카드 | 단어장 상세 카드 모양, 북마크 없음. 상세 시트는 `CalendarWordDetailCard`(`StudyStatsWordCard`와 같은 수치, "이날" 접두어) |
