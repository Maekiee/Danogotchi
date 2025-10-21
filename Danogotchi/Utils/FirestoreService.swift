import Foundation
import FirebaseFirestore
import RxSwift
import RxCocoa

enum FirestoreService {
    
    // 컬렉션 또는 쿼리 조회
    static func fetchDocuments<T: Decodable>(router: FirestoreRouter, type: T.Type) -> Single<Result<[T], Error>> {
        return Single.create { observer in
            let query = router.buildQuery()
            
            query.getDocuments { snapshot, error in
                if let error = error {
                    print("Firestore 에러: \(error)")
                    observer(.success(.failure(error)))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    observer(.success(.success([])))
                    return
                }
                
                do {
                    let results = try documents.compactMap { doc -> T? in
                        let data = doc.data()
                        let jsonData = try JSONSerialization.data(withJSONObject: data)
                        return try JSONDecoder().decode(T.self, from: jsonData)
                    }
                    print("Firestore 성공>> \(results)")
                    observer(.success(.success(results)))
                } catch {
                    print("Firestore 디코딩 에러: \(error)")
                    observer(.success(.failure(error)))
                }
            }
            
            return Disposables.create()
        }
    }
    
    // 단일 문서 조회
    static func fetchDocument<T: Decodable>(router: FirestoreRouter, type: T.Type) -> Single<Result<T, Error>> {
        return Single.create { observer in
            guard let documentId = router.documentId else {
                observer(.success(.failure(NSError(domain: "FirestoreService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Document ID 필요"]))))
                return Disposables.create()
            }
            
            router.collectionRef.document(documentId).getDocument { snapshot, error in
                if let error = error {
                    print("Firestore 에러: \(error)")
                    observer(.success(.failure(error)))
                    return
                }
                
                guard let data = snapshot?.data() else {
                    observer(.success(.failure(NSError(domain: "FirestoreService", code: -1, userInfo: [NSLocalizedDescriptionKey: "문서가 존재하지 않음"]))))
                    return
                }
                
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: data)
                    let result = try JSONDecoder().decode(T.self, from: jsonData)
                    print("Firestore 성공>> \(result)")
                    observer(.success(.success(result)))
                } catch {
                    print("Firestore 디코딩 에러: \(error)")
                    observer(.success(.failure(error)))
                }
            }
            
            return Disposables.create()
        }
    }
    
    // 실시간 리스너 (Observable)
    static func observeDocuments<T: Decodable>(router: FirestoreRouter, type: T.Type) -> Observable<Result<[T], Error>> {
        return Observable.create { observer in
            let query = router.buildQuery()
            
            let listener = query.addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Firestore 리스너 에러: \(error)")
                    observer.onNext(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    observer.onNext(.success([]))
                    return
                }
                
                do {
                    let results = try documents.compactMap { doc -> T? in
                        let data = doc.data()
                        let jsonData = try JSONSerialization.data(withJSONObject: data)
                        return try JSONDecoder().decode(T.self, from: jsonData)
                    }
                    observer.onNext(.success(results))
                } catch {
                    print("Firestore 디코딩 에러: \(error)")
                    observer.onNext(.failure(error))
                }
            }
            
            return Disposables.create {
                listener.remove()
            }
        }
    }
}
