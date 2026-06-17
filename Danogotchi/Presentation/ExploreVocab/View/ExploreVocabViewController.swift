import Kingfisher
import RealmSwift
import RxCocoa
import RxSwift
import SnapKit
import UIKit


protocol ExploreVocabViewControllerDelegate: AnyObject {
    func exploreVocabDidTapLibrary()
    func exploreVocabDidTapSetting()
    func exploreVocabDidTapStartQuiz(quizData: QuizData)
    func exploreVocabDidTapEditWord(wordItem: CreateWord)
}

final class ExploreVocabViewController: BaseViewController {
    private let disposeBag = DisposeBag()
    private let viewModel: ExploreVocabViewModel
    private let userInfo = UserInfoManager.shared
    private var bookTitle = ""
    private var allWordsInfo: [WordDisplayInfo] = []
    weak var delegate: ExploreVocabViewControllerDelegate?

    private enum Section {
        case main
    }

    private typealias DataSource = UICollectionViewDiffableDataSource<Section, WordDisplayInfo>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, WordDisplayInfo>

    private var dataSource: DataSource!

    init(viewModel: ExploreVocabViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI 프로퍼티
    private let themeBackgroundImage: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        return view
    }()

    private let settingTabButton: UIButton = {
        var config = UIButton.Configuration.filled()
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium, scale: .default)
        config.image = UIImage(systemName: "gearshape", withConfiguration: symbolConfig)
        config.baseForegroundColor = .black
        config.baseForegroundColor = .white
        // 어두운 반투명
        config.background.backgroundColor = .black.withAlphaComponent(
            0.25
        )
        config.background.cornerRadius = 24
        config.background.visualEffect = UIBlurEffect(
            style: .systemMaterialDark
        )
        let button = UIButton(configuration: config)
        return button
    }()
    
    private let addWordButton: UIButton = {
        var config = UIButton.Configuration.filled()
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium, scale: .default)
        config.image = UIImage(systemName: "plus", withConfiguration: symbolConfig)
        config.baseForegroundColor = .black
        config.baseForegroundColor = .white
        // 어두운 반투명
        config.background.backgroundColor = .black.withAlphaComponent(
            0.25
        )
        config.background.cornerRadius = 24
        config.background.visualEffect = UIBlurEffect(
            style: .systemMaterialDark
        )
        let button = UIButton(configuration: config)
        return button
    }()

    private let showWordBookButton: UIButton = {
        var config = UIButton.Configuration.filled()
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium, scale: .default)
        config.image = UIImage(systemName: "square.grid.2x2", withConfiguration: symbolConfig)
        config.baseForegroundColor = .black
        config.baseForegroundColor = .white

        // 어두운 반투명
        config.background.backgroundColor = .black.withAlphaComponent(0.25)
        config.background.cornerRadius = 24
        config.background.visualEffect = UIBlurEffect(
            style: .systemMaterialDark
        )
        let button = UIButton(configuration: config)
        return button
    }()
    
    
    private let noBookInfoContainer: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        let view = UIVisualEffectView(effect: blurEffect)
        view.layer.cornerRadius = 20
        view.layer.masksToBounds = true
        return view
    }()
    
    private let noWordBookLabel: UILabel = {
        let label = UILabel()
        label.text = "학습할 단어장을 만들어 주세요"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .white
        return label
    }()

    let startLearningButton: UIButton = {
        var config = UIButton.Configuration.filled()

        // 텍스트 설정
        config.title = "학습하기"
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium, scale: .default)
        config.image = UIImage(systemName: "graduationcap", withConfiguration: symbolConfig)
        config.imagePadding = 4
        config.baseForegroundColor = .white

        // 하얀색 유리 효과 배경 설정
        config.background.backgroundColor = UIColor.black.withAlphaComponent(
            0.25
        )
        config.background.cornerRadius = 24
        config.background.visualEffect = UIBlurEffect(
            style: .systemMaterialDark
        )
        config.contentInsets = NSDirectionalEdgeInsets(
            top: 12,
            leading: 12,
            bottom: 12,
            trailing: 16
        )
        let button = UIButton(configuration: config)
        // 폰트 설정
        button.configuration?.titleTextAttributesTransformer =
            UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = .systemFont(ofSize: 14, weight: .semibold)
                return outgoing
            }
        return button
    }()

    private let collectionView: UICollectionView = {
        let view = UICollectionView(
            frame: .zero,
            collectionViewLayout: ExploreVocabViewController.layout()
        )
        view.isPagingEnabled = true
        view.showsVerticalScrollIndicator = false
        view.backgroundColor = .clear
        view.decelerationRate = .fast
        view.contentInsetAdjustmentBehavior = .never
        return view
    }()

    private let deleteWordTrigger = PublishRelay<Word>()

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
            themeBackgroundImage,
            collectionView,
            showWordBookButton,
            settingTabButton,
            startLearningButton,
            
        ].forEach { view.addSubview($0) }
    }

    override func configLayout() {
        
        themeBackgroundImage.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        showWordBookButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            make.leading.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.size.equalTo(48)
        }
        
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        startLearningButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            make.centerX.equalToSuperview()
            make.height.equalTo(48)
        }
        
        settingTabButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            make.trailing.equalTo(view.safeAreaLayoutGuide).offset(-20)
            make.size.equalTo(48)
        }
    }

    override func configView() {
        
        if let themeUrl = userInfo.currentThemeUrl {
            themeBackgroundImage.kf.setImage(with: URL(string: themeUrl))
        }
    }
}

