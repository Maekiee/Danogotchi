import UIKit
import SnapKit
import RxSwift
import RxCocoa

protocol CharacterViewControllerDelegate: AnyObject {
    func characterDidTapClose()
}

final class CharacterViewController: BaseViewController {

    private let disposeBag = DisposeBag()
    private let viewModel: CharacterViewModel
    weak var delegate: CharacterViewControllerDelegate?

    /// 부활은 확인 알럿을 거친 뒤에만 ViewModel로 보낸다
    private let reviveConfirmed = PublishRelay<Void>()

    // MARK: - UI 프로퍼티
    private let scrollView: UIScrollView = {
        let view = UIScrollView()
        view.showsVerticalScrollIndicator = false
        return view
    }()
    private let contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = AppSpacing.space20
        stack.alignment = .fill
        return stack
    }()
    private let petImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.tintColor = AppColor.textSecondary
        return view
    }()
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.title1
        label.textColor = AppColor.textPrimary
        label.textAlignment = .center
        return label
    }()
    private let moodLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.headline
        label.textColor = AppColor.textSecondary
        label.textAlignment = .center
        return label
    }()
    private let heartBarView = HeartBarView()
    private let levelLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.bodyEmphasis
        label.textColor = AppColor.textPrimary
        return label
    }()
    private let experiencePercentLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.footnote
        label.textColor = AppColor.textSecondary
        label.textAlignment = .right
        return label
    }()
    private let experienceGaugeView = CustomProgressView()
    private lazy var careRowViews = PetCareStat.allCases.map { CareStatRowView(stat: $0) }
    private let dangerLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.footnote
        label.textColor = AppColor.error
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    /// 네 개를 한 줄에 놓으면 좁은 기기에서 "놀아주기"가 잘린다 — 2×2로 세운다
    private lazy var careButtons = PetCareStat.allCases.map { stat in
        (stat: stat, button: PrimaryFillButton(title: stat.actionTitle))
    }
    private let levelUpButton = PrimaryFillButton(title: "레벨업")
    private let reviveButton = PrimaryFillButton(title: "부활")

    init(viewModel: CharacterViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @MainActor
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configHierarchy()
        configLayout()
        configView()

        bind()
    }

    override func configHierarchy() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentStackView)

        [
            petImageView,
            nameLabel,
            moodLabel,
            heartBarView,
            makeExperienceSection(),
            makeCareSection(),
            dangerLabel,
            makeCareButtonGrid(),
            levelUpButton,
            reviveButton,
        ].forEach { contentStackView.addArrangedSubview($0) }
    }

    override func configLayout() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentStackView.snp.makeConstraints { make in
            make.verticalEdges.equalToSuperview().inset(AppSpacing.space20)
            make.horizontalEdges.equalToSuperview().inset(AppSpacing.space20)
            make.width.equalToSuperview().offset(-AppSpacing.space20 * 2)
        }

        petImageView.snp.makeConstraints { make in
            make.height.equalTo(160)
        }

        [levelUpButton, reviveButton].forEach { button in
            button.snp.makeConstraints { make in
                make.height.equalTo(48)
            }
        }
    }

    override func configView() {
        // 펫 에셋이 아직 없다 — 들어오면 `PetType.imageName` 하나만 바뀐다
        petImageView.image = UIImage(named: PetType.sprout.imageName)
            ?? UIImage(systemName: "pawprint")

        heartBarView.isAccessibilityElement = true
        heartBarView.accessibilityLabel = "체력"

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark"), style: .plain, target: nil, action: nil
        )
    }
}

// MARK: - 섹션 조립
extension CharacterViewController {
    private func makeExperienceSection() -> UIView {
        let container = UIView()

        // 현재/필요 EXP 절대 수치는 노출하지 않는다 — 진행률만 퍼센트로 알린다
        let headerStack = UIStackView(arrangedSubviews: [levelLabel, experiencePercentLabel])
        headerStack.axis = .horizontal

        [headerStack, experienceGaugeView].forEach { container.addSubview($0) }

        headerStack.snp.makeConstraints { make in
            make.top.horizontalEdges.equalToSuperview()
        }

        experienceGaugeView.snp.makeConstraints { make in
            make.top.equalTo(headerStack.snp.bottom).offset(AppSpacing.space8)
            make.horizontalEdges.bottom.equalToSuperview()
            make.height.equalTo(12)
        }

        container.isAccessibilityElement = true
        container.accessibilityLabel = "경험치"
        return container
    }

    private func makeCareSection() -> UIView {
        let stack = UIStackView(arrangedSubviews: careRowViews)
        stack.axis = .vertical
        stack.spacing = AppSpacing.space12
        return stack
    }

