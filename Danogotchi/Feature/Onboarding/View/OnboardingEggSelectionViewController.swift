import RxCocoa
import RxSwift
import SnapKit
import UIKit


protocol OnboardingEggSelectionViewControllerDelegate: AnyObject {
    func onboardingEggSelectionDidFinish(type: PetType)
}

final class OnboardingEggSelectionViewController: BaseViewController {

    weak var delegate: OnboardingEggSelectionViewControllerDelegate?

    private let disposeBag = DisposeBag()
    private let viewModel: OnboardingEggSelectionViewModel
    private let itemSelected = PublishRelay<OnboardingEggItem>()

    private enum Section {
        case main
    }

    private typealias DataSource = UICollectionViewDiffableDataSource<Section, OnboardingEggItem>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, OnboardingEggItem>

    private var dataSource: DataSource!

    // MARK: - UI 프로퍼티
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "함께할 알을 골라주세요"
        label.font = AppFont.font(.semibold, size: 28)
        label.textColor = AppColor.textPrimary
        return label
    }()
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "지금은 첫 번째 알만 만날 수 있어요."
        label.font = AppFont.footnote
        label.textColor = AppColor.textSecondary
        label.numberOfLines = 0
        return label
    }()
    private lazy var collectionView: UICollectionView = {
        let view = UICollectionView(
            frame: .zero,
            collectionViewLayout: OnboardingEggSelectionViewController.layout()
        )
        view.alwaysBounceVertical = false
        view.showsVerticalScrollIndicator = false
        view.backgroundColor = AppColor.background
        return view
    }()
    private let nextButton = PrimaryFillButton(title: "다음")

    init(viewModel: OnboardingEggSelectionViewModel) {
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

extension OnboardingEggSelectionViewController {
    private func bind() {
        let input = OnboardingEggSelectionViewModel.Input(
            itemSelected: itemSelected.asObservable(),
            nextTapped: nextButton.rx.tap.asObservable()
        )

        let output = viewModel.transform(input: input)

        output.eggItems
            .drive(with: self) { owner, items in
                owner.applySnapshot(items: items)
            }.disposed(by: disposeBag)

        output.isNextEnabled
            .drive(nextButton.rx.isEnabled)
            .disposed(by: disposeBag)

        output.didSelectEgg
            .emit(with: self) { owner, type in
                owner.delegate?.onboardingEggSelectionDidFinish(type: type)
            }.disposed(by: disposeBag)

        // 개발중 슬롯 무시는 ViewModel이 처리한다
        collectionView.rx.itemSelected
            .compactMap { [weak self] indexPath in
                self?.dataSource.itemIdentifier(for: indexPath)
            }
            .bind(to: itemSelected)
            .disposed(by: disposeBag)
    }
}

// MARK: - CollectionView
extension OnboardingEggSelectionViewController {
    private func configDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<
            OnboardingEggCollectionViewCell, OnboardingEggItem
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

    private func applySnapshot(items: [OnboardingEggItem]) {
        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems(items, toSection: .main)
        // 선택이 바뀌면 diffable이 삭제+삽입으로 처리한다 — 알이 튀지 않도록 애니메이션은 끈다
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    private static func layout() -> UICollectionViewLayout {
        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .fractionalHeight(1)
            )
        )

        // count: 3이 여백을 뺀 나머지를 3등분하고, 높이는 컨테이너 너비 기준으로 잡아 정사각형에 가깝게 만든다
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .fractionalWidth(1.0 / 3)
            ),
            repeatingSubitem: item,
            count: 3
        )
        group.interItemSpacing = .fixed(AppSpacing.space12)

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
