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
    private let petSpriteView = PetSpriteView()
    private let weatherSpriteView = WeatherSpriteView()
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
    private lazy var careButtons = PetCareStat.allCases.map { stat in
        (stat: stat, button: PrimaryFillButton(title: stat.actionTitle))
    }
    private let levelUpButton = PrimaryFillButton(title: "레벨업")
    private let reviveButton = PrimaryFillButton(title: "부활")
    private let debugLevelDownButton = PrimaryFillButton(title: "Lv -1")
    private let debugLevelUpButton = PrimaryFillButton(title: "Lv +1")
    private let debugLevelSpacer = UIView()

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
        view.addSubview(weatherSpriteView)
        scrollView.addSubview(contentStackView)

        [
            petSpriteView,
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

        #if DEBUG
        contentStackView.addArrangedSubview(debugLevelSpacer)
        contentStackView.addArrangedSubview(makeDebugLevelRow())
        #endif
    }

    override func configLayout() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        // 스크롤과 무관하게 화면 우측 상단에 머문다
        weatherSpriteView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(AppSpacing.space20)
            make.trailing.equalTo(view.safeAreaLayoutGuide).inset(AppSpacing.space20)
            make.size.equalTo(64)
        }

        // 남는 세로 공간을 전부 흡수한다. 콘텐츠가 화면보다 길면 이 최소값으로 돌아온다.
        petSpriteView.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(160)
        }

        contentStackView.snp.makeConstraints { make in
            make.verticalEdges.equalToSuperview().inset(AppSpacing.space20)
            make.horizontalEdges.equalToSuperview().inset(AppSpacing.space20)
            make.width.equalToSuperview().offset(-AppSpacing.space20 * 2)
            make.height.greaterThanOrEqualTo(scrollView.frameLayoutGuide.snp.height)
                .offset(-AppSpacing.space20 * 2)
        }

        [levelUpButton, reviveButton].forEach { button in
            button.snp.makeConstraints { make in
                make.height.equalTo(48)
            }
        }

        #if DEBUG
        // 화면 높이에 비례 — 기기가 커져 아래 여백이 늘어도 첫 화면에는 안 걸린다
        debugLevelSpacer.snp.makeConstraints { make in
            make.height.equalTo(scrollView.frameLayoutGuide.snp.height).multipliedBy(0.3)
        }
        #endif
    }

    override func configView() {
        heartBarView.isAccessibilityElement = true
        heartBarView.accessibilityLabel = "체력"

        // 날씨를 받기 전에는 빈 칸을 보이지 않는다
        weatherSpriteView.isHidden = true

        // 스택의 남는 공간을 가져갈 뷰를 명시한다 — 기본값(250)끼리 겹치면 어디가 늘어날지 불확실하다
        petSpriteView.setContentHuggingPriority(.init(1), for: .vertical)

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark"), style: .plain, target: nil, action: nil
        )

//        #if DEBUG
//        // 임시 — 캐릭터 영역이 실제로 차지하는 박스 확인용. 날씨 배경 배치를 정하면 지운다.
//        petSpriteView.layer.borderWidth = 0.5
//        petSpriteView.layer.borderColor = UIColor.red.cgColor
//        #endif
    }
}

// MARK: - 섹션 조립
extension CharacterViewController {
    private func makeExperienceSection() -> UIView {
        let container = UIView()
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

    private func makeDebugLevelRow() -> UIView {
        let row = UIStackView(arrangedSubviews: [debugLevelDownButton, debugLevelUpButton])
        row.axis = .horizontal
        row.spacing = AppSpacing.space12
        row.distribution = .fillEqually

        [debugLevelDownButton, debugLevelUpButton].forEach { button in
            button.snp.makeConstraints { make in
                make.height.equalTo(48)
            }
        }
        return row
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
            levelDeltaTapped: Observable.merge(
                debugLevelDownButton.rx.tap.map { -1 },
                debugLevelUpButton.rx.tap.map { 1 }
            ),
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

        output.weatherType
            .drive(with: self) { owner, type in
                owner.weatherSpriteView.isHidden = false
                owner.weatherSpriteView.render(type)
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

        
        petSpriteView.render(
            sheetName: pet.type.sheetName(level: pet.level),
            clip: PetSpriteClip(mood: info.mood, isDead: pet.isDead)
        )

        nameLabel.text = pet.name
        moodLabel.text = pet.isDead ? "세상을 떠났어요" : info.mood.title

        heartBarView.setHearts(info.hearts)
        heartBarView.accessibilityValue =
            "\(Int(PetStatePolicy.maxHP)) 중 \(Int(pet.hp))"

        levelLabel.text = "Lv. \(pet.level)"
        experiencePercentLabel.text = "\(Int(info.progress * 100))%"
        experienceGaugeView.setProgress(Float(info.progress), animated: true)
        experienceGaugeView.superview?.accessibilityValue = info.isMaxLevel
            ? "레벨 \(pet.level), 최고 레벨"
            : "레벨 \(pet.level), \(Int(info.progress * 100))퍼센트"

        zip(careRowViews, PetCareStat.allCases).forEach { row, stat in
            row.update(value: pet[keyPath: stat.keyPath])
        }

        renderDanger(pet)
        
        careButtons.forEach { pair in
            pair.button.isEnabled = !pet.isDead
                && pet[keyPath: pair.stat.keyPath] < PetStatePolicy.careThreshold
        }
        levelUpButton.isHidden = info.isMaxLevel
        levelUpButton.isEnabled = info.canLevelUp && !pet.isDead
        reviveButton.isHidden = !pet.isDead
    }

    private func renderDanger(_ pet: Pet) {
        let dangerStats = PetCareStat.allCases
            .filter { pet[keyPath: $0.keyPath] <= PetStatePolicy.dangerThreshold }

        dangerLabel.isHidden = dangerStats.isEmpty
        guard !dangerStats.isEmpty else { return }

        let names = dangerStats.map { $0.title }.joined(separator: "·")
        dangerLabel.text = "\(names)이(가) 위험해요. 체력이 줄고 있어요."
    }
}
