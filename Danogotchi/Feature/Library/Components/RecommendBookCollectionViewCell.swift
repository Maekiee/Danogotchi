import UIKit
import SnapKit
import RxSwift
import RxCocoa


final class RecommendBookCollectionViewCell: UICollectionViewCell {
    var disposeBag = DisposeBag()
    
    var onTouchDownload: Observable<Void> {
        return downloadButton.rx.tap.asObservable()
    }
    
    
    private let symbolIconImage: UIImageView = {
        let view = UIImageView()
//        view.image = UIImage(named: "businessIcon")
        view.contentMode = .scaleAspectFill
//        view.layer.borderWidth = 1
//        view.layer.borderColor = UIColor.gray.cgColor
        return view
    }()
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = AppColor.textPrimary
        label.font = AppFont.font(.bold, size: 18)
        return label
    }()
    private let checkIcon: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(systemName: "checkmark.circle.fill")
        view.tintColor = AppColor.oxfordBlue
        view.backgroundColor = AppColor.backgroundBeige2
        view.layer.cornerRadius = AppRadius.radius12
        view.clipsToBounds = true
        view.isHidden = true
        return view
    }()
    private let downloadButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.plain()
        // 아이콘을 크고 굵게 설정
        config.image = UIImage(systemName: "arrow.down.circle.fill")
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(
            pointSize: 40, // 아이콘 크기
            weight: .medium
        )
        config.baseForegroundColor = AppColor.oxfordBlue
        button.configuration = config
        button.isHidden = true // 기본값은 숨김
        return button
    }()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
        
        checkIcon.isHidden = true
        downloadButton.isHidden = true
        titleLabel.isHidden = false
        titleLabel.text = nil
        
        symbolIconImage.snp.remakeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-AppSpacing.space16)
            make.height.equalTo(112)
            make.width.equalTo(200)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configHierarchy()
        configLayout()
        configView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configHierarchy() {
        [
            titleLabel,
            checkIcon,
            downloadButton,
            symbolIconImage
        ].forEach { contentView.addSubview($0)
        }
    }
    
    private func configLayout() {
        titleLabel.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-AppSpacing.space20)
            make.leading.equalToSuperview().offset(AppSpacing.space20)
        }
        
        checkIcon.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(AppSpacing.space12)
            make.trailing.equalToSuperview().inset(AppSpacing.space12)
        }

        downloadButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-AppSpacing.space16)
        }
        
        symbolIconImage.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-AppSpacing.space16)
            make.height.equalTo(112)
            make.width.equalTo(200)
        }
    }
    
    private func configView() {
        backgroundColor = AppColor.backgroundBeige2
        layer.borderWidth = AppBorder.regular
        layer.borderColor = AppColor.pointBlack.cgColor
        layer.cornerRadius = AppRadius.radius20
        
        // 그림자 (cell의 layer에 적용)
        layer.shadowColor = AppColor.pointBlack.cgColor
        layer.shadowOpacity = 1
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 0
    }
    
    
    func binding(with item: LibraryViewModel.RecommendItem, isSelected: Bool, indexRow: Int) {
        symbolIconImage.image = UIImage(named: "book_image_\(indexRow)")
        
        if indexRow == 2 {
            symbolIconImage.snp.remakeConstraints { make in
                make.centerX.equalToSuperview()
                make.centerY.equalToSuperview().offset(-AppSpacing.space4)
                make.height.equalTo(88)
                make.width.equalTo(180)
            }
        } else {
            symbolIconImage.snp.remakeConstraints { make in
                make.centerX.equalToSuperview()
                make.centerY.equalToSuperview().offset(-AppSpacing.space16)
                make.height.equalTo(112)
                make.width.equalTo(200)
            }
        }
        
        
        switch item {
        case .downloaded(let downloadedBook):
            // 1. 이미 로컬 DB에 저장된 경우 (기존 로직)
            titleLabel.text = downloadedBook.title
            checkIcon.isHidden = !isSelected
            downloadButton.isHidden = true
            symbolIconImage.isHidden = false
            titleLabel.isHidden = false
            
        case .notDownloaded(let mockBook):
            // 2. 로컬 DB에 없는 경우 (다운로드 UI)
            titleLabel.text = mockBook.title // 제목은 흐리게 표시
            titleLabel.isHidden = false
            checkIcon.isHidden = true
            downloadButton.isHidden = false
            symbolIconImage.isHidden = true
            
            // 다운로드 버튼이 보일 때 제목을 흐리게 처리 (선택 사항)
            titleLabel.textColor = AppColor.textSecondary
        }
        
        
    }
}

