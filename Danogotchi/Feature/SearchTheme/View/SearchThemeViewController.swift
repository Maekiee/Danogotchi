import RxCocoa
import RxSwift
import SnapKit
import UIKit


protocol SearchThemeViewControllerDelegate: AnyObject {
    func didSelectTheme()
}

final class SearchThemeViewController: BaseViewController {
    
    weak var delegate: SearchThemeViewControllerDelegate?
    
    private let entryMode: SearchThemeEntryMode
    private let disposeBag = DisposeBag()
    private let viewModel: SearchThemeViewModel
    private let selectedThemeUrl = BehaviorRelay<String?>(value: nil)

    private enum Section {
        case main
    }
    
    private typealias DataSource = UICollectionViewDiffableDataSource<Section, ThemeImageViewData>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, ThemeImageViewData>
    
    private var dataSource: DataSource!
    private var imageDataList: [ThemeImageViewData] = []
    private let waterfallLayout = WaterfallLayout()
    

    private let titleText: UILabel = {
        let label = UILabel()
        label.text = "배경 테마를 골라주세요"
        label.font = AppFont.font(.semibold, size: 28)
        label.textColor = AppColor.textPrimary
        return label
    }()
    private let textField = RoundedTextField(placeholder: "이미지를 검색해주세요")
    private lazy var collectionView: UICollectionView = {
        waterfallLayout.delegate = self
        let view = UICollectionView(
            frame: .zero,
            collectionViewLayout: waterfallLayout // 추가
        )
        view.showsVerticalScrollIndicator = false
        view.backgroundColor = AppColor.background
        return view
    }()
    private lazy var  submitButton: PrimaryFillButton = {
        let button = entryMode == .onboarding ? "시작하기" : "수정하기"
        return PrimaryFillButton(title: button)
    }()
    
    init(
        mode: SearchThemeEntryMode,
        viewModel: SearchThemeViewModel
    ) {
        self.entryMode = mode
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
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
            make.top.equalTo(view.safeAreaLayoutGuide).offset(AppSpacing.space16)
            make.horizontalEdges.equalToSuperview().inset(AppSpacing.space20)
        }
        
        textField.snp.makeConstraints { make in
            make.top.equalTo(titleText.snp.bottom).offset(AppSpacing.space12)
            make.horizontalEdges.equalToSuperview().inset(AppSpacing.space16)
            make.height.equalTo(48)
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(textField.snp.bottom).offset(AppSpacing.space4)
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        submitButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-AppSpacing.space20)
            make.horizontalEdges.equalToSuperview().inset(AppSpacing.space20)
            make.height.equalTo(48)
        }
        
    }
}



extension SearchThemeViewController {
    private func bind() {
        let loadNextPage = PublishRelay<Void>()
        
        let input = SearchThemeViewModel.Input(
            viewWillAppear: rx.methodInvoked(#selector(viewWillAppear)).map {
                _ in
            },
            searchText: textField.rx.text.orEmpty.asObservable(),
            loadNextPage: loadNextPage.asObservable(),
            textEndTrigger: textField.rx.controlEvent(.editingDidEndOnExit).asObservable(),
            selectedTheme: selectedThemeUrl.asObservable(),
            submitTapped: submitButton.rx.tap.asObservable()
        )
        let output = viewModel.transform(input: input)
        
        output.themeImageList
            .drive(with: self) { owner, imageList in
                owner.imageDataList = imageList
                owner.waterfallLayout.invalidateLayout()
                owner.applySnapshot(items: imageList)
            }.disposed(by: disposeBag)
        
        output.isEmptyResult
            .drive(with: self) { owner, isEmpty in
                if isEmpty {
                    owner.collectionView.setView(title: "검색 결과가 없습니다")
                } else {
                    owner.collectionView.restore()
                }
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
            .drive(submitButton.rx.isHidden)
            .disposed(by: disposeBag)

        output.alertMessage
            .emit(with: self) { owner, message in
                AlertPresenter.showNotificationAlert(on: owner, title: "알림", message: message)
            }.disposed(by: disposeBag)

        // 저장까지 끝난 뒤 다음 화면으로 넘긴다 (온보딩/설정 분기는 Coordinator가 담당)
        output.themeSaved
            .emit(with: self) { owner, _ in
                owner.delegate?.didSelectTheme()
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
