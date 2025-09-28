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
        cv.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "ImageCell")
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
        let input = WordImageListViewModel.Input()
        let output = viewModel.transform(input: input)
        
        output.imageList
            .drive(collectionView.rx.items(cellIdentifier: "ImageCell")) { index, item, cell in
                // 기본 셀 설정 (나중에 커스텀 셀로 교체 예정)
                cell.backgroundColor = .systemGray5
                cell.layer.cornerRadius = 8
                cell.clipsToBounds = true
                
                let imageView = UIImageView()
                imageView.contentMode = .scaleAspectFill
                imageView.clipsToBounds = true
                
                cell.contentView.subviews.forEach { $0.removeFromSuperview() }
                cell.contentView.addSubview(imageView)
                
                
                imageView.snp.makeConstraints { $0.edges.equalToSuperview() }
                
                imageView.backgroundColor = .systemBlue
                imageView.kf.setImage(with: URL(string: item.urls.small)!)
            }.disposed(by: disposeBag)
        
        collectionView.rx.modelSelected(PhotoDTO.self)
            .bind(with: self) { owner, item in
                print(item.urls.raw)
                owner.onChangedImage?(item.urls.small)
            }.disposed(by: disposeBag)
        
        navigationItem.leftBarButtonItem!.rx.tap
            .bind(with: self) { owner, _ in
                owner.navigationController?.popViewController(animated: true)
            }.disposed(by: disposeBag)
        
        
    }
}
