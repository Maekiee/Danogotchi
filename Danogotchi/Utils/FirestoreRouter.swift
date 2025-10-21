import Foundation
import FirebaseFirestore

enum FirestoreRouter {
    case fetchCollection(name: String, limit: Int?)
    case fetchDocument(collection: String, documentId: String)
    case queryCollection(name: String, field: String, value: Any, limit: Int?)
    
    var collectionRef: CollectionReference {
        let db = Firestore.firestore()
        switch self {
        case .fetchCollection(name: let name, _),
             .queryCollection(name: let name, _, _, _):
            return db.collection(name)
        case .fetchDocument(collection: let name, _):
            return db.collection(name)
        }
    }
    
    func buildQuery() -> Query {
        switch self {
        case .fetchCollection(_, let limit):
            var query: Query = collectionRef
            if let limit = limit {
                query = query.limit(to: limit)
            }
            return query
            
        case .queryCollection(_, let field, let value, let limit):
            var query: Query = collectionRef.whereField(field, isEqualTo: value)
            if let limit = limit {
                query = query.limit(to: limit)
            }
            return query
            
        case .fetchDocument:
            return collectionRef
        }
    }
    
    var documentId: String? {
        switch self {
        case .fetchDocument(_, let id):
            return id
        default:
            return nil
        }
    }
}
