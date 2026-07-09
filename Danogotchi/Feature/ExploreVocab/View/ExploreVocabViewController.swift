import Kingfisher
import RxCocoa
import RxSwift
import SnapKit
import UIKit


protocol ExploreVocabViewControllerDelegate: AnyObject {
    func exploreVocabDidTapLibrary()
    func exploreVocabDidTapSetting()
    func exploreVocabDidTapStartQuiz(quizData: QuizData)
    func exploreVocabDidTapEditWord(vocabItem: CreateVocab)
}

final class ExploreVocabViewController: BaseViewController {
    private let disposeBag = DisposeBag()
    private let viewModel: ExploreVocabViewModel
    private let userInfo = UserInfoManager.shared
    private var bookTitle = ""
    private var allWordsInfo: [VocabDisplayInfo] = []
    weak var delegate: ExploreVocabViewControllerDelegate?

    private enum Section {
        case main
    }

    private typealias DataSource = UICollectionViewDiffableDataSource<Section, VocabDisplayInfo>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, VocabDisplayInfo>

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
        config.baseForegroundColor = AppColor.white
        config.background.backgroundColor = AppColor.black.withAlphaComponent(
            0.25
        )
        config.background.cornerRadius = AppSpacing.space24
        config.background.visualEffect = UIBlurEffect(
            style: .systemMaterialDark
        )
        let button = UIButton(configuration: config)
        return button
    }()
    private let showLibraryVCButton: UIButton = {
        var config = UIButton.Configuration.filled()
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium, scale: .default)
        config.image = UIImage(systemName: "square.grid.2x2", withConfiguration: symbolConfig)
        config.baseForegroundColor = AppColor.white
        config.background.backgroundColor = AppColor.black.withAlphaComponent(0.25)
        config.background.cornerRadius = AppSpacing.space24
        config.background.visualEffect = UIBlurEffect(
            style: .systemMaterialDark
        )
        let button = UIButton(configuration: config)
        return button
    }()
    let startLearningButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "학습하기"
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium, scale: .default)
        config.image = UIImage(systemName: "graduationcap", withConfiguration: symbolConfig)
        config.imagePadding = AppSpacing.space4
        config.baseForegroundColor = AppColor.white
        config.background.backgroundColor = AppColor.black.withAlphaComponent(
            0.25
        )
        config.background.cornerRadius = AppSpacing.space24
        config.background.visualEffect = UIBlurEffect(
            style: .systemMaterialDark
        )
        config.contentInsets = NSDirectionalEdgeInsets(
            top: AppSpacing.space12,
            leading: AppSpacing.space12,
            bottom: AppSpacing.space12,
            trailing: AppSpacing.space16
        )
        let button = UIButton(configuration: config)
        button.configuration?.titleTextAttributesTransformer =
            UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = AppFont.label
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

    private let deleteWordTrigger = PublishRelay<Vocab>()

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
            showLibraryVCButton,
            settingTabButton,
            startLearningButton,
            
        ].forEach { view.addSubview($0) }
    }

    override func configLayout() {
        
        themeBackgroundImage.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        showLibraryVCButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-AppSpacing.space20)
            make.leading.equalTo(view.safeAreaLayoutGuide).offset(AppSpacing.space20)
            make.size.equalTo(AppSpacing.space24 * 2)
        }
        
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        startLearningButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-AppSpacing.space20)
            make.centerX.equalToSuperview()
            make.height.equalTo(AppSpacing.space24 * 2)
        }
        
        settingTabButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-AppSpacing.space20)
            make.trailing.equalTo(view.safeAreaLayoutGuide).offset(-AppSpacing.space20)
            make.size.equalTo(AppSpacing.space24 * 2)
        }
    }

    override func configView() {
        if let themeUrl = userInfo.currentThemeUrl {
            themeBackgroundImage.kf.setImage(with: URL(string: themeUrl))
        }
    }
}

extension ExploreVocabViewController {
    private func updateBackgroundImage(with urlString: String) {
        guard let url = URL(string: urlString) else { return }
        themeBackgroundImage.kf.setImage(
            with: url,
            options: [.transition(.fade(0.3)), .cacheOriginalImage]
        )
    }
    
    private func bind() {
        let input = ExploreVocabViewModel.Input(
            viewWillAppear: rx.methodInvoked(#selector(viewWillAppear)).map {
                _ in
            },
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

        showLibraryVCButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.delegate?.exploreVocabDidTapLibrary()
//                owner.delegate?.
            }.disposed(by: disposeBag)
        
        settingTabButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.delegate?.exploreVocabDidTapSetting()
            }.disposed(by: disposeBag)

        startLearningButton.rx.tap
            .bind(with: self) { owner, _ in
                let allWords = owner.allWordsInfo.map { $0.word }

                guard !allWords.isEmpty else {
                    AlertPresenter.showNotificationAlert(
                        on: owner,
                        title: "알림",
                        message: "학습할 단어가 없습니다."
                    )
                    return
                }

                guard allWords.count >= 4 else {
                    AlertPresenter.showNotificationAlert(
                        on: owner,
                        title: "알림",
                        message: "최소 4개 이상의 단어가 필요합니다."
                    )
                    return
                }

                var wordsForQuiz: [Vocab]

                if let currentWordIds = owner.userInfo.currentQuizWordIds {
                    let wordMap = Dictionary(uniqueKeysWithValues: allWords.map { ($0.id.uuidString, $0) })
                    wordsForQuiz = currentWordIds.compactMap { wordMap[$0] }
                } else {
                    wordsForQuiz = allWords
                    let wordIds = wordsForQuiz.map { $0.id.uuidString }
                    owner.userInfo.currentQuizWordIds = wordIds
                    owner.userInfo.currentQuizIndex = 0
                    owner.userInfo.currentCorrectCount = 0
                    owner.userInfo.currentIncorrectWordIds = nil
                }
                
                let quizData = QuizData(words: wordsForQuiz, allWord: allWords)

                owner.delegate?.exploreVocabDidTapStartQuiz(quizData: quizData)
            }.disposed(by: disposeBag)
    }
}

// MARK: - CollectionView
extension ExploreVocabViewController {
    private func configDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<
            MainWordCardCollectionViewCell, VocabDisplayInfo
        > { [weak self] cell, indexPath, item in
            guard let self = self else { return }
            
            cell.configure(with: item, parentVC: self)
            
            cell.onTouchTopIcon.bind(with: self) { owner, _ in
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

    private func applySnapshot(items: [VocabDisplayInfo]) {
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
