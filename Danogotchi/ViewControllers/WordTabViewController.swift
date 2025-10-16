import Kingfisher
import RealmSwift
import RxCocoa
import RxSwift
import SnapKit
import UIKit

final class WordTabViewController: BaseViewController {
    private let disposeBag = DisposeBag()
    private let viewModel: WordTabViewModel
    private let userInfo = UserInfoManager.shared
    private var bookTitle = ""
    private var allWordsInfo: [WordDisplayInfo] = []

    private enum Section {
        case main
    }

    private typealias DataSource = UICollectionViewDiffableDataSource<
        Section, WordDisplayInfo
    >
    private typealias Snapshot = NSDiffableDataSourceSnapshot<
        Section, WordDisplayInfo
    >

    private var dataSource: DataSource!

    init(viewModel: WordTabViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI 프로퍼티
    private let listSegmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["전체", "완료"])
        control.selectedSegmentIndex = 0
        control.backgroundColor = .systemGray5
        return control
    }()

    private let addWordButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        button.tintColor = UIColor.black.withAlphaComponent(0.8)

        return button
    }()

    private let showWordBookButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(
            UIImage(systemName: "rectangle.stack.fill"),
            for: .normal
        )
        button.tintColor = UIColor.black.withAlphaComponent(0.8)
        return button
    }()

    private let noWordBookLabel: UILabel = {
        let label = UILabel()
        label.text = "학습할 단어장을 만들어 주세요"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .black
        return label
    }()

    //    private let noWordLabel: UILabel = {
    //        let label = UILabel()
    //        label.text = "학습할 단어를 추가해주세요"
    //        label.font = .systemFont(ofSize: 16, weight: .semibold)
    //        label.textColor = .black
    //        return label
    //    }()

    private let showCreateBookButton = PrimaryFillButton(title: "단어장 만들기")

    private let testButton: UIButton = {
        let button = UIButton(type: .roundedRect)
        button.frame = CGRect(x: 20, y: 50, width: 100, height: 30)
        button.setTitle("Test Crash", for: [])
        return button
    }()

    let startLearningButton: UIButton = {
        var config = UIButton.Configuration.filled()

        // 텍스트 설정
        config.title = "학습하기"
        config.baseForegroundColor = .black

        // 하얀색 유리 효과 배경 설정
        config.background.backgroundColor = UIColor.white.withAlphaComponent(
            0.25
        )
        config.background.cornerRadius = 22
        config.background.visualEffect = UIBlurEffect(
            style: .systemUltraThinMaterialLight
        )
        config.contentInsets = NSDirectionalEdgeInsets(
            top: 12,
            leading: 24,
            bottom: 12,
            trailing: 24
        )

        // 테두리 추가 (유리 느낌 강화)
        config.background.strokeColor = UIColor.white.withAlphaComponent(0.8)
        config.background.strokeWidth = 1

        let button = UIButton(configuration: config)

        // 폰트 설정
        button.configuration?.titleTextAttributesTransformer =
            UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = .systemFont(ofSize: 15, weight: .semibold)
                return outgoing
            }
        return button
    }()

    private let collectionView: UICollectionView = {
        let view = UICollectionView(
            frame: .zero,
            collectionViewLayout: WordTabViewController.layout()
        )
        view.showsVerticalScrollIndicator = false
        view.backgroundColor = AppColor.appBackgroundColor
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

            noWordBookLabel,
            //            noWordLabel,
            showCreateBookButton,
            collectionView,
            startLearningButton,
//            testButton, // x테스트
            listSegmentedControl,
        ].forEach { view.addSubview($0) }
    }

    override func configLayout() {
        noWordBookLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        //        noWordLabel.snp.makeConstraints { make in
        //            make.center.equalToSuperview()
        //        }

        showCreateBookButton.snp.makeConstraints { make in
            make.top.equalTo(noWordBookLabel.snp.bottom).offset(8)
            make.horizontalEdges.equalToSuperview().inset(24)
            make.height.equalTo(40)
        }
        
        

        listSegmentedControl.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.horizontalEdges.equalToSuperview().inset(16)
            make.height.equalTo(32)  // 적절한 높이 설정
        }

        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        /// 크레시 테스트
