import XCTest
@testable import Danogotchi

final class TopicVocabsDTOTests: XCTestCase {
    func test_wordsKeepServerIdAndOrderAndPickMeaningByLanguage() throws {
        let dto = try decodeWords()

        let korean = dto.toDomain(key: travelA1, language: "ko", base: testBase)
        let japanese = dto.toDomain(key: travelA1, language: "ja", base: testBase)
        let other = dto.toDomain(key: travelA1, language: "fr", base: testBase)

        XCTAssertEqual(korean.prefix(2).map(\.id.uuidString), [Self.airportId, Self.departId])
        XCTAssertEqual(korean.map(\.meaning), ["공항", "출발하다", "한국어만"])
        XCTAssertEqual(japanese.map(\.meaning), ["空港", "出発する"])
        // 지원하지 않는 언어는 한국어 뜻
        XCTAssertEqual(other.map(\.meaning), korean.map(\.meaning))
        XCTAssertEqual(korean.map(\.partOfSpeech), [.noun, .verb, nil])
        XCTAssertTrue(korean.allSatisfy { $0.bookType == .travel && $0.level == .a1 && $0.sourceWordId == nil })
        // createAt 정렬로 서버 순서를 지킨다
        XCTAssertEqual(korean.sorted { $0.createAt < $1.createAt }.map(\.word), ["airport", "depart", "koOnly"])
    }

    func test_wordWithInvalidIdOrMissingMeaningIsSkipped() throws {
        let dto = try decodeWords()

        XCTAssertEqual(dto.toDomain(key: travelA1, language: "ko", base: testBase).map(\.word), ["airport", "depart", "koOnly"])
        XCTAssertEqual(dto.toDomain(key: travelA1, language: "ja", base: testBase).map(\.word), ["airport", "depart"])
    }

    private static let airportId = "6F9619FF-8B86-D011-B42D-00C04FC964FF"
    private static let departId = "7F9619FF-8B86-D011-B42D-00C04FC964FF"

    private func decodeWords() throws -> TopicVocabsDTO {
        let json = """
        {"words": [
            {"id": "\(Self.airportId)", "word": "airport", "pos": "noun", "meaning": {"ko": "공항", "ja": "空港"}},
            {"id": "not-a-uuid", "word": "broken", "pos": "noun", "meaning": {"ko": "깨짐", "ja": "壊れ"}},
            {"id": "\(Self.departId)", "word": "depart", "pos": "verb", "meaning": {"ko": "출발하다", "ja": "出発する"}},
            {"id": "8F9619FF-8B86-D011-B42D-00C04FC964FF", "word": "koOnly", "meaning": {"ko": "한국어만"}}
        ]}
        """
        return try JSONDecoder().decode(TopicVocabsDTO.self, from: Data(json.utf8))
    }
}
