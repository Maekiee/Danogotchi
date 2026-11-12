import FirebaseFirestore
import Foundation

/// 단어장 1권 = 문서 1개. `Firestore.firestore()`는 호출 시점에 꺼낸다 — 컨테이너 조립만으로 Firestore가 뜨지 않게
final class FirestoreVocabBookRepository {}

extension FirestoreVocabBookRepository: RemoteVocabBookRepository {
    func fetchBooks() async throws -> [RemoteVocabBook] {
        // 기본값은 오프라인이면 빈 캐시를 성공으로 돌려줘 화면이 다시 받지 않는다
        let snapshot = try await Firestore.firestore().collection("topics").getDocuments(source: .server)
        // 깨진 문서 하나가 목록 전체를 막지 않게 건너뛴다
        return snapshot.documents.compactMap { try? $0.data(as: TopicDTO.self).toDomain() }
    }

    func fetchVocabs(key: VocabBookKey) async throws -> [Vocab] {
        let dto = try await Firestore.firestore().collection("topicVocabs").document(key.id)
            .getDocument(as: TopicVocabsDTO.self)
        // 받을 때 앱 언어로 뜻을 고른다 — 이후 언어를 바꿔도 저장된 뜻은 유지
        return dto.toDomain(key: key, language: Bundle.main.preferredLocalizations.first, base: Date())
    }
}
