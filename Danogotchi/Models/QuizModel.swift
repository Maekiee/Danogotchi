import Foundation


struct QuizData {
    let mode: QuizMode
    let words: [WordModel]
    let allWord: [WordModel]
    let startIndex: Int
    let sectionSize: Int? // 구간 학습일 때만 존재
    let isRestart: Bool //
}
