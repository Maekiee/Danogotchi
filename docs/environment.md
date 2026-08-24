# 빌드 환경 / 의존성 / UI

## 환경(스킴) 상태

### `Danogotchi-dev` (개발)
- 앱 표시명: `단어고치[DEV]`
- 번들 ID: DEV 접미사 포함

### `Danogotchi` (운영)
- 앱 표시명: `단어고치`
- 번들 ID: `com.maekie.Danogotchi`

### 공통 사항
- 빌드 페이즈에서 환경에 맞는 `GoogleService-Info.plist`가 자동 복사된다.

## 로컬 DB

- CoreData 사용. 스택은 `Core/Storage/CoreDataStack.swift` — `NSPersistentContainer(name: "Model")` 싱글턴, `viewContext`에 자동 머지 + `NSMergeByPropertyObjectTrumpMergePolicy` 적용.
- 모델 파일: `Shared/Data/DataSources/CoreDataEntities/Model.xcdatamodeld` (엔티티: `VocabEntity` / `VocabBookEntity` / `LearningHistoryEntity`).
- 스키마 변경 시 마이그레이션 처리 필요. **모델을 in-place 수정하면 기존 스토어를 가진 기기는 앱 삭제 후 재설치해야 한다.**
- 첫 실행 시 `Shared/Data/DatabaseSeeder.swift`가 추천 단어장을 시드한다.

