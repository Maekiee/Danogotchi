import Foundation

protocol ExperienceRepository {
    /// 포인트를 적립하고 적립 후 누적값을 반환한다
    func addPoint(_ amount: Int) -> Int
}
