import Foundation

final class LibraryDIContainer {
    private let dependencies: AppDependencies

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
    }

    func makeLibraryViewModel() -> LibraryViewModel {
        return LibraryViewModel(
            fetchVocabBooksUseCase: DefaultFetchVocabBooksUseCase(
                vocabBookRepository: dependencies.vocabBookRepository,
                remoteVocabBookRepository: dependencies.makeRemoteVocabBookRepository()
            ),
            reportError: dependencies.reportError
        )
    }

    func makeVocabDetailViewModel(key: VocabBookKey) -> VocabBookDetailViewModel {
        return VocabBookDetailViewModel(
            key: key,
            fetchVocabsUseCase: dependencies.makeFetchVocabsUseCase(),
            toggleSaveVocabUseCase: dependencies.makeToggleSaveVocabUseCase(),
            deleteVocabUseCase: DefaultDeleteVocabUseCase(vocabRepository: dependencies.makeVocabRepository()),
            setActiveBookUseCase: dependencies.makeSetActiveBookUseCase(),
            isActiveBookUseCase: DefaultIsActiveBookUseCase(vocabBookRepository: dependencies.vocabBookRepository),
            reportError: dependencies.reportError
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
