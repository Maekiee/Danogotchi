import UIKit
import SnapKit
import RealmSwift
import RxSwift
import RxCocoa
import Kingfisher


final class WordTabViewController: BaseViewController {
    private let disposeBag = DisposeBag()
    private let viewModel: WordTabViewModel
    private let userInfo = UserInfoManager.shared
    private var bookTitle = ""
    
    private enum Section {
        case main
    }
    
    private typealias DataSource = UICollectionViewDiffableDataSource<Section, WordModel>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, WordModel>
    
    private var dataSource: DataSource!
    
    
    init(viewModel: WordTabViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI 프로퍼티
    private let addWordButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "plus"), for: .normal)
        button.tintColor = .systemBlue
        return button
    }()
    
    private let showWordBookButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "line.3.horizontal"), for: .normal)
        button.tintColor = .systemBlue
        return button
    }()
    
    private let noWordBookLabel: UILabel = {
        let label = UILabel()
        label.text = "학습할 단어장을 만들어 주세요"
        label.textColor = .black
        return label
    }()
    
    private let showCreateBookButton = PrimaryFillButton(title: "단어장 만들기")
    
    private let startLearningButton = PrimaryFillButton(title: "학습하기")
    private let collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: WordTabViewController.layout())
        view.showsVerticalScrollIndicator = false
        return view
    }()
    
    private let deleteWordTrigger = PublishRelay<WordModel>()
    
    
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
            noWordBookLabel,
            showCreateBookButton,
            collectionView,
            startLearningButton,
        ].forEach { view.addSubview($0) }
    }
    
    override func configLayout() {
        noWordBookLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        showCreateBookButton.snp.makeConstraints { make in
            make.top.equalTo(noWordBookLabel.snp.bottom).offset(8)
            make.horizontalEdges.equalToSuperview().inset(24)
            make.height.equalTo(40)
        }
        
        collectionView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        startLearningButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            make.horizontalEdges.equalToSuperview().inset(24)
            make.height.equalTo(44)
        }
    }
    
    override func configView() {
        let firstBarButton = UIBarButtonItem(customView: showWordBookButton)
        let secondBarButton = UIBarButtonItem(customView: addWordButton)
        navigationItem.rightBarButtonItems = [firstBarButton, secondBarButton]
    }
}

extension WordTabViewController {
    private func bind() {
        let input = WordTabViewModel.Input(
            viewWillAppear:  rx.methodInvoked(#selector(viewWillAppear)).map { _ in },
            selectedWordCard: deleteWordTrigger.asObservable()
        )
        let output = viewModel.transform(input: input)
        
        output.bookTitle
            .drive(with: self) { owner, title in
                owner.bookTitle = title
            }.disposed(by: disposeBag)
        
        output.currentWordbook
            .drive(with: self) { owner, hasWordBook in
                owner.addWordButton.isHidden = hasWordBook
                owner.showWordBookButton.isHidden = hasWordBook
                owner.collectionView.isHidden = hasWordBook
                
                owner.noWordBookLabel.isHidden = !hasWordBook
                owner.showCreateBookButton.isHidden = !hasWordBook
            }
            .disposed(by: disposeBag)
        
        output.bookTitle
            .drive(navigationItem.rx.title)
            .disposed(by: disposeBag)
        
        output.wordItems
            .drive(with: self) { owner, items in
                owner.applySnapshot(items: items)
            }.disposed(by: disposeBag)
        
        // 단어 추가
        addWordButton.rx.tap
            .bind(with: self) { owner, _ in
                guard let bookObjectId = owner.userInfo.selectedBookId
                    .flatMap({ try? ObjectId(string: $0) }) else { return }
            
                let createWordModel = CreateWordModel(
                    wordBookId: bookObjectId,
                    wordId: nil,
                    thumbnail: "",
                    bookTitle: owner.bookTitle,
                    word: "",
                    meaning: "",
                    actionType: .add
                )
                
                // 여기에는 선택한 단어장의 pk 주입
                let vm = AddWordViewModel(wordItem: createWordModel)
                let vc = UINavigationController(rootViewController: AddWordViewController(viewModel: vm, entryPoint: .add))
                vc.modalPresentationStyle = .fullScreen
                owner.present(vc, animated: true)
            }.disposed(by: disposeBag)
        
        showWordBookButton.rx.tap
            .bind(with: self) { owner, _ in
                let vc = MyBookListViewController()
                owner.present(vc, animated: true)
            }.disposed(by: disposeBag)
        
        
        // 단어장 생성
        showCreateBookButton.rx.tap
            .bind(with: self) { owner, _ in
                let vc = CreateBookViewController()
                vc.modalPresentationStyle = .overFullScreen
                vc.modalTransitionStyle = .crossDissolve
                owner.present(vc, animated: true)
            }.disposed(by: disposeBag)
        
        startLearningButton.rx.tap
            .bind(with: self) { owner, _ in
                let vc = SelectQuizViewController()
                vc.modalPresentationStyle = .formSheet
                
                if let sheet =  vc.sheetPresentationController {
                    sheet.detents = [.medium(), .large()]
                    sheet.prefersGrabberVisible = true
                    // (선택) 모서리 둥글기 값을 설정합니다.
                    sheet.preferredCornerRadius = 20
                }
                
                owner.present(vc, animated: true)
            }.disposed(by: disposeBag)
        
    }
}


// MARK: - CollectionView
extension WordTabViewController {
    private func configDataSource() {
       let cellRegistration = UICollectionView.CellRegistration<WordCardCollectionViewCell, WordModel> { cell, indexPath, item in
            cell.configure(with: item)
            cell.onTouchTopIcon.bind(with: self) { owner, _ in
                owner.showActionSheet(
                    title: item.word,
                    editAction: { [weak self] in
                        guard let _ = self else { return }
                        guard let bookObjectId = owner.userInfo.selectedBookId
                            .flatMap({ try? ObjectId(string: $0) }) else { return }
                        
                        let createWordModel = CreateWordModel(
                            wordBookId: bookObjectId,
                            wordId: try! ObjectId(string: item.id),
                            thumbnail: item.thumbnail,
                            bookTitle: owner.bookTitle, // 여기
                            word: item.word,
                            meaning: item.meaning,
                            actionType: .edit
                        )
                        let vm = AddWordViewModel(wordItem: createWordModel)
                        let vc = UINavigationController(rootViewController: AddWordViewController(viewModel: vm, entryPoint: .edit))
                        vc.modalPresentationStyle = .fullScreen
                        owner.present(vc, animated: true)
                    },
                    deleteAction: { [weak self] in
                        guard let self = self else { return }
                        deleteWordTrigger.accept(item)
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
    
    private func applySnapshot(items: [WordModel]) {
        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems(items)
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    
    private static func layout() -> UICollectionViewLayout {
        let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .fractionalHeight(1.0))
        )
        item.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16)
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(200)
        )
        
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        
        let layout = UICollectionViewCompositionalLayout(section: section)
        
        return layout
    }
}
