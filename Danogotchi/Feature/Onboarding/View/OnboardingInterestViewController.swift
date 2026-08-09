import RxCocoa
import RxSwift
import SnapKit
import UIKit


protocol OnboardingInterestViewControllerDelegate: AnyObject {
    func onboardingInterestDidFinish()
}

final class OnboardingInterestViewController: BaseViewController {

    weak var delegate: OnboardingInterestViewControllerDelegate?

    private let disposeBag = DisposeBag()
    private let viewModel: OnboardingInterestViewModel
    private let topicSelected = PublishRelay<BookTopic>()

    private enum Section {
        case main
    }

    private typealias DataSource = UICollectionViewDiffableDataSource<Section, OnboardingInterestItem>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, OnboardingInterestItem>

    private var dataSource: DataSource!

    // MARK: - UI 프로퍼티
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "관심 있는 주제를 골라주세요"
        label.font = AppFont.font(.semibold, size: 28)
        label.textColor = AppColor.textPrimary
        return label
    }()
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "선택한 주제로 학습을 시작해요. 나중에 언제든 바꿀 수 있어요."
        label.font = AppFont.footnote
        label.textColor = AppColor.textSecondary
        label.numberOfLines = 0
        return label
    }()
    private lazy var collectionView: UICollectionView = {
        let view = UICollectionView(
            frame: .zero,
            collectionViewLayout: OnboardingInterestViewController.layout()
        )
        view.alwaysBounceVertical = false
        view.showsVerticalScrollIndicator = false
        view.backgroundColor = AppColor.background
        return view
    }()
    private let nextButton = PrimaryFillButton(title: "다음")

    init(viewModel: OnboardingInterestViewModel) {
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
        configDataSource()
        bind()
    }

    override func configHierarchy() {
        [
            titleLabel,
            descriptionLabel,
            collectionView,
            nextButton,
        ].forEach { view.addSubview($0) }
    }

    override func configLayout() {
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(AppSpacing.space32)
            make.horizontalEdges.equalToSuperview().inset(AppSpacing.space20)
        }

        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(AppSpacing.space8)
            make.horizontalEdges.equalToSuperview().inset(AppSpacing.space20)
        }

        collectionView.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(AppSpacing.space24)
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalTo(nextButton.snp.top).offset(-AppSpacing.space16)
        }

        nextButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-AppSpacing.space20)
            make.horizontalEdges.equalToSuperview().inset(AppSpacing.space20)
            make.height.equalTo(48)
        }
    }

    override func configView() {
        nextButton.isEnabled = false
    }
}

extension OnboardingInterestViewController {
    private func bind() {
        let input = OnboardingInterestViewModel.Input(
            topicSelected: topicSelected.asObservable(),
            nextTapped: nextButton.rx.tap.asObservable()
        )

        let output = viewModel.transform(input: input)

        output.interestItems
            .drive(with: self) { owner, items in
                owner.applySnapshot(items: items)
            }.disposed(by: disposeBag)

        output.isNextEnabled
            .drive(nextButton.rx.isEnabled)
            .disposed(by: disposeBag)

        output.didFinish
            .emit(with: self) { owner, _ in
                owner.delegate?.onboardingInterestDidFinish()
            }.disposed(by: disposeBag)

        collectionView.rx.itemSelected
            .compactMap { [weak self] indexPath in
                self?.dataSource.itemIdentifier(for: indexPath)?.topic
            }
            .bind(to: topicSelected)
            .disposed(by: disposeBag)
    }
}

// MARK: - CollectionView
extension OnboardingInterestViewController {
    private func configDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<
            OnboardingInterestCollectionViewCell, OnboardingInterestItem
        > { cell, _, item in
            cell.binding(with: item)
        }

        dataSource = DataSource(collectionView: collectionView) {
            collectionView,
            indexPath,
            itemIdentifier in
            return collectionView.dequeueConfiguredReusableCell(
                using: cellRegistration,
                for: indexPath,
                item: itemIdentifier
            )
        }
    }

    private func applySnapshot(items: [OnboardingInterestItem]) {
        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems(items, toSection: .main)
        // 선택이 바뀌면 diffable이 삭제+삽입으로 처리한다 — 카드가 튀지 않도록 애니메이션은 끈다
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    private static func layout() -> UICollectionViewLayout {
        let capsuleHeight: CGFloat = 36

        // 너비를 estimated로 두면 그룹이 한 줄을 채울 때까지 캡슐을 반복하고, 넘치면 다음 줄로 넘어간다
        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .estimated(100),
                heightDimension: .absolute(capsuleHeight)
            )
        )

        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(capsuleHeight)
            ),
            subitems: [item]
        )
        group.interItemSpacing = .fixed(AppSpacing.space8)

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = AppSpacing.space12
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 0,
            leading: AppSpacing.space20,
            bottom: 0,
            trailing: AppSpacing.space20
        )

        return UICollectionViewCompositionalLayout(section: section)
    }
}