//        testButton.snp.makeConstraints { make in
//            make.bottom.equalTo(startLearningButton.snp.top).offset(10)
//            make.horizontalEdges.equalToSuperview().inset(24)
//            make.height.equalTo(44)
//        }

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
            viewWillAppear: rx.methodInvoked(#selector(viewWillAppear)).map {
                _ in
            },
            selectedWordCard: deleteWordTrigger.asObservable(),
            segmentChanged: listSegmentedControl.rx.selectedSegmentIndex
                .asObservable()
        )

        let output = viewModel.transform(input: input)

        listSegmentedControl.rx.selectedSegmentIndex
            .bind(with: self) { owner, index in
                owner.startLearningButton.isHidden = index == 1 ? true : false
            }.disposed(by: disposeBag)

        output.bookTitle
            .drive(with: self) { owner, title in
                owner.bookTitle = title
                owner.navigationItem.title = title
            }.disposed(by: disposeBag)

        output.currentWordbook
            .drive(with: self) { owner, hasWordBook in
                // 단어장 1개 이상
                owner.addWordButton.isHidden = hasWordBook
                owner.showWordBookButton.isHidden = hasWordBook
                //                owner.collectionView.isHidden = hasWordBook
                owner.startLearningButton.isHidden = hasWordBook

                // 단어장 0개
                owner.noWordBookLabel.isHidden = !hasWordBook
                owner.showCreateBookButton.isHidden = !hasWordBook
            }
            .disposed(by: disposeBag)

        output.wordItems
            .drive(with: self) { owner, wordList in
                let selectedBook = owner.userInfo.selectedBookId

                if selectedBook == nil && wordList.isEmpty {
                    //                    owner.noWordLabel.isHidden = true
                    owner.collectionView.isHidden = true
                } else if selectedBook != nil && wordList.isEmpty {
                    //                    owner.noWordLabel.isHidden = false
                    owner.collectionView.isHidden = true
                } else {
                    owner.collectionView.isHidden = false
                }

                owner.allWordsInfo = wordList
                owner.applySnapshot(items: wordList)
            }.disposed(by: disposeBag)

        // 단어 추가
        addWordButton.rx.tap
            .bind(with: self) { owner, _ in
                guard
                    let bookObjectId = owner.userInfo.selectedBookId
                        .flatMap({ try? ObjectId(string: $0) })
                else { return }

                let createWordModel = CreateWord(
                    wordBookId: bookObjectId,
                    wordId: nil,
                    thumbnail: "",
                    bookTitle: owner.bookTitle,
                    word: "",
                    meaning: "",
                    actionType: .add
                )

                let vm = AddWordViewModel(wordItem: createWordModel)
                let vc = UINavigationController(
                    rootViewController: AddWordViewController(
                        viewModel: vm,
                        entryPoint: .add
                    )
                )
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
                    print("최소 4개 이상 필요해요")

                    AlertUtils.showNotificationAlert(
                        on: owner,
                        title: "알림",
                        message: "최소 4개 이상의 단어가 필요합니다."
                    )
                    return
                }

                var wordsForQuiz: [Word]

                // 이어할 퀴즈가 있는지 확인합니다.
                if let currentWordIds = owner.userInfo.currentQuizWordIds {
                    // 이어할 퀴즈가 있다면, 저장된 단어 ID 목록을 기반으로 퀴즈를 재구성합니다.
                    // (틀린 문제 학습하기를 이어하는 경우도 이 로직으로 처리됩니다.)
                    let wordIdSet = Set(currentWordIds)
                    wordsForQuiz = allWords.filter { wordIdSet.contains($0.id) }
                } else {
                    // 새로 시작하는 퀴즈라면, 전체 단어 목록으로 퀴즈를 구성하고 상태를 저장합니다.
                    wordsForQuiz = allWords
                    let wordIds = wordsForQuiz.map { $0.id }
                    owner.userInfo.currentQuizWordIds = wordIds
                    owner.userInfo.currentQuizIndex = 0
                    owner.userInfo.currentCorrectCount = 0
                    owner.userInfo.currentIncorrectWordIds = nil
                }

                // 위에서 결정된 `wordsForQuiz`를 사용하여 퀴즈 데이터를 생성합니다.
                let quizData = QuizData(words: wordsForQuiz, allWord: allWords)

                let choiceVM = ChoiceQuizViewModel(quizData: quizData)
                let choiceVC = ChoiceQuizViewController(viewModel: choiceVM)
                choiceVC.modalPresentationStyle = .fullScreen
                owner.present(choiceVC, animated: true)
            }.disposed(by: disposeBag)
        
        
        // 크레시 테스트
//        testButton.rx.tap
//            .bind(with: self) { owner, _ in
//                let numbers = [0]
//                let _ = numbers[1]
//            }.disposed(by: disposeBag)

    }
}

// MARK: - CollectionView
extension WordTabViewController {
    private func configDataSource() {
        // 셀ㅜ
        let cellRegistration = UICollectionView.CellRegistration<
            WordCardCollectionViewCell, WordDisplayInfo
        > { cell, indexPath, item in
            cell.configure(with: item)
            cell.onTouchTopIcon.bind(with: self) { owner, _ in
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
                            thumbnail: item.word.thumbnail,
                            bookTitle: owner.bookTitle,
                            word: item.word.word,
                            meaning: item.word.meaning,
                            actionType: .edit
                        )
                        let vm = AddWordViewModel(wordItem: createWordModel)
                        let vc = UINavigationController(
                            rootViewController: AddWordViewController(
                                viewModel: vm,
                                entryPoint: .edit
                            )
                        )
                        vc.modalPresentationStyle = .fullScreen
                        owner.present(vc, animated: true)
                    },
                    deleteAction: { [weak self] in
                        guard let self = self else { return }
                        deleteWordTrigger.accept(item.word)
                    }
                )
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

    // 추후에 공용으로 사용할 수 있는 메서드로 분리 해보기
    private static func layout() -> UICollectionViewLayout {
        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .estimated(250)
            )
        )

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(250)
        )

        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitems: [item]
        )

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 16
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 48,
            leading: 16,
            bottom: 80,
            trailing: 16
        )

        let layout = UICollectionViewCompositionalLayout(section: section)

        return layout
    }
}
