import Foundation
import OSLog
import UIKit

/// Composition Root. 앱 스코프 인스턴스를 여기서만 생성하고, 기능별 컨테이너를 만들어 넘긴다.
final class AppDIContainer {
    private let dependencies: AppDependencies
    private let databasePreparer: DatabasePreparing

    /// 앱 시작 실패 보고에도 쓴다
    var reportError: @Sendable (Error) -> Void { dependencies.reportError }

    /// screenPixelSize는 SceneDelegate가 연결된 UIWindowScene.screen에서 읽어 넘긴다
    /// window는 화면 모드를 걸 앱 창이다
    /// databasePreparer·reportError는 테스트가 시작 실패 경로를 검증할 때만 넘긴다
    init(
        screenPixelSize: CGSize,
        window: UIWindow,
        databasePreparer: DatabasePreparing? = nil,
        reportError: @escaping @Sendable (Error) -> Void = { CrashReporter.record($0) }
    ) {
        let coreDataStack = CoreDataStack(
            modelName: "Model",
            willLoadStore: { url, model in
                try DatabasePreparationError.tagging(.preflight) {
                    try StudyStatsMigration.preflight(storeURL: url, destinationModel: model)
                }
            },
            didLoadStore: { context in
                try DatabasePreparationError.tagging(.backfill) {
                    try StudyStatsMigration.backfillIfNeeded(context: context)
                }
            }
        )
        dependencies = AppDependencies(
            screenPixelSize: screenPixelSize,
            coreDataStack: coreDataStack,
            apiClient: DefaultApiClient(),
            speechSynthesizer: SystemSpeechSynthesizer(),
            themeImageStorage: ImageFileStorage(directoryName: "ThemeImage"),
            userSettingsRepository: DefaultUserSettingsRepository(),
            vocabBookRepository: DefaultVocabBookRepository(context: coreDataStack.viewContext),
            petRepository: DefaultPetRepository(context: coreDataStack.viewContext),
            appearanceApplier: WindowAppearanceApplier(window: window),
            reportError: reportError
        )
        self.databasePreparer = databasePreparer ?? CoreDataPreparer(stack: coreDataStack)
    }

    func makeDatabasePreparer() -> DatabasePreparing {
        return databasePreparer
    }

    /// shortcut: 실행마다 DB 준비 직후 한 번만 설정해 세션 중 단어 수·펫 변화는 반영하지 않는다. 필요해지면 저장 지점에서 갱신
    func recordStoreContextForCrashReports() {
        do {
            let vocabCount = try dependencies.makeVocabRepository().countAllVocabs()
            CrashReporter.setValue(CrashContext.vocabCountBucket(vocabCount), for: .vocabCountBucket)
            let pet = try dependencies.petRepository.readPet()
            CrashReporter.setValue(CrashContext.petStage(pet, now: Date()), for: .petStage)
        } catch {
            // 진단용 부가 정보라 읽기 실패가 앱 진입을 막지 않는다
            AppLogger.database.error("크래시 맥락 읽기 실패: \(String(describing: error), privacy: .public)")
        }
    }

    func makeStudyReminderUseCase() -> StudyReminderUseCase {
        return dependencies.makeStudyReminderUseCase()
    }

    func makeOnboardingProgressUseCase() -> OnboardingProgressUseCase {
        return dependencies.makeOnboardingProgressUseCase()
    }

    func makeAppearanceModeUseCase() -> AppearanceModeUseCase {
        return dependencies.makeAppearanceModeUseCase()
    }

    func makeOnboardingDIContainer() -> OnboardingDIContainer {
        return OnboardingDIContainer(dependencies: dependencies)
    }

    func makeMainDIContainer() -> MainDIContainer {
        return MainDIContainer(dependencies: dependencies)
    }
}

#if DEBUG
extension AppDIContainer {
    /// UI 테스트 전용 — 온보딩을 건너뛰고 여행 단어장을 학습 중인 메인 화면 상태를 만든다
    func seedMainFlowForUITesting() throws {
        try seedThemeSelectedForUITesting()
        _ = try DefaultCreatePetUseCase(petRepository: dependencies.petRepository).execute(type: .sprout, name: "테스트")
    }

    /// UI 테스트 전용 — 관심사·테마까지만 고른 상태. 펫이 없어 온보딩이 알 선택부터 이어진다
    func seedThemeSelectedForUITesting() throws {
        try makeDatabasePreparer().prepareIfNeeded()
        let travel = VocabBookKey(topic: .travel, level: .a1)
        _ = try dependencies.vocabBookRepository.importBook(
            key: travel, vocabs: UITestingSupport.vocabs(key: travel), isActive: true
        )
        // 없는 파일명만 지정 — 원본 URL이 없어 복구 다운로드가 일어나지 않는다
        dependencies.userSettingsRepository.currentThemeImageFileName = "ui-test-theme.png"
    }

    /// UI 테스트 전용 — 주어진 이미지를 실제 테마 파일로 저장하고 배경으로 지정한다
    func seedThemeImageForUITesting(_ data: Data) throws {
        let fileName = "ui-test-solid-theme.png"
        try dependencies.themeImageStorage.save(data, fileName: fileName)
        dependencies.userSettingsRepository.currentThemeImageFileName = fileName
    }
}
#endif
