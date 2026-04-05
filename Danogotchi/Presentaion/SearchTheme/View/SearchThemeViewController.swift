import RxCocoa
import RxSwift
import SnapKit
import UIKit

final class SearchThemeViewController: BaseViewController {
    
    enum EntryMode {
        case onboarding
        case settings
    }
    
    private let entryMode: EntryMode
    private let disposeBag = DisposeBag()
    private let viewModel: SearchThemeViewModel
    private let selectedThemeUrl = BehaviorRelay<String?>(value: nil)
    private let wordBookRepo = WordBookRepository()
    private let userInfo = UserInfoManager.shared
    
    
    
    private enum Section {
        case main
    }
    
    private typealias DataSource = UICollectionViewDiffableDataSource<Section, ThemeImageViewData>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, ThemeImageViewData>
    
    private var dataSource: DataSource!
    
    private var imageDataList: [ThemeImageViewData] = []
    private let waterfallLayout = WaterfallLayout()
    
    
    private let backButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "chevron.backward")
        config.title = "Back"
        config.imagePadding = 4
        config.baseForegroundColor = .black
        button.configuration = config
        return button
    }()
    private let titleText: UILabel = {
        let label = UILabel()
        label.text = "배경 테마를 골라주세요2"
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
        )
        view.showsVerticalScrollIndicator = false
        view.backgroundColor = AppColor.backgroundBeige
        return view
    }()
    private lazy var  submitButton: PrimaryFillButton = {
        let button = entryMode == .onboarding ? "시작하기" : "수정하기"
        return PrimaryFillButton(title: button)
    }()
    
    init(mode: EntryMode = .onboarding) {
        self.entryMode = mode
        self.viewModel = SearchThemeViewModel(mode: mode)
        super.init(nibName: nil, bundle: nil)
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if entryMode == .settings {
            navigationController?.setNavigationBarHidden(true, animated: animated)
        }
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
        
        if entryMode == .settings {
            navigationController?.setNavigationBarHidden(false, animated: animated)
        }
    }
    
    override func configHierarchy() {
        if entryMode == .settings {
            view.addSubview(backButton)
        }
        
        [
            titleText,
            textField,
            collectionView,
            submitButton,
        ].forEach { view.addSubview($0) }
    }
    
    override func configLayout() {
        
        if entryMode == .settings {
            backButton.snp.makeConstraints { make in
                make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
                make.leading.equalToSuperview().inset(8)
            }
        }
        
        titleText.snp.makeConstraints { make in
            if entryMode == .settings {
                make.top.equalTo(backButton.snp.bottom).offset(8)
            } else {
                make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            }
            
            make.horizontalEdges.equalToSuperview().inset(20)
        }
        
        textField.snp.makeConstraints { make in
            make.top.equalTo(titleText.snp.bottom).offset(12)
            make.horizontalEdges.equalToSuperview().inset(16)
            make.height.equalTo(48)
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
        view.backgroundColor = AppColor.backgroundBeige
//        navigationController?.navigationBar.tintColor = .black
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
                owner.imageDataList = imageList
                owner.waterfallLayout.invalidateLayout()
                
                owner.applySnapshot(items: imageList)
            }.disposed(by: disposeBag)
        
        if entryMode == .settings {
            backButton.rx.tap
                .bind(with: self) { owner, _ in
                    owner.navigationController?.popViewController(animated: true)
                }.disposed(by: disposeBag)
        }
        
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
        
        submitButton.rx.tap
            .bind(with: self) { owner, _ in
                guard let selectedTheme = owner.selectedThemeUrl.value else { return }
                
                switch owner.entryMode {
                case .onboarding:
                    owner.handleOnboardingSubmit(selectedTheme: selectedTheme)
                case .settings:
                    owner.handleSettingsSubmit(selectedTheme: selectedTheme)
                }
                
            }.disposed(by: disposeBag)
    }
    
    private func handleOnboardingSubmit(selectedTheme: String) {
        
        UserInfoManager.shared.currentThemeUrl = selectedTheme
        
        let existingBooks = wordBookRepo.readAll()
        
        if let existingBooks = existingBooks.first {
            userInfo.selectedBookId = existingBooks.id
            Coordinator.switchToMainVieWController()
        } else {
            // 새로 생성
            wordBookRepo.create(title: "나의 단어장")
            
            if let newBook = wordBookRepo.readAll().last {
                userInfo.selectedBookId = newBook.id
                Coordinator.switchToMainVieWController()
            } else {
                // 사용자에게 에러 알림
            }
        }
    }
    
    /// 설정 화면에서 수정하기 버튼 탭 (새로운 로직)
    private func handleSettingsSubmit(selectedTheme: String) {
        // 테마만 변경
        UserInfoManager.shared.currentThemeUrl = selectedTheme
        
        // 설정 화면으로 돌아가기
        navigationController?.popViewController(animated: true)
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
