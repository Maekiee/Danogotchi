import RxCocoa
import RxSwift
import SnapKit
import UIKit


protocol EggSelectionViewControllerDelegate: AnyObject {
    func eggSelectionDidFinish(type: PetType)
}

final class EggSelectionViewController: BaseViewController {

    weak var delegate: EggSelectionViewControllerDelegate?

    private let disposeBag = DisposeBag()
    private let viewModel: EggSelectionViewModel
    private let itemSelected = PublishRelay<EggItem>()

    private enum Section {
        case main
    }

    private typealias DataSource = UICollectionViewDiffableDataSource<Section, EggItem>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, EggItem>

    private var dataSource: DataSource!

    // MARK: - UI 프로퍼티
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "함께할 알을 골라주세요"
        label.font = AppFont.font(.semibold, size: 28)
        label.textColor = AppColor.textPrimary
        return label
    }()
    private lazy var collectionView: UICollectionView = {
        let view = UICollectionView(
            frame: .zero,
            collectionViewLayout: EggSelectionViewController.layout()
        )
        view.alwaysBounceVertical = false
        view.showsVerticalScrollIndicator = false
        view.backgroundColor = AppColor.background
        return view
    }()
    private let nextButton = PrimaryFillButton(title: "다음")

    init(viewModel: EggSelectionViewModel) {
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
            collectionView,
            nextButton,
        ].forEach { view.addSubview($0) }
    }

    override func configLayout() {
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(AppSpacing.space32)
            make.horizontalEdges.equalToSuperview().inset(AppSpacing.space20)
        }

        collectionView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(AppSpacing.space24)
            make.horizontalEdges.equalToSuperview().inset(AppSpacing.space20)
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

extension EggSelectionViewController {
    private func bind() {
        let input = EggSelectionViewModel.Input(
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
                owner.delegate?.eggSelectionDidFinish(type: type)
            }.disposed(by: disposeBag)

        // 준비중 슬롯 무시는 ViewModel이 처리한다
        collectionView.rx.itemSelected
            .compactMap { [weak self] indexPath in
                self?.dataSource.itemIdentifier(for: indexPath)
            }
            .bind(to: itemSelected)
            .disposed(by: disposeBag)
    }
}

// MARK: - CollectionView
extension EggSelectionViewController {
    private func configDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<
            EggCollectionViewCell, EggItem
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

    private func applySnapshot(items: [EggItem]) {
        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems(items, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    private static func layout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { _, environment in
            let spacing = AppSpacing.space12

            let width = environment.container.effectiveContentSize.width
            let side = floor((width - spacing * 2) / 3)

            let item = NSCollectionLayoutItem(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .absolute(side),
                    heightDimension: .absolute(side)
                )
            )

            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .absolute(side)
                ),
                subitems: [item, item, item]
            )
            group.interItemSpacing = .fixed(spacing)

            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = spacing

            return section
        }
    }
}
