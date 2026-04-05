import UIKit
import SnapKit

final class UIChip: UIView {
    
    private let label: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    init(text: String, backgroundColor: UIColor = UIColor.darkGray) {
        super.init(frame: .zero)
        
        self.backgroundColor = backgroundColor
        self.label.text = text
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(label)
        
        label.snp.makeConstraints { make in
            make.verticalEdges.equalToSuperview().inset(4)
            make.horizontalEdges.equalToSuperview().inset(8)
        }
    }
    
    // 외부에서 배경색 변경
    func setBackgroundColor(_ color: UIColor) {
        self.backgroundColor = color
    }
    
    // 외부에서 텍스트 변경
    func setText(_ text: String) {
        self.label.text = text
    }
    
    // 외부에서 텍스트 색상 변경
    func setTextColor(_ color: UIColor) {
        self.label.textColor = color
    }
    
    // 외부에서 폰트 변경
    func setFont(_ font: UIFont) {
        self.label.font = font
    }
}
