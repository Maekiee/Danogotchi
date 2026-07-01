import UIKit
import SnapKit
import RxSwift
import RxCocoa


protocol MyBookDetailViewControllerDelegate: AnyObject {
    func myBookDetailDidTapBack()
    func myBookDetailDidTapCreateWord(with createVocabModel: CreateVocab)
    func myBookDetailDidTapEditWord(with createVocabModel: CreateVocab)
}

final class MyBookDetailViewController: BaseViewController {
    weak var delegate: MyBookDetailViewControllerDelegate?
    private let disposeBag = DisposeBag()
    private let viewModel: MyBookDetailViewModel
    private let userInfo = UserInfoManager.shared
    
    init(viewModel: MyBookDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let deleteWordTrigger = PublishRelay<Vocab>()
    private let myBookObjectId = BehaviorRelay<UUID?>(value: nil)
    
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
        config.image = UIImage(systemName: "chevron.backward")
        config.title = "Back"
        config.imagePadding = 4
        config.baseForegroundColor = AppColor.textPrimary
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
    private let emptyTextLabel: UILabel = {
        let label = UILabel()
        label.text = "아직 단어를 추가하지 않았어요\n단어를 추가해 주세요"
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        return label
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
            emptyTextLabel,
            addBookButton,
        ].forEach { view.addSubview($0)
        }
    }
    
    override func configLayout() {
        
        backButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.leading.equalTo(view.safeAreaLayoutGuide).offset(12)
        }
        
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
            make.top.equalTo(backButton.snp.bottom).offset(8)
            make.horizontalEdges.equalToSuperview().inset(16)
            make.bottom.equalToSuperview()
        }
    }
    
    override func configView() {
        view.backgroundColor = AppColor.backgroundBeige
        collectionView.contentInset.bottom = 100
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
        
        backButton.rx.tap
            .bind(with: self) { owner, _ in
                // 코디네이터 적용
                owner.delegate?.myBookDetailDidTapBack()
            }.disposed(by: disposeBag)
        
        addBookButton.rx.tap
            .withLatestFrom(myBookObjectId)
            .compactMap{ $0 }
            .bind(with: self) { owner, bookObjectId in
                let createVocabModel = CreateVocab(
                    vocabBookId: bookObjectId,
                    vocabId: nil,
                    bookTitle: "나의 단어장",
                    word: "",
                    meaning: "",
                    actionType: .add
                )
                // 코디네이터 적용
                owner.delegate?.myBookDetailDidTapCreateWord(with: createVocabModel)
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
                    editAction: {
                        guard let bookObjectId = owner.myBookObjectId.value else {
                            print("Error: '나의 단어장' ID가 없습니다.")
                            return
                        }
                        
                        let createVocabModel = CreateVocab(
                            vocabBookId: bookObjectId,
                            vocabId: item.word.id,
                            bookTitle: "",
                            word: item.word.word,
                            meaning: item.word.meaning,
                            actionType: .edit
                        )
                        // 코디네이터 적용
                        owner.delegate?.myBookDetailDidTapEditWord(with: createVocabModel)
                    },
                    deleteAction: {
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
                item: itemIdentifier,
            )
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
