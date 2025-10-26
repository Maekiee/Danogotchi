import RxCocoa
import RxSwift
import SnapKit
import UIKit

final class SearchThemeViewController: BaseViewController {
    private let disposeBag = DisposeBag()
    private let viewModel = SearchThemeViewModel()
    
    private enum Section {
        case main
    }
    
    private typealias DataSource = UICollectionViewDiffableDataSource<Section, ThemeImageViewData>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, ThemeImageViewData>
    
    private var dataSource: DataSource!
    
    // 추가 ----------------------------------
    private var imageDataList: [ThemeImageViewData] = []
    private let waterfallLayout = WaterfallLayout()
    // ------------------------------------

    private let titleText: UILabel = {
        let label = UILabel()
        label.text = "배경 테마를 골라주세요"
        label.font = .systemFont(ofSize: 28, weight: .semibold)
        label.textColor = .black
        return label
    }()

    private let textField: UnderlineTextField = {
        let tf = UnderlineTextField()
        tf.placeholder = "이미지를 검색해주세요"
        tf.font = .systemFont(ofSize: 16, weight: .regular)
        tf.isUserInteractionEnabled = true
        return tf
    }()
    
    private lazy var collectionView: UICollectionView = {
        // 추가
        waterfallLayout.delegate = self
        
        let view = UICollectionView(
            frame: .zero,
            collectionViewLayout: waterfallLayout // 추가
//            collectionViewLayout: SearchThemeViewController.layout()
        )
        view.showsVerticalScrollIndicator = false
        view.backgroundColor = AppColor.appBackgroundColor
        return view
    }()
    
    private let submitButton = PrimaryFillButton(title: "시작하기")

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
            titleText,
            textField,
            collectionView,
            submitButton,
        ].forEach { view.addSubview($0) }
    }

    override func configLayout() {
        titleText.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.horizontalEdges.equalToSuperview().inset(20)
        }

        textField.snp.makeConstraints { make in
            make.top.equalTo(titleText.snp.bottom).offset(12)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(40)
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(textField.snp.bottom).offset(4)
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        submitButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(44)
        }

    }

    override func configView() {

    }

}

extension SearchThemeViewController {
    private func bind() {
        let loadNextPage = PublishRelay<Void>()
        
        let input = SearchThemeViewModel.Input(
            viewWillAppear: rx.methodInvoked(#selector(viewWillAppear)).map {
                _ in
            },
            searchText: textField.tf.rx.text.orEmpty.asObservable(),
            loadNextPage: loadNextPage.asObservable(),
            textEndTrigger: textField.tf.rx.controlEvent(.editingDidEndOnExit).asObservable()
        )
        let output = viewModel.transform(input: input)
        
        output.themeImageList
            .drive(with: self) { owner, imageList in
                // 추가된 부분 --------------
                owner.imageDataList = imageList
                owner.waterfallLayout.invalidateLayout()
                // ----------------------
                
                owner.applySnapshot(items: imageList)
            }.disposed(by: disposeBag)
        
        collectionView.rx.contentOffset
            .map { [weak self] offset in
                guard let self = self else { return false }
                let contentHeight = collectionView.contentSize.height
                let scrollViewHeight = collectionView.frame.height
                let offsetY = offset.y
                return offsetY > contentHeight - scrollViewHeight - 100
            }.distinctUntilChanged()
            .filter { $0 }
            .map { _ in () }
            .bind(to: loadNextPage)
            .disposed(by: disposeBag)
    }
}


// MARK: - WaterfallLayoutDelegate
extension SearchThemeViewController: WaterfallLayoutDelegate {
    func collectionView(_ collectionView: UICollectionView, heightForItemAt indexPath: IndexPath, width: CGFloat) -> CGFloat {
        guard indexPath.item < imageDataList.count else { return 200 }
        let item = imageDataList[indexPath.item]
        return width * item.aspectRatio
    }
}


//MARK: - 컬렉션 뷰
extension SearchThemeViewController {
    private func configDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<ThemeImageCollectionViewCell, ThemeImageViewData> {
            cell, indexPath, item in
            cell.configBind(with: item)
        }
        
        dataSource = DataSource(collectionView: collectionView) {
            collectionView,
            indexPath,
            itemIdentifier in
            return collectionView.dequeueConfiguredReusableCell(
                using: cellRegistration,
                for: indexPath,
                item: itemIdentifier)
        }
    }
    
    private func applySnapshot(items: [ThemeImageViewData]) {
        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems(items)
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    
//    private static func layout() -> UICollectionViewLayout {
//        // 2열 그리드 with estimated height
//        let itemSize = NSCollectionLayoutSize(
//            widthDimension: .fractionalWidth(0.5),
//            heightDimension: .estimated(200)
//        )
//        let item = NSCollectionLayoutItem(layoutSize: itemSize)
//        
//        let groupSize = NSCollectionLayoutSize(
//            widthDimension: .fractionalWidth(1.0),
//            heightDimension: .estimated(200)
//        )
//        let group = NSCollectionLayoutGroup.horizontal(
//            layoutSize: groupSize,
//            repeatingSubitem: item,
//            count: 2
//        )
//        group.interItemSpacing = .fixed(8)
//        
//        let section = NSCollectionLayoutSection(group: group)
//        section.interGroupSpacing = 8
//        section.contentInsets = NSDirectionalEdgeInsets(
//            top: 12,
//            leading: 16,
//            bottom: 80,
//            trailing: 16
//        )
//        
//        let layout = UICollectionViewCompositionalLayout(section: section)
//        return layout
//    }
//    
}
