public protocol QuestionFactory: Sendable {
    func makeQuestions(from countries: [Country]) -> [Question]
}

public protocol Scoring: Sendable {
    func points(for result: AnswerResult) -> Int
}

public struct CapitalQuestionFactory: QuestionFactory {
    public init() {}

    public func makeQuestions(from countries: [Country]) -> [Question] {
        countries.map { country in
            Question(
                prompt: "Столица \(country.name)?",
                options: countries.map { AnswerOption(id: $0.code, title: $0.capital) },
                correctOptionID: country.code
            )
        }
    }
}

public struct OnePointScoring: Scoring {
    public init() {}

    public func points(for result: AnswerResult) -> Int {
        result == .correct ? 1 : 0
    }
}
