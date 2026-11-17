import Foundation


/// 이름 입력의 세 가지 상태. 화면이 "아직 안 썼다"와 "너무 길다"를 구분해야
/// 입력 전부터 빨간 문구를 띄우는 일이 없다.
enum PetNameValidation: Equatable {
    /// 아직 안 썼거나 공백뿐 — 안내 없이 완료 버튼만 잠근다
    case empty
    /// 상한 초과. 실제 글자 수를 함께 돌려준다
    case tooLong(Int)
    /// 앞뒤 공백을 제거한 저장 가능한 이름
    case valid(String)
}

/// 펫 이름 검증. 입력 화면의 규칙이지만 ViewModel에 두면 테스트할 수 없어(테스트 타깃에 RxSwift 링크 없음)
/// 다른 정책들과 같은 자리에 순수 타입으로 둔다.
enum PetNamePolicy {

    static let maxLength = 10

    /// 앞뒤 공백·줄바꿈을 제거한 뒤 판정한다.
    /// 길이는 `Character` 기준이라 한글 조합 문자와 이모지가 1자로 세어진다.
    static func validate(_ raw: String) -> PetNameValidation {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty { return .empty }
        if trimmed.count > maxLength { return .tooLong(trimmed.count) }

        return .valid(trimmed)
    }
}
