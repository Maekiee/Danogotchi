import Foundation

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
