import UIKit
import SnapKit
import RxSwift
import RxCocoa
import RealmSwift

final class MyBookDetailViewController: BaseViewController {
    private let disposeBag = DisposeBag()
    private let viewModel = MyBookDetailViewModel()
    
    private let userInfo = UserInfoManager.shared
    
    private let deleteWordTrigger = PublishRelay<Word>()
    private let myBookObjectId = BehaviorRelay<ObjectId?>(value: nil)
    
    private enum Section {
        case main
    }
    
    private typealias DataSource = UICollectionViewDiffableDataSource<Section, WordDisplayInfo>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, WordDisplayInfo>
    private var dataSource: DataSource!
    
    // MARK: UI 프로퍼티
    private let backButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "chevron.left")
        config.baseForegroundColor = .black
        button.configuration = config
        return button
    }()
    private let addBookButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.filled()
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(
                pointSize: 16,
                weight: .medium
            )
        config.image = UIImage(systemName: "plus")
        
        config.baseForegroundColor = AppColor.appWhite
        config.baseBackgroundColor = AppColor.oxfordBlue
        config.cornerStyle = .capsule
        button.configuration = config
        return button
    }()
    private let collectionView: UICollectionView = {
        let view = UICollectionView(
            frame: .zero,
            collectionViewLayout: MyBookDetailViewController.layout()
        )
        view.backgroundColor = AppColor.backgroundBeige
        view.showsVerticalScrollIndicator = false
        return view
    }()
    
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
            backButton,
            collectionView,
            addBookButton,
        ].forEach { view.addSubview($0)
        }
    }
    
    override func configLayout() {
        backButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.leading.equalToSuperview().offset(6)
        }
        
        addBookButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-28)
            make.trailing.equalToSuperview().offset(-20)
            make.size.equalTo(44)
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(backButton.snp.bottom).offset(16)
            make.horizontalEdges.equalToSuperview().inset(16)
            make.bottom.equalToSuperview()
        }
    }
    
    override func configView() {
        view.backgroundColor = AppColor.backgroundBeige
    }
}

extension MyBookDetailViewController {
    private func bind() {
        let input = MyBookDetailViewModel.Input(
            viewWillAppear: rx.methodInvoked(#selector(viewWillAppear)).map { _ in },
            deleteWordTrigger: deleteWordTrigger.asObservable()
        )
        let output = viewModel.transform(input: input)
        
        backButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.navigationController?.popViewController(animated: true)
            }.disposed(by: disposeBag)
        
        output.wordList
            .drive(with: self) { owner, items in
                owner.applaySnapshot(items: items)
            }.disposed(by: disposeBag)
        
        output.myBookObjectId
            .bind(to: myBookObjectId)
            .disposed(by: disposeBag)
        
        addBookButton.rx.tap
            .withLatestFrom(myBookObjectId)
            .compactMap{ $0 }
            .bind(with: self) { owner, bookObjectId in
                let createWordModel = CreateWord(
                    wordBookId: bookObjectId, // 💡 전달받은 ID 사용
                    wordId: nil,
                    thumbnail: "",
                    bookTitle: "나의 단어장",
                    word: "",
                    meaning: "",
                    actionType: .add // 💡 .add 액션
                )
                let vm = AddWordViewModel(wordItem: createWordModel)
                let vc = AddWordViewController(
                    viewModel: vm,
                    entryPoint: .add // 💡 .add 액션
                )
                owner.navigationController?.pushViewController(vc, animated: true)
            }.disposed(by: disposeBag)
    }
}

// MARK: 컬렉션 뷰
extension MyBookDetailViewController {
    private func configDataSource() {
        let cellregistration = UICollectionView.CellRegistration<MyBookDetailCollectionViewCell, WordDisplayInfo> { [weak self]
            cell, indexPath, item in
            guard let self = self else { return }
            cell.binding(with: item)
            
            cell.onTouchIcon.bind(with: self) { owner, _ in
                owner.showActionSheet(
                    title: item.word.word,
                    editAction: { [weak self] in
                        guard let owner = self else { return }
                        
                        // --- 💡 5. '단어 수정' (연필) 로직 수정 ---
                        
                        // 💡 5-1. ViewModel에서 받은 ID를 .value로 즉시 사용
                        guard let bookObjectId = owner.myBookObjectId.value else {
                            print("Error: '나의 단어장' ID가 없습니다.")
                            return
                        }
                        
                        let createWordModel = CreateWord(
                            wordBookId: bookObjectId, // 💡 전달받은 ID 사용
                            wordId: try! ObjectId(string: item.word.id),
                            thumbnail: item.word.thumbnail,
                            bookTitle: "",
                            word: item.word.word,
                            meaning: item.word.meaning,
                            actionType: .edit
                        )
                        let vm = AddWordViewModel(wordItem: createWordModel)
                        let vc = AddWordViewController(
                            viewModel: vm,
                            entryPoint: .edit
                        )
                        owner.navigationController?.pushViewController(vc, animated: true)
//                        let vc = UINavigationController(
//                            rootViewController: AddWordViewController(
//                                viewModel: vm,
//                                entryPoint: .edit
//                            )
//                        )
//                        vc.modalPresentationStyle = .fullScreen
//                        owner.present(vc, animated: true)
                    },
                    deleteAction: { [weak self] in
                        guard let owner = self else { return }
                        owner.deleteWordTrigger.accept(item.word)
                    }
                )
            }.disposed(by: cell.disposeBag)
        }
        
        dataSource = DataSource(collectionView: collectionView) {
            collectionView, indexPath, itemIdentifier in
            return collectionView.dequeueConfiguredReusableCell(
                using: cellregistration,
                for: indexPath,
                item: itemIdentifier)
        }
    }
    
    private func applaySnapshot(items: [WordDisplayInfo]) {
        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems(items)
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    private static func layout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(120)
        )
        
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(120)
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitems: [item]
        )
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 16, trailing: 0)
        section.interGroupSpacing = 12
        
        
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.scrollDirection = .vertical
        
        
        let layout = UICollectionViewCompositionalLayout(section: section, configuration: config)
        
        return layout
    }
}
