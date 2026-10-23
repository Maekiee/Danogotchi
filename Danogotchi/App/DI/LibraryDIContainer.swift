import Foundation

final class LibraryDIContainer {
    private let dependencies: AppDependencies

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
    }

    func makeLibraryViewModel() -> LibraryViewModel {
        return LibraryViewModel(
            fetchVocabBooksUseCase: DefaultFetchVocabBooksUseCase(vocabBookRepository: dependencies.vocabBookRepository)
        )
    }

    func makeVocabDetailViewModel(topic: BookTopic) -> VocabBookDetailViewModel {
        return VocabBookDetailViewModel(
            topic: topic,
            fetchVocabsUseCase: dependencies.makeFetchVocabsUseCase(),
            toggleSaveVocabUseCase: dependencies.makeToggleSaveVocabUseCase(),
            deleteVocabUseCase: DefaultDeleteVocabUseCase(vocabRepository: dependencies.makeVocabRepository()),
            setActiveBookUseCase: dependencies.makeSetActiveBookUseCase(),
            isActiveBookUseCase: DefaultIsActiveBookUseCase(vocabBookRepository: dependencies.vocabBookRepository)
        )
    }

    func makeAddVocabViewModel(editingVocab: Vocab? = nil) -> AddVocabViewModel {
        return AddVocabViewModel(
            addVocabUseCase: DefaultAddVocabUseCase(vocabBookRepository: dependencies.vocabBookRepository),
            updateVocabUseCase: DefaultUpdateVocabUseCase(vocabRepository: dependencies.makeVocabRepository()),
            editingVocab: editingVocab
        )
    }
}
