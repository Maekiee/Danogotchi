import RxCocoa
import RxSwift
import SnapKit
import UIKit

final class SearchThemeViewController: BaseViewController {
    private let disposeBag = DisposeBag()
    private let viewModel = SearchThemeViewModel()
    private let selectedThemeUrl = BehaviorRelay<String?>(value: nil)
    private let wordBookRepo = WordBookRepository()
    private let userInfo = UserInfoManager.shared
    
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
            textEndTrigger: textField.tf.rx.controlEvent(.editingDidEndOnExit).asObservable(),
            selectedTheme: selectedThemeUrl.asObservable(),
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
        
        // 스크롤 하단 체크
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
        
        collectionView.rx.itemSelected
            .bind(with: self) { owner, indexPath in
                guard let selectedItem = owner.dataSource.itemIdentifier(for: indexPath) else {
                    return
                }
                
                let newUrl = (owner.selectedThemeUrl.value == selectedItem.themeImageUrl) ? nil : selectedItem.themeImageUrl
                owner.selectedThemeUrl.accept(newUrl)
            }.disposed(by: disposeBag)
        
        
        selectedThemeUrl
            .distinctUntilChanged()
            .bind(with: self) { owner, _ in
                var currentSnapshot = owner.dataSource.snapshot()
                let allItems = currentSnapshot.itemIdentifiers
                currentSnapshot.reconfigureItems(allItems)
                owner.dataSource.apply(currentSnapshot, animatingDifferences: false)
            }.disposed(by: disposeBag)
        
        output.buttonEnable
            .drive(submitButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
        submitButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.wordBookRepo.create(title: "나의 단어장")
                guard let myBook = owner.wordBookRepo.readAll().last else { return }
                
                // 배경 사진이 유저디폴트에 저장되었는지 확인
                if let selectedTheme = owner.selectedThemeUrl.value {
                    UserInfoManager.shared.currentThemeUrl = selectedTheme
                    // 생성된 단어장 유저 인포에 넣기
                    if owner.userInfo.selectedBookId == nil {
                        owner.userInfo.selectedBookId = myBook.id
                        Coordinator.switchToMainVieWController()
                    }
                }
            }.disposed(by: disposeBag)
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
            [weak self] cell, indexPath, item in
            guard let self = self else { return }
            cell.configBind(with: item, isSelected: item.themeImageUrl == selectedThemeUrl.value)
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
}
