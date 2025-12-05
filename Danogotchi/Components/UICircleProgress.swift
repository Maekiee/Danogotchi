import UIKit

final class UICircleProgress: UIView {

    // MARK: - UI Properties
    private let trackLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()
    private let percentageLabel = UILabel()

    // MARK: - Properties
    private let lineWidth: CGFloat = 4.0
    private var progress: CGFloat = 0 {
        didSet {
            updatePercentageLabel()
        }
    }

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
        setupPercentageLabel()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
        setupPercentageLabel()
    }

    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        updateCircularPath()
    }
    
    // MARK: - Public Method
    public func setProgress(_ value: Double, animated: Bool = true) {
        let clampedValue = max(0.0, min(1.0, value))
        
        CATransaction.begin()
        if !animated {
            CATransaction.setDisableActions(true)
        } else {
            CATransaction.setAnimationDuration(0.5)
            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeInEaseOut))
        }
        
        progressLayer.strokeEnd = CGFloat(clampedValue)
        self.progress = CGFloat(clampedValue)
        
        CATransaction.commit()
    }
    
    // MARK: - Private Setup Methods
    private func setupLayers() {
        // 배경 트랙 레이어 설정
        layer.addSublayer(trackLayer)
        trackLayer.strokeColor = UIColor.lightGray.withAlphaComponent(0.3).cgColor
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.lineWidth = lineWidth
        
        // 프로그레스 레이어 설정
        layer.addSublayer(progressLayer)
        progressLayer.strokeColor = AppColor.oxfordBlue.cgColor
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineWidth = lineWidth
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = 0
    }

    private func setupPercentageLabel() {
        addSubview(percentageLabel)
        percentageLabel.font = .systemFont(ofSize: 10, weight: .bold)
        percentageLabel.textColor = .darkGray
        percentageLabel.textAlignment = .center
        updatePercentageLabel()

        // SnapKit을 사용하지 않은 기본 Auto Layout
        percentageLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            percentageLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            percentageLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
    }
    
    private func updateCircularPath() {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = (min(bounds.width, bounds.height) - lineWidth) / 2
        let startAngle = -CGFloat.pi / 2
        let endAngle = startAngle + (2 * CGFloat.pi)
        
        let circularPath = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: true
        )
        
        trackLayer.path = circularPath.cgPath
        progressLayer.path = circularPath.cgPath
    }

    private func updatePercentageLabel() {
        percentageLabel.text = String(format: "%.0f%%", progress * 100)
    }
}
