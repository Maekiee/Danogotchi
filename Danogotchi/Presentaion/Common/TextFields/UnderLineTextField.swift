import UIKit
import SnapKit

final class UnderlineTextField: UIView {
    private let textField = UITextField()
    private let underlineView = UIView()
    private let titleLabel = UILabel()
    
    // TextField 접근을 위한 프로퍼티
    var text: String? {
        get { textField.text }
        set { textField.text = newValue }
    }
    
    var placeholder: String? {
        get { textField.placeholder }
        set { textField.placeholder = newValue }
    }
    
    var isSecureTextEntry: Bool {
        get { textField.isSecureTextEntry }
        set { textField.isSecureTextEntry = newValue }
    }
    
    var font: UIFont? {
        get { textField.font }
        set { textField.font = newValue }
    }
    
    var title: String? {
        get { titleLabel.text }
        set {
            titleLabel.text = newValue
            titleLabel.isHidden = newValue == nil || newValue?.isEmpty == true
            updateTextFieldConstraints()
        }
    }
    
    var titleFont: UIFont? {
        get { titleLabel.font }
        set { titleLabel.font = newValue }
    }
    
    var titleColor: UIColor? {
        get { titleLabel.textColor }
        set { titleLabel.textColor = newValue }
    }
    
    // RxSwift용 textField 접근
    var tf: UITextField {
        return textField
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    convenience init(placeholder: String) {
        self.init(frame: .zero)
        self.placeholder = placeholder
    }
    
    convenience init(placeholder: String, fontSize: CGFloat, weight: UIFont.Weight) {
        self.init(frame: .zero)
        self.placeholder = placeholder
        self.font = .systemFont(ofSize: fontSize, weight: weight)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 타이틀과 함께 초기화하는 convenience init 추가
    convenience init(title: String, placeholder: String) {
        self.init(frame: .zero)
        self.title = title
        self.placeholder = placeholder
    }
    
    convenience init(title: String, placeholder: String, fontSize: CGFloat, weight: UIFont.Weight) {
        self.init(frame: .zero)
        self.title = title
        self.placeholder = placeholder
        self.font = .systemFont(ofSize: fontSize, weight: weight)
    }
    
    private func setupUI() {
        // TextField 설정
        textField.borderStyle = .none
        textField.autocapitalizationType = .none
        textField.textColor = .label
        textField.font = .systemFont(ofSize: 20, weight: .semibold)
        
        textField.backgroundColor = AppColor.appWhite // 배경색을 회색으로 설정
        textField.layer.cornerRadius = 20 // 모서리를 둥글게
        
        // 텍스트 필드에 좌우 패딩 추가
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        textField.leftViewMode = .always
        textField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        textField.rightViewMode = .always
        
        // Underline 설정
//        underlineView.backgroundColor = .systemGray3
        
        // Title Label 설정
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .black//.secondaryLabel
        titleLabel.isHidden = true // 기본적으로 숨김
        
        // 뷰 추가
        addSubview(titleLabel)
        addSubview(textField)
        addSubview(underlineView)
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.horizontalEdges.equalToSuperview().inset(4)
        }
        
        // AutoLayout 설정
        textField.snp.makeConstraints { make in
            make.horizontalEdges.top.equalToSuperview()
            if titleLabel.isHidden {
                make.top.equalToSuperview()
            } else {
                make.top.equalTo(titleLabel.snp.bottom).offset(4)
            }
        }
        
        underlineView.snp.makeConstraints { make in
            make.top.equalTo(textField.snp.bottom).offset(4)
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(2)
            make.bottom.equalToSuperview()
        }
    }
    
    private func updateTextFieldConstraints() {
        // 타이틀 라벨 표시/숨김에 따라 TextField 제약조건 업데이트
        textField.snp.remakeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            if titleLabel.isHidden {
                make.top.equalToSuperview()
            } else {
                make.top.equalTo(titleLabel.snp.bottom).offset(8)
            }
        }
    }
    
    // 폰트 설정 메서드
    func setFont(size: CGFloat, weight: UIFont.Weight) {
        textField.font = .systemFont(ofSize: size, weight: weight)
    }
    
    // 타이틀 폰트 설정 메서드
    func setTitleFont(size: CGFloat, weight: UIFont.Weight) {
        titleLabel.font = .systemFont(ofSize: size, weight: weight)
    }
    
    // 포커스 상태에 따른 언더라인 색상 변경
    func setFocused(_ focused: Bool) {
        UIView.animate(withDuration: 0.2) {
            self.underlineView.backgroundColor = focused ? .systemGreen : .systemGray3
        }
    }
    
    // 에러 상태 표시
    func setError(_ hasError: Bool) {
        UIView.animate(withDuration: 0.2) {
            self.underlineView.backgroundColor = hasError ? .systemRed : .systemGray3
        }
    }
    
    // 타이틀 표시/숨김 메서드
    func showTitle(_ show: Bool, animated: Bool = true) {
        if animated {
            UIView.animate(withDuration: 0.3) {
                self.titleLabel.isHidden = !show
                self.updateConstraints()
                self.layoutIfNeeded()
            }
        } else {
            titleLabel.isHidden = !show
            updateConstraints()
        }
    }
}
