import UIKit
import SnapKit


/// HP를 하트 10칸으로 표시한다.
/// 하트 에셋이 없어 SF Symbol 하나를 두 겹으로 깔고 위쪽을 폭으로 잘라 부분 채움을 만든다 —
/// `heart.fill` / `heart.righthalf.filled`만으로는 `2/3`·`1/3`을 표현할 수 없다.
/// 에셋이 들어오면 바꿀 곳은 `slot(fill:)` 하나뿐이다.
final class HeartBarView: UIView {

    private static let slotSize: CGFloat = 20

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = AppSpacing.space2
        return stack
    }()

    /// 칸마다 채움 폭을 쥔 제약. `setHearts`는 이 값만 갱신한다.
    private var clipWidthConstraints: [Constraint] = []

    init() {
        super.init(frame: .zero)
        configHierarchy()
        configLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configHierarchy() {
        addSubview(stackView)
        (0..<PetHeartPolicy.heartCount).forEach { _ in
            stackView.addArrangedSubview(makeSlot())
        }
    }

    private func configLayout() {
        stackView.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
        }
    }

    private func makeSlot() -> UIView {
        let slot = UIView()
        slot.snp.makeConstraints { make in
            make.size.equalTo(Self.slotSize)
        }

        // 빈 배경 슬롯 — HP 단계가 아니라 하트가 있던 자리를 드러내는 용도다
        let emptyImage = UIImageView(image: UIImage(systemName: "heart.fill"))
        emptyImage.tintColor = AppColor.gray30
        slot.addSubview(emptyImage)
        emptyImage.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        let clipView = UIView()
        clipView.clipsToBounds = true
        slot.addSubview(clipView)
        clipView.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            clipWidthConstraints.append(make.width.equalTo(0).constraint)
        }

        // 채움 이미지는 clipView가 아니라 슬롯 크기에 못박는다 —
        // clipView에 맞추면 잘릴 때 하트가 가로로 찌그러진다
        let fillImage = UIImageView(image: UIImage(systemName: "heart.fill"))
        fillImage.tintColor = AppColor.error
        clipView.addSubview(fillImage)
        fillImage.snp.makeConstraints { make in
            make.leading.top.equalToSuperview()
            make.size.equalTo(Self.slotSize)
        }

        return slot
    }

    func setHearts(_ fills: [PetHeartFill]) {
        for (index, constraint) in clipWidthConstraints.enumerated() {
            let ratio = index < fills.count ? fills[index].widthRatio : 0
            constraint.update(offset: Self.slotSize * ratio)
        }
    }
}


private extension PetHeartFill {
    var widthRatio: CGFloat {
        switch self {
        case .empty: return 0
        case .oneThird: return 1.0 / 3
        case .half: return 1.0 / 2
        case .twoThirds: return 2.0 / 3
        case .full: return 1
        }
    }
}
