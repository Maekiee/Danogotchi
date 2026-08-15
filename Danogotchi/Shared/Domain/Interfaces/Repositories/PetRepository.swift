import Foundation

protocol PetRepository {
    func createPet(_ pet: Pet) -> Pet?
    func readPet() -> Pet?
    func updatePet(_ pet: Pet)
    func addExperience(_ amount: Int) -> Int?
}
