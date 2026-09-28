import Foundation

struct QuizSession: Equatable, Sendable, Identifiable {
    let id: UUID
    let startedAt: Date
    let questionCount: Int
}

struct QuizAnswer: Equatable, Sendable {
    let history: LearningHistory
    let session: QuizSession

    init(id: UUID = UUID(), word: Vocab, isCorrect: Bool, createAt: Date = Date(),
         session: QuizSession, questionIndex: Int) {
        self.session = session
        history = LearningHistory(
            id: id, vocabId: word.id, isCorrect: isCorrect, createAt: createAt,
            sourceWordIdSnapshot: word.sourceWordId,
            wordSnapshot: word.word, meaningSnapshot: word.meaning,
            topicSnapshot: word.studyTopic,
            partOfSpeechSnapshot: word.partOfSpeech?.rawValue,
            sessionId: session.id, questionIndex: questionIndex
        )
    }
}

enum StudyReportDataError: Error, Equatable, LocalizedError {
    case invalidRecord
    case conflictingAnswer
    case conflictingSession
    case invalidIdentifiers

    var errorDescription: String? {
        switch self {
        case .invalidRecord: return "학습 기록의 필수 정보가 올바르지 않아요."
        case .conflictingAnswer: return "이미 저장한 답변과 내용이 달라요."
        case .conflictingSession: return "이미 저장한 회차와 정보가 달라요."
        case .invalidIdentifiers: return "학습 기록에 없거나 중복된 ID가 있어요."
        }
    }
}
