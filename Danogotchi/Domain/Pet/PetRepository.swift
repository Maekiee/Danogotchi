import Foundation

protocol PetRepository {
    func createPet(_ pet: Pet) throws -> Pet?
    func readPet() throws -> Pet?
    func updatePet(_ pet: Pet) throws
    func addExperience(_ amount: Int) throws -> Int?
}
