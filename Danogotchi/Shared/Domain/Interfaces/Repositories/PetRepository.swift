import Foundation

protocol PetRepository {
    /// 앱당 1마리 — 이미 있으면 만들지 않고 기존 펫을 돌려준다
    func createPet(_ pet: Pet) -> Pet
    func readPet() -> Pet?
    /// 정산·액션 결과를 한 번에 덮어쓴다
    func updatePet(_ pet: Pet)
    /// 경험치만 가산하고 적립 후 누적값을 돌려준다. 펫이 없으면 nil.
    func addExperience(_ amount: Int) -> Int?
}
