import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class ThemeImageCollectionViewCell: UICollectionViewCell {
    var disposeBag = DisposeBag()
    private var thumbnailTask: Task<Void, Never>?

    private let thumbnail: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        return view
    }()
    private let selectionOverlay: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        view.isHidden = true
        return view
    }()
    private let checkmarkIcon: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(systemName: "checkmark.circle.fill")
        view.tintColor = AppColor.appWhite
        view.backgroundColor = AppColor.black
        view.layer.cornerRadius = AppRadius.radius12
        view.clipsToBounds = true
        view.isHidden = true
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        configHierarchy()
        configLayout()
        configView()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
        thumbnailTask?.cancel()
        thumbnailTask = nil
        thumbnail.image = nil
        setSelected(false)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configBind(with item: ThemeImageViewData, isSelected: Bool, loader: RemoteImageLoader) {
        setSelected(isSelected)

        guard let url = URL(string: item.thumbnailUrl) else { return }

        // 이미 받아둔 이미지는 즉시 넣는다 — 재사용 때 한 프레임 비는 것을 막는다
        if let cached = loader.cachedImage(for: url) {
            thumbnail.image = cached
            return
        }

        thumbnailTask = Task { @MainActor [weak self] in
            let image = await loader.load(url: url)
            guard !Task.isCancelled, let self, let image else { return }
            self.thumbnail.image = image
        }
    }
    
    private func configHierarchy() {
        [
            thumbnail,
            selectionOverlay,
            checkmarkIcon,
        ].forEach { contentView.addSubview($0) }
    }
    
    private func configLayout() {
        thumbnail.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        selectionOverlay.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        checkmarkIcon.snp.makeConstraints { make in
            make.trailing.bottom.equalToSuperview().inset(AppSpacing.space8)
            make.size.equalTo(24)
        }
    }
    
    private func configView() {
        backgroundColor = .systemGray5
        layer.cornerRadius = AppRadius.radius12
        clipsToBounds = true

        contentView.layer.cornerRadius = AppRadius.radius12
        contentView.clipsToBounds = true //

    }
    
    
    func setSelected(_ selected: Bool) {
        contentView.layer.borderWidth = selected ? AppBorder.thick : 0
        contentView.layer.borderColor = selected ? AppColor.appWhite.cgColor : UIColor.clear.cgColor
        selectionOverlay.isHidden = !selected
        checkmarkIcon.isHidden = !selected
    }
}
