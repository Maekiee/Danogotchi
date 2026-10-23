import Foundation

/// 기기에 저장되는 사용자 설정. 테마 파일명은 상태를 소유하고 변경을 스트림으로 알린다.
protocol UserSettingsRepository: AnyObject {
    /// 선택한 원본 사진의 URL. 로컬 파일이 사라졌을 때의 복구에 쓴다. 사진첩에서 고른 사진은 원본이 없어 nil이다.
    var currentThemeUrl: String? { get set }
    /// 로컬에 저장된 배경 이미지 파일명. 앱 컨테이너 경로는 재설치·복원 시 바뀌므로 파일명만 보관한다.
    var currentThemeImageFileName: String? { get set }
    var isStudyReminderEnabled: Bool { get set }
    /// 구독 즉시 현재 파일명을 보내고, 바뀔 때마다 새 파일명을 보낸다.
    var themeImageFileNameChanges: AsyncStream<String?> { get }
}

extension UserSettingsRepository {
    /// 테마를 한 번이라도 지정했는가 — 온보딩 완료 판별에 쓴다.
    /// 사진첩 테마는 rawUrl이 없고, themeImageFileName 키가 없던 버전에서 올라온 사용자는 파일명이 없다.
    /// 둘 중 하나라도 있으면 완료로 본다.
    var hasSelectedTheme: Bool {
        return currentThemeImageFileName != nil || currentThemeUrl != nil
    }
}
