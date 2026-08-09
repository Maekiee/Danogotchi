import Kingfisher
import RxCocoa
import RxSwift
import SnapKit
import UIKit


protocol ExploreVocabViewControllerDelegate: AnyObject {
    func exploreVocabDidTapLibrary()
    func exploreVocabDidTapSetting()
    func exploreVocabDidTapStartQuiz(quizData: QuizData)
}

final class ExploreVocabViewController: BaseViewController {
    private let disposeBag = DisposeBag()
    private let viewModel: ExploreVocabViewModel
    private let userInfo = UserInfoManager.shared
    private var bookTitle = ""
    weak var delegate: ExploreVocabViewControllerDelegate?

    private enum Section {
        case main
    }

    /// 무한 스크롤용 셀 식별자. 같은 단어를 여러 벌 복제해 넣으므로 복제 위치(page)까지 식별자에 포함한다.
    private struct LoopItem: Hashable {
        let page: Int
        let info: VocabDisplayInfo
    }

    private typealias DataSource = UICollectionViewDiffableDataSource<Section, LoopItem>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, LoopItem>

    private var dataSource: DataSource!

    /// 목록을 3벌 복제해 가운데 벌에서 시작한다 — 앞뒤 어느 쪽으로 넘겨도 카드가 끊기지 않도록.
    private static let loopCopyCount = 3
    private var baseItems: [VocabDisplayInfo] = []
    private var pendingRecenterPage: Int?

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
    private let saveVocabRelay = PublishRelay<VocabDisplayInfo>()
    private var showsSaveButton = false

    override func viewDidLoad() {
        super.viewDidLoad()
        configHierarchy()
        configLayout()
        configView()
        configDataSource()
        bind()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let page = pendingRecenterPage, pageHeight > 0 else { return }
        pendingRecenterPage = nil
        moveTo(page: page)
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
            startLearningTapped: startLearningButton.rx.tap.asObservable(),
            saveVocabTrigger: saveVocabRelay.asObservable()
        )

        let output = viewModel.transform(input: input)
        
        UserInfoManager.shared.themeUrlObservable
            .compactMap { $0 }
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, themeUrl in
                owner.updateBackgroundImage(with: themeUrl)
            }
            .disposed(by: disposeBag)

        // 셀 구성 시점에 저장 버튼 노출 여부가 최신이어야 하므로 목록과 같이 반영한다
        Driver.combineLatest(output.wordItems, output.showsSaveButton)
            .drive(with: self) { owner, pair in
                let (wordList, showsSaveButton) = pair
                owner.showsSaveButton = showsSaveButton
                owner.collectionView.isHidden = wordList.isEmpty
                owner.applySnapshot(items: wordList)
            }.disposed(by: disposeBag)

        output.startQuiz
            .emit(with: self) { owner, quizData in
                owner.delegate?.exploreVocabDidTapStartQuiz(quizData: quizData)
            }.disposed(by: disposeBag)

        output.alertMessage
            .emit(with: self) { owner, message in
                AlertPresenter.showNotificationAlert(on: owner, title: "알림", message: message)
            }.disposed(by: disposeBag)

        showLibraryVCButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.delegate?.exploreVocabDidTapLibrary()
            }.disposed(by: disposeBag)
        
        settingTabButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.delegate?.exploreVocabDidTapSetting()
            }.disposed(by: disposeBag)

        // 페이지가 멈춘 뒤에 가운데 벌로 되돌린다 — 내용이 같아 화면상 변화가 없다
        Observable.merge(
            collectionView.rx.didEndDecelerating.asObservable(),
            collectionView.rx.didEndDragging.filter { !$0 }.map { _ in () }
        )
        .bind(with: self) { owner, _ in
            owner.recenterIfNeeded()
        }.disposed(by: disposeBag)
    }
}

// MARK: - CollectionView
extension ExploreVocabViewController {
    private func configDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<
            MainWordCardCollectionViewCell, LoopItem
        > { [weak self] cell, indexPath, loopItem in
            guard let self = self else { return }
            let item = loopItem.info
            cell.disposeBag = DisposeBag()

            cell.configure(
                with: item,
                parentVC: self,
                isSaved: item.isSaved,
                showsSaveButton: self.showsSaveButton
            )

            cell.onTouchTopIcon.bind(with: self) { owner, _ in
                TTSManager.shared.speak(item.cardTitle)
            }.disposed(by: cell.disposeBag)

            cell.onSaveVocab
                .map { item }
                .bind(to: self.saveVocabRelay)
                .disposed(by: cell.disposeBag)

            // 발음 중인 단어의 카드만 아이콘 색을 바꾼다
            TTSManager.shared.currentSpeakingText
                .observe(on: MainScheduler.instance)
                .map { $0 == item.cardTitle }
                .distinctUntilChanged()
                .bind(with: cell) { cell, isSpeaking in
                    cell.setSpeaking(isSpeaking)
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
        // 저장 토글은 목록이 그대로다 — 이때는 스크롤 위치를 건드리지 않는다
        let isSameList = baseItems.map(\.word.id) == items.map(\.word.id)
        baseItems = items

        // 카드가 1장이면 순환할 것이 없다 — 스크롤 자체를 막는다
        let isLoopEnabled = items.count > 1
        collectionView.isScrollEnabled = isLoopEnabled

        let copies = isLoopEnabled ? Self.loopCopyCount : 1
        let loopItems = (0..<(items.count * copies)).map { page in
            LoopItem(page: page, info: items[page % items.count])
        }

        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems(loopItems)
        // 저장 상태가 바뀌면 diffable이 삭제+삽입으로 처리한다 — 페이징 카드가 튀지 않도록 애니메이션은 끈다
        dataSource.apply(snapshot, animatingDifferences: false) { [weak self] in
            guard let self, !isSameList else { return }
            // 목록이 바뀌면 복제 버퍼도 새로 잡아야 한다 — 가운데 벌의 첫 카드로
            moveTo(page: middlePageStart)
        }
    }

    // MARK: - 무한 스크롤
    /// contentInsetAdjustmentBehavior가 .never라 페이지 높이 = 컬렉션뷰 높이다.
    private var pageHeight: CGFloat { collectionView.bounds.height }
    private var middlePageStart: Int { baseItems.count * (Self.loopCopyCount / 2) }

    private func moveTo(page: Int) {
        guard pageHeight > 0 else {
            // 레이아웃 전이면 bounds가 0이라 offset을 못 구한다 — viewDidLayoutSubviews로 미룬다
            pendingRecenterPage = page
            return
        }
        // contentSize가 새 스냅샷 기준으로 확정돼야 offset이 잘리지 않는다
        collectionView.layoutIfNeeded()
        collectionView.setContentOffset(
            CGPoint(x: 0, y: CGFloat(page) * pageHeight),
            animated: false
        )
    }

    /// 가장자리 벌에 착지했으면 같은 카드를 보여주는 가운데 벌로 순간 이동한다.
    private func recenterIfNeeded() {
        let count = baseItems.count
        guard count > 1, pageHeight > 0 else { return }

        let page = Int((collectionView.contentOffset.y / pageHeight).rounded())
        guard page < middlePageStart || page >= middlePageStart + count else { return }
        moveTo(page: (page % count) + middlePageStart)
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
