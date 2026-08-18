import UIKit
import SnapKit


/// `[포만감] [====게이지====] [82]` 한 줄. 네 수치가 같은 구조를 쓴다.
final class CareStatRowView: UIView {

    private let stat: PetCareStat

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.label
        label.textColor = AppColor.textPrimary
        return label
    }()
    private lazy var gaugeView = CustomProgressView(fillColor: stat.color)
    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.footnote
        label.textAlignment = .right
        return label
    }()

    init(stat: PetCareStat) {
        self.stat = stat
        super.init(frame: .zero)
        configHierarchy()
        configLayout()
        configView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configHierarchy() {
        [
            titleLabel,
            gaugeView,
            valueLabel,
        ].forEach { addSubview($0) }
    }

    private func configLayout() {
        titleLabel.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
            make.width.equalTo(52)
        }

        valueLabel.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
            make.width.equalTo(32)
        }

        gaugeView.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel.snp.trailing).offset(AppSpacing.space8)
            make.trailing.equalTo(valueLabel.snp.leading).offset(-AppSpacing.space8)
            make.centerY.equalToSuperview()
            make.height.equalTo(12)
            make.verticalEdges.equalToSuperview().inset(AppSpacing.space4)
        }
    }

    private func configView() {
        titleLabel.text = stat.title
        // 게이지 색만으로는 상태가 전달되지 않는다 — 한 줄을 통째로 읽어준다
        isAccessibilityElement = true
        accessibilityLabel = stat.title
    }

    func update(value: Double) {
        let isDanger = value <= PetStatePolicy.dangerThreshold
        // 버림으로 표시하면 갓 만든 펫의 `99.96`이 `99`로 뜬다 —
        // 게이지는 꽉 찼는데 숫자만 모자라 보이고, 돌보기가 `+1`만 하는 것처럼 읽힌다
        let displayValue = Int(value.rounded())

        gaugeView.setProgress(Float(value / PetStatePolicy.maxStat), animated: true)
        valueLabel.text = "\(displayValue)"
        // 위험은 색과 문구 양쪽으로 알린다
        valueLabel.textColor = isDanger ? AppColor.error : AppColor.textSecondary
        accessibilityValue = isDanger ? "\(displayValue)퍼센트, 위험" : "\(displayValue)퍼센트"
    }
}
