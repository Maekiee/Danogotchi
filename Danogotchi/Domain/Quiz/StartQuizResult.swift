import Foundation

enum StartQuizResult {
    case success(QuizData)
    /// 학습중 단어장이 없거나 단어가 0개
    case noWords
    /// 4지선다 보기 구성을 위해 최소 4개 필요
    case notEnoughWords
}
