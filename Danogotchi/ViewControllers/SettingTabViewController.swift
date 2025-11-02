import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class SettingTabViewController: BaseViewController {
    private let disposeBag = DisposeBag()
    private let viewModel = SettingTabViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configHierarchy()
        configLayout()
        configView()
        bind()

    }
    
    override func configHierarchy() {
        
    }
    
    override func configLayout() {
        
    }
    
    override func configView() {
        view.backgroundColor = AppColor.backgroundBeige
    }

}

extension SettingTabViewController {
    private func bind() {
        let input = SettingTabViewModel.Input()
        let output = viewModel.transform(input: input)
    }
}