    private func makeCareButtonGrid() -> UIView {
        let buttons = careButtons.map { $0.button }
        let rows = stride(from: 0, to: buttons.count, by: 2).map { index -> UIStackView in
            let row = UIStackView(arrangedSubviews: Array(buttons[index..<min(index + 2, buttons.count)]))
            row.axis = .horizontal
            row.spacing = AppSpacing.space12
            row.distribution = .fillEqually
            return row
        }

        let grid = UIStackView(arrangedSubviews: rows)
        grid.axis = .vertical
        grid.spacing = AppSpacing.space12

        buttons.forEach { button in
            button.snp.makeConstraints { make in
                make.height.equalTo(48)
            }
        }
        return grid
    }
}

// MARK: - Bind
extension CharacterViewController {
    private func bind() {
        let careTapped = Observable.merge(
            careButtons.map { pair in
                pair.button.rx.tap.map { pair.stat }
            }
        )

        let input = CharacterViewModel.Input(
            viewWillAppear: rx.methodInvoked(#selector(viewWillAppear)).map { _ in },
            didBecomeActive: NotificationCenter.default.rx
                .notification(UIApplication.didBecomeActiveNotification)
                .map { _ in },
            careTapped: careTapped,
            levelUpTapped: levelUpButton.rx.tap.asObservable(),
            reviveTapped: reviveConfirmed.asObservable()
        )

        let output = viewModel.transform(input: input)

        output.info
            .drive(with: self) { owner, info in
                owner.render(info)
            }.disposed(by: disposeBag)

        output.toastMessage
            .emit(with: self) { owner, message in
                owner.showToast(message)
            }.disposed(by: disposeBag)

        // 되돌릴 수 없는 경험치 차감이라 확인을 받는다
        reviveButton.rx.tap
            .bind(with: self) { owner, _ in
                AlertPresenter.showAlert(
                    on: owner,
                    title: "부활",
                    message: "경험치가 일부 차감돼요. 부활할까요?"
                ) {
                    owner.reviveConfirmed.accept(())
                }
            }.disposed(by: disposeBag)

        navigationItem.leftBarButtonItem?.rx.tap
            .bind(with: self) { owner, _ in
                owner.delegate?.characterDidTapClose()
            }.disposed(by: disposeBag)
    }

    /// 한 번의 정산 결과를 화면 전체에 반영한다
    private func render(_ info: PetDisplayInfo) {
        let pet = info.pet

        nameLabel.text = pet.name
        // 기분은 사망 상태에서도 계산되므로 갈아치우는 건 화면 몫이다
        moodLabel.text = pet.isDead ? "세상을 떠났어요" : info.mood.title

        heartBarView.setHearts(info.hearts)
        heartBarView.accessibilityValue =
            "\(Int(PetStatePolicy.maxHP)) 중 \(Int(pet.hp))"

        levelLabel.text = "Lv. \(pet.level)"
        // 버림이다 — 반올림하면 99.6%가 `100%`로 떠서 레벨업 버튼은 비활성인데 다 찬 것처럼 읽힌다.
        // `progress == 1`(승급 가능)에서만 정확히 `100%`가 된다.
        // (`CareStatRowView`는 정반대로 반올림한다. 거기선 99.96을 99로 쓰면 돌보기가 안 먹은 것처럼 보인다.)
        experiencePercentLabel.text = "\(Int(info.progress * 100))%"
        experienceGaugeView.setProgress(Float(info.progress), animated: true)
        // 게이지만 남으므로 VoiceOver에는 퍼센트로 읽어준다
        experienceGaugeView.superview?.accessibilityValue = info.isMaxLevel
            ? "레벨 \(pet.level), 최고 레벨"
            : "레벨 \(pet.level), \(Int(info.progress * 100))퍼센트"

        zip(careRowViews, PetCareStat.allCases).forEach { row, stat in
            row.update(value: pet[keyPath: stat.keyPath])
        }

        renderDanger(pet)

        // 수치가 넉넉하면 돌보기를 막는다 — 기준은 정책이 갖는다
        careButtons.forEach { pair in
            pair.button.isEnabled = !pet.isDead
                && pet[keyPath: pair.stat.keyPath] < PetStatePolicy.careThreshold
        }
        levelUpButton.isHidden = info.isMaxLevel
        levelUpButton.isEnabled = info.canLevelUp && !pet.isDead
        reviveButton.isHidden = !pet.isDead
    }

    /// 기분만으로는 사망이 임박한 걸 알 수 없다 — 어떤 수치가 HP를 깎고 있는지 문구로 알린다
    private func renderDanger(_ pet: Pet) {
        let dangerStats = PetCareStat.allCases
            .filter { pet[keyPath: $0.keyPath] <= PetStatePolicy.dangerThreshold }

        dangerLabel.isHidden = dangerStats.isEmpty
        guard !dangerStats.isEmpty else { return }

        let names = dangerStats.map { $0.title }.joined(separator: "·")
        dangerLabel.text = "\(names)이(가) 위험해요. 체력이 줄고 있어요."
    }
}
