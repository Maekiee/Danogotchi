import UIKit
import SnapKit
import RxSwift
import RxCocoa


final class WordImageListViewController: BaseViewController {
    private let disposeBag = DisposeBag()
    private let viewModel: WordImageListViewModel
    
    var onChangedImage: ((String) -> Void)?
    
    init(viewModel: WordImageListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 8
        layout.minimumInteritemSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .systemBackground
        cv.register(WordImageCollectionViewCell.self, forCellWithReuseIdentifier: WordImageCollectionViewCell.identifier)
        return cv
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configHierarchy()
        configLayout()
        configView()
        
        bind()
    }
    
    override func configHierarchy() {
        [
            collectionView
        ].forEach { view.addSubview($0) }
    }
    
    override func configLayout() {
        collectionView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }
    
    override func configView() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: nil,
            action: nil
        )
        
        navigationItem.title = viewModel.wordText
        
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.itemSize = CGSize(
                width: (view.frame.width - 48) / 3, // 3개 컬럼, 패딩 고려
                height: (view.frame.width - 48) / 3
            )
        }
    }
}

extension WordImageListViewController {
    private func bind() {
        
        var selectedImageUrl: String?
        
        let input = WordImageListViewModel.Input()
        let output = viewModel.transform(input: input)
        
        output.imageList
            .drive(collectionView.rx.items(cellIdentifier: WordImageCollectionViewCell.identifier, cellType: WordImageCollectionViewCell.self)) { index, item, cell in
                cell.config(with: item.urls.small, isSelected: item.urls.small == selectedImageUrl)
            }.disposed(by: disposeBag)
        
        collectionView.rx.modelSelected(PhotoDTO.self)
            .bind(with: self) { owner, item in
                
                // ✅ 선택 상태 업데이트
                let previousUrl = selectedImageUrl
                selectedImageUrl = item.urls.small
                
                // 셀 업데이트
                for cell in owner.collectionView.visibleCells {
                    if let imageCell = cell as? WordImageCollectionViewCell,
                       let indexPath = owner.collectionView.indexPath(for: cell),
                       let photoItem = try? owner.collectionView.rx.model(at: indexPath) as PhotoDTO {
                        imageCell.setSelected(photoItem.urls.small == selectedImageUrl)
                    }
                }
                
                owner.onChangedImage?(item.urls.small)
                owner.onChangedImage?(item.urls.small)
            }.disposed(by: disposeBag)
        
        navigationItem.leftBarButtonItem!.rx.tap
            .bind(with: self) { owner, _ in
                owner.navigationController?.popViewController(animated: true)
            }.disposed(by: disposeBag)
        
        
    }
}
