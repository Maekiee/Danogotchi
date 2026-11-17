import XCTest
@testable import Danogotchi

final class TopicDTOTests: XCTestCase {
    func test_topicDecodesAndUnknownTopicOrLevelIsExcluded() throws {
        let json = """
        [
            {"topic": "travel", "level": "A1", "order": 0, "wordCount": 549},
            {"topic": "music", "level": "A1", "order": 1, "wordCount": 10},
            {"topic": "life", "level": "Z9", "order": 2, "wordCount": 10},
            {"topic": "myBook", "level": "A1", "order": 3, "wordCount": 10}
        ]
        """
        let dtos = try JSONDecoder().decode([TopicDTO].self, from: Data(json.utf8))

        XCTAssertEqual(dtos.compactMap { $0.toDomain() }, [RemoteVocabBook(key: travelA1, wordCount: 549, order: 0)])
    }
}
