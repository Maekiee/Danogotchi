import UIKit
import SnapKit

/// 학습 결과 요약 카드. 점수·정답/오답 개수와 획득 경험치를 보여준다.
final class QuizResultCard: UIView {

    // MARK: - UI 프로퍼티
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.appWhite
        view.layer.cornerRadius = 30
        view.layer.borderWidth = AppBorder.regular
        view.layer.borderColor = UIColor.black.cgColor
        return view
    }()

    private let scoreLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.largeDisplay
        label.textColor = AppColor.textPrimary
        label.textAlignment = .center
        return label
    }()

    private let summaryLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.label
        label.textColor = AppColor.textSecondary
        label.textAlignment = .center
        return label
    }()

    private let horizontalDivider = QuizResultCard.makeDivider()
    private let verticalDivider = QuizResultCard.makeDivider()
    private let experienceDivider = QuizResultCard.makeDivider()
    private let experienceVerticalDivider = QuizResultCard.makeDivider()

    private let correctItem = CountItem(caption: "정답", dotColor: AppColor.appGreen)
    private let incorrectItem = CountItem(caption: "오답", dotColor: AppColor.appRed)
    private let experienceItem = CountItem(caption: "획득 경험치", dotColor: AppColor.butter)
    private let pointItem = CountItem(caption: "보유 포인트", dotColor: AppColor.lavender)

    // MARK: - Public Properties
    var scoreText: String? {
        get { scoreLabel.text }
        set { scoreLabel.text = newValue }
    }

    var summaryText: String? {
        get { summaryLabel.text }
        set { summaryLabel.text = newValue }
    }

    var correctText: String? {
        get { correctItem.countText }
        set { correctItem.countText = newValue }
    }

    var incorrectText: String? {
        get { incorrectItem.countText }
        set { incorrectItem.countText = newValue }
    }

    var experienceText: String? {
        get { experienceItem.countText }
        set { experienceItem.countText = newValue }
    }

    var pointText: String? {
        get { pointItem.countText }
        set { pointItem.countText = newValue }
    }

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupHierarchy()
        setupLayout()
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupHierarchy() {
        addSubview(containerView)
        [
            scoreLabel,
            summaryLabel,
            horizontalDivider,
            verticalDivider,
            correctItem,
            incorrectItem,
            experienceDivider,
            experienceVerticalDivider,
            experienceItem,
            pointItem
        ].forEach { containerView.addSubview($0) }
    }

    private func setupLayout() {
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        scoreLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(AppSpacing.space32)
            make.centerX.equalToSuperview()
        }

        summaryLabel.snp.makeConstraints { make in
            make.top.equalTo(scoreLabel.snp.bottom).offset(AppSpacing.space8)
            make.centerX.equalToSuperview()
        }

        layoutRow(divider: horizontalDivider, verticalDivider: verticalDivider,
                  left: correctItem, right: incorrectItem,
                  below: summaryLabel, topSpacing: AppSpacing.space24)

        layoutRow(divider: experienceDivider, verticalDivider: experienceVerticalDivider,
                  left: experienceItem, right: pointItem,
                  below: correctItem, topSpacing: AppSpacing.space20)

        // 카드 높이는 마지막 행의 컨텐츠 높이로 결정된다
        experienceItem.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-AppSpacing.space32)
        }
    }

    /// 구분선 아래에 좌/우 2열 항목과 가운데 세로 구분선을 한 행으로 배치한다
    private func layoutRow(
        divider: UIView,
        verticalDivider: UIView,
        left: UIView,
        right: UIView,
        below: UIView,
        topSpacing: CGFloat
    ) {
        divider.snp.makeConstraints { make in
            make.top.equalTo(below.snp.bottom).offset(topSpacing)
            make.horizontalEdges.equalToSuperview().inset(AppSpacing.space24)
            make.height.equalTo(AppBorder.thin)
        }

        left.snp.makeConstraints { make in
            make.top.equalTo(divider.snp.bottom).offset(AppSpacing.space20)
            make.leading.equalToSuperview().offset(AppSpacing.space24)
            make.trailing.equalTo(verticalDivider.snp.leading).offset(-AppSpacing.space16)
        }

        right.snp.makeConstraints { make in
            make.top.bottom.equalTo(left)
            make.leading.equalTo(verticalDivider.snp.trailing).offset(AppSpacing.space16)
            make.trailing.equalToSuperview().offset(-AppSpacing.space24)
        }

        verticalDivider.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(left)
            make.width.equalTo(AppBorder.thin)
            make.height.equalTo(40)
        }
    }

    private func setupView() {
        backgroundColor = .clear
    }

    private static func makeDivider() -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.12)
        return view
    }
}

// MARK: - 정답 / 오답 개수 항목
private final class CountItem: UIView {

    private let dot: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 4
        return view
    }()

    private let captionLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.footnote
        label.textColor = AppColor.textSecondary
        return label
    }()

    private let countLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.title2
        label.textColor = AppColor.textPrimary
        label.textAlignment = .center
        return label
    }()

    private lazy var captionStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [dot, captionLabel])
        stack.axis = .horizontal
        stack.spacing = AppSpacing.space4
        stack.alignment = .center
        return stack
    }()

    var countText: String? {
        get { countLabel.text }
        set { countLabel.text = newValue }
    }

    init(caption: String, dotColor: UIColor) {
        super.init(frame: .zero)
        captionLabel.text = caption
        dot.backgroundColor = dotColor
        setupHierarchy()
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupHierarchy() {
        [captionStackView, countLabel].forEach { addSubview($0) }
    }

    private func setupLayout() {
        dot.snp.makeConstraints { make in
            make.size.equalTo(8)
        }

        captionStackView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
        }

        countLabel.snp.makeConstraints { make in
            make.top.equalTo(captionStackView.snp.bottom).offset(AppSpacing.space4)
            make.horizontalEdges.bottom.equalToSuperview()
        }
    }
}
