import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class MyBookListViewController: BaseViewController {
    private let disposeBag = DisposeBag()
    private let viewModel = MyBookListViewModel()
    
    // MARK: - 컬렉션 뷰
    private enum Section {
        case main
    }
    
    private typealias DataSource = UICollectionViewDiffableDataSource<Section, WordBook>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, WordBook>
    
    private var dataSource: DataSource!
    
    // MARK: - UI 프로퍼티
    private let addBookButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.plain()
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(
                pointSize: 28,
                weight: .medium
            )
        config.image = UIImage(systemName: "plus.circle.fill")
        
        config.baseForegroundColor = UIColor.black.withAlphaComponent(0.8)
        config.cornerStyle = .capsule
        button.configuration = config
        return button
    }()
    private let collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: MyBookListViewController.layout())
        view.backgroundColor = AppColor.appBackgroundColor
        view.showsVerticalScrollIndicator = false
        return view
    }()
    private let changeButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.plain()
        config.title = "변경"
        config.baseForegroundColor = UIColor.black.withAlphaComponent(0.8)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            // 현재 폰트 사이즈는 유지하면서 굵기만 semibold로 변경합니다.
            let font = incoming.font ?? UIFont.systemFont(ofSize: 17) // 기본 폰트 정보 가져오기
            outgoing.font = UIFont.systemFont(ofSize: font.pointSize, weight: .semibold)
            return outgoing
        }
        button.configuration = config
        return button
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = .black
        return button
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "내 단어장"
        label.textColor = AppColor.textPrimaryColor
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        return label
    }()
    
    private let deleteTrigger = PublishRelay<WordBook>()
    
    let selectedBook = PublishRelay<WordBook>()
    
    private var currentSelectedBook: WordBook?
    
    private let refreshTrigger = PublishRelay<Void>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configHierarchy()
        configLayout()
        configDataSource()
        bind()
    }
    
    override func configHierarchy() {
        [
            closeButton,
            titleLabel,
            changeButton,
            collectionView,
            addBookButton
        ].forEach { view.addSubview($0) }
    }
    
    override func configLayout() {
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.centerX.equalToSuperview()
        }
        
        closeButton.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel).offset(2)
            make.leading.equalToSuperview().offset(20)
        }
        
        changeButton.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.trailing.equalToSuperview().offset(-16)
        }
        
        // collectionView의 상단 기준을 titleLabel로 변경합니다.
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        
        addBookButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            make.trailing.equalToSuperview().offset(-20)
            make.size.equalTo(40)
        }
    }
    
    
}

// MARK: - Rx 바인딩
extension MyBookListViewController {
    private func bind() {
//        let refreshTrigger = PublishRelay<Void>()
//        let selectedBook = PublishRelay<WordBookModel>()
        
        let input = MyBookListViewModel.Input(
            viewWillAppear:  rx.methodInvoked(#selector(viewWillAppear)).map { _ in },
            refreshTrigger: refreshTrigger.asObservable(),
            selectedChangeBook: selectedBook.asObservable(),
            selectedDeleteTrigger: deleteTrigger.asObservable()
        )
        let output = viewModel.transform(input: input)
        
        changeButton.rx.tap
            .withLatestFrom(selectedBook)
            .bind(with: self) { owner, book in
                UserInfoManager.shared.selectedBookId = book.id
                owner.dismiss(animated: true)
            }.disposed(by: disposeBag)
        
        output.bookList
            .drive(with: self) { owner, books in
                if let selectedId = UserInfoManager.shared.selectedBookId,
                   let initiallySelected = books.first(where: { $0.id == selectedId }) {
                    owner.currentSelectedBook = initiallySelected
                    owner.selectedBook.accept(initiallySelected)
                }
                
                owner.applySnapshot(items: books)
            }.disposed(by: disposeBag)
        
        output.deleteFaileTrigger
            .emit(with: self) { owner, _ in
                AlertUtils.showNotificationAlert(
                    on: owner,
                    title: "알림",
                    message: "단어장은 최소 1개 이상 있어야 합니다."
                )
            }.disposed(by: disposeBag)
        
        // 셀 터치
        collectionView.rx.itemSelected
            .compactMap { [weak self] indexPath -> WordBook? in
                guard let self = self else { return nil }
                return dataSource.itemIdentifier(for: indexPath)
            }
            .bind(with: self) { owner, book in
                var itemsToReload = [WordBook]()
                
                if let previousBook = owner.currentSelectedBook, previousBook.id != book.id {
                    itemsToReload.append(previousBook)
                }
                
                itemsToReload.append(book)
                owner.currentSelectedBook = book
                
                var snapshot = owner.dataSource.snapshot()
                snapshot.reconfigureItems(itemsToReload)
                owner.dataSource.apply(snapshot, animatingDifferences: false)
                
                
                owner.selectedBook.accept(book)
            }.disposed(by: disposeBag)
        
        // 단어장 추가하기
        addBookButton.rx.tap
            .bind(with: self) { owner, _ in
                let vc = CreateBookViewController()
                vc.modalPresentationStyle = .overFullScreen
                vc.modalTransitionStyle = .crossDissolve
                
                vc.bookCreated
                    .bind(to: owner.refreshTrigger)
                    .disposed(by: vc.disposeBag)
                owner.present(vc, animated: true)
                
            }.disposed(by: disposeBag)
        
    }
}

// MARK: - 컬렉션 뷰
extension MyBookListViewController {
    private func configDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<WordCardCollectionViewCell, WordBook> { [weak self]
            cell, indexPath, item in
            guard let self = self else { return }
            let isSelected = self.currentSelectedBook?.id == item.id
            cell.configure(with: item, isSelected: isSelected)
            
            cell.onTouchTopIcon.bind(with: self) { owner, _ in
                owner.showActionSheet(
                    title: item.title,
                    editAction: {
                        let vc = CreateBookViewController(selectedBookInfo: (item.id, item.title))
                        vc.modalPresentationStyle = .overFullScreen
                        vc.modalTransitionStyle = .crossDissolve
                        
                        vc.bookCreated
                            .bind(to: owner.refreshTrigger)
                            .disposed(by: vc.disposeBag)
                        owner.present(vc, animated: true)
                    },
                    deleteAction: {
                        owner.deleteTrigger.accept(item)
                    }
                )
            }.disposed(by: cell.disposeBag)
        }
        
        dataSource = DataSource(collectionView: collectionView) { collectionView, indexPath, itemIdentifier in
            return collectionView.dequeueConfiguredReusableCell(
                using: cellRegistration,
                for: indexPath,
                item: itemIdentifier)
        }
    }
    
    private func applySnapshot(items: [WordBook]) {
        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems(items)
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    
    private static func layout() -> UICollectionViewLayout {
        let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(140))
        )
        
        item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(140)
        )
        
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 12
        
        let layout = UICollectionViewCompositionalLayout(section: section)
        
        return layout
    }
}


