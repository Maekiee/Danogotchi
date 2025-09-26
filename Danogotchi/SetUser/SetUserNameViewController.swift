
import UIKit

class SetUserNameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .green
        ApiService.searchPhoto(api: .searchPhoto(word: "car", page: 1), type: SearchPhotoDTO.self) { response in
            print(response)
        }

        
    }
    

  

}
