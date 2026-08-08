import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class CustomProgressView: UIView {
    
    private let trackView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.appWhite
        view.layer.borderColor = UIColor.black.cgColor
        view.layer.borderWidth = AppBorder.thin
        return view
    }()
    private let progressFillView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.black
        return view
    }()
    
    
    private var progressWidthConstraint: Constraint?
    private var currentProgress: Float = 0.0

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupLayout() {
        backgroundColor = .clear
        
        // 트랙 뷰를 먼저 추가
        addSubview(trackView)
        trackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // 게이지 뷰를 트랙 뷰의 자식으로 추가
        trackView.addSubview(progressFillView)
        progressFillView.snp.makeConstraints { make in
            make.top.bottom.leading.equalToSuperview()
            self.progressWidthConstraint = make.width.equalTo(0).constraint
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let cornerRadius = bounds.height / 2
        
        trackView.layer.cornerRadius = cornerRadius
        progressFillView.layer.cornerRadius = cornerRadius

        trackView.clipsToBounds = true

        // bounds 확정 후 저장된 progress로 채움 너비 재계산
        progressWidthConstraint?.update(offset: trackView.bounds.width * CGFloat(currentProgress))
    }

    func setProgress(_ progress: Float, animated: Bool) {
        currentProgress = max(0.0, min(1.0, progress))

        let newWidth = trackView.bounds.width * CGFloat(currentProgress)

        progressWidthConstraint?.update(offset: newWidth)
        
        if animated {
            UIView.animate(withDuration: 0.25) {
                self.trackView.layoutIfNeeded()
            }
        } else {
            self.trackView.layoutIfNeeded()
        }
    }
}