extension ExploreVocabViewController {
    private func bind() {
        let input = ExploreVocabViewModel.Input(
            viewWillAppear: rx.methodInvoked(#selector(viewWillAppear)).map {
                _ in
            },
            selectedWordCard: deleteWordTrigger.asObservable(),
        )

        let output = viewModel.transform(input: input)
        
        
        UserInfoManager.shared.themeUrlObservable
            .compactMap { $0 }
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, themeUrl in
                owner.updateBackgroundImage(with: themeUrl)
            }
            .disposed(by: disposeBag)

        output.wordItems
            .drive(with: self) { owner, wordList in
                owner.collectionView.isHidden = wordList.isEmpty
                owner.allWordsInfo = wordList
                owner.applySnapshot(items: wordList)
            }.disposed(by: disposeBag)

        showWordBookButton.rx.tap
            .bind(with: self) { owner, _ in
                print("Hello world!!!")
                owner.delegate?.exploreVocabDidTapLibrary()
            }.disposed(by: disposeBag)
        
        settingTabButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.delegate?.exploreVocabDidTapSetting()
            }.disposed(by: disposeBag)

        // 학습 시작하기
        startLearningButton.rx.tap
            .bind(with: self) { owner, _ in
                let allWords = owner.allWordsInfo.map { $0.word }

                guard !allWords.isEmpty else {
                    AlertUtils.showNotificationAlert(
                        on: owner,
                        title: "알림",
                        message: "학습할 단어가 없습니다."
                    )
                    return
                }

                guard allWords.count >= 4 else {
                    AlertUtils.showNotificationAlert(
                        on: owner,
                        title: "알림",
                        message: "최소 4개 이상의 단어가 필요합니다."
                    )
                    return
                }

                var wordsForQuiz: [Word]

                if let currentWordIds = owner.userInfo.currentQuizWordIds {
                    let wordMap = Dictionary(uniqueKeysWithValues: allWords.map { ($0.id, $0) })
                    wordsForQuiz = currentWordIds.compactMap { wordMap[$0] }
                } else {
                    wordsForQuiz = allWords
                    let wordIds = wordsForQuiz.map { $0.id }
                    owner.userInfo.currentQuizWordIds = wordIds
                    owner.userInfo.currentQuizIndex = 0
                    owner.userInfo.currentCorrectCount = 0
                    owner.userInfo.currentIncorrectWordIds = nil
                }
                
                let quizData = QuizData(words: wordsForQuiz, allWord: allWords)

                owner.delegate?.exploreVocabDidTapStartQuiz(quizData: quizData)
            }.disposed(by: disposeBag)
    }
    
    private func updateBackgroundImage(with urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        themeBackgroundImage.kf.setImage(
            with: url,
            options: [.transition(.fade(0.3)), .cacheOriginalImage]
        )
    }

}

// MARK: - CollectionView
extension ExploreVocabViewController {
    private func configDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<
            MainWordCardCollectionViewCell, WordDisplayInfo
        > { [weak self] cell, indexPath, item in
            guard let self = self else { return }
            
            cell.configure(with: item, parentVC: self)
            
            cell.onTouchImageIcon.bind(with: self) { owner, _ in
                owner.showActionSheet(
                    title: item.word.word,
                    editAction: { [weak self] in
                        guard self != nil else { return }
                        
                        guard
                            let bookObjectId = owner.userInfo.selectedBookId
                                .flatMap({ try? ObjectId(string: $0) })
                        else { return }
                        
                        let createWordModel = CreateWord(
                            wordBookId: bookObjectId,
                            wordId: try! ObjectId(string: item.word.id),
                            bookTitle: owner.bookTitle,
                            word: item.word.word,
                            meaning: item.word.meaning,
                            actionType: .edit
                        )
                        
                        owner.delegate?.exploreVocabDidTapEditWord(wordItem: createWordModel)
                    },
                    deleteAction: { [weak self] in
                        guard let self = self else { return }
                        deleteWordTrigger.accept(item.word)
                    }
                )
            }.disposed(by: cell.disposeBag)
            
            cell.onTouchTopIcon.bind(with: self) { owner, _ in
                // 음성 출력
                TTSManager.shared.speak(item.cardTitle)
            }.disposed(by: cell.disposeBag)
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

    private func applySnapshot(items: [WordDisplayInfo]) {
        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems(items)
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    private static func layout() -> UICollectionViewLayout {
        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalHeight(1.0)
            )
        )

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0)
        )

        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: groupSize,
            subitems: [item]
        )

        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .none
        
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.scrollDirection = .vertical

        let layout = UICollectionViewCompositionalLayout(section: section, configuration: config)

        return layout
    }
}
