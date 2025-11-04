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
    private let emptyTextLabel: UILabel = {
        let label = UILabel()
        label.text = "아직 단어를 추가하지 않았어요\n단어를 추가해 주세요"
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        return label
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
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
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func configHierarchy() {
        [
            collectionView,
            emptyTextLabel,
            addBookButton,
        ].forEach { view.addSubview($0)
        }
    }
    
    override func configLayout() {
        addBookButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-28)
            make.trailing.equalToSuperview().offset(-20)
            make.size.equalTo(44)
        }
        
        
        emptyTextLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-20)
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.horizontalEdges.equalToSuperview().inset(16)
            make.bottom.equalToSuperview()
        }
    }
    
    override func configView() {
        view.backgroundColor = AppColor.backgroundBeige
        navigationController?.navigationBar.tintColor = .black
        collectionView.contentInset.bottom = 100
        
        let appearance = UINavigationBarAppearance()
        
        // 1. 네비게이션 바를 불투명하게(Opaque) 만들고, 배경색을 뷰의 배경색과 맞춥니다.
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = AppColor.backgroundBeige
        
        // 2. 네비게이션 바 하단의 그림자(선)를 제거합니다.
        appearance.shadowColor = .clear
        
        // 3. 이 appearance를 standard(스크롤 중)와 scrollEdge(맨 위) 상태 모두에 적용합니다.
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        
        // 4. (기존 코드) 백버튼 등 아이템 색상 설정
        navigationController?.navigationBar.tintColor = .black
    }
}

extension MyBookDetailViewController {
    private func bind() {
        let input = MyBookDetailViewModel.Input(
            viewWillAppear: rx.methodInvoked(#selector(viewWillAppear)).map { _ in },
            deleteWordTrigger: deleteWordTrigger.asObservable()
        )
        let output = viewModel.transform(input: input)
        
        output.wordList
            .drive(with: self) { owner, items in
                if items.isEmpty {
                    owner.emptyTextLabel.isHidden = false
                    owner.collectionView.isHidden = true
                } else {
                    owner.emptyTextLabel.isHidden = true
                    owner.collectionView.isHidden = false
                }
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
