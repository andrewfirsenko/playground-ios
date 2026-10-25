@MainActor
public final class QuizSession {
    public init(provider: CountryProvider, questionFactory: QuestionFactory, scoring: Scoring) {
    }

    public func start(mode: QuizMode) async {
    }

    public func answer(_ option: AnswerOption) -> AnswerResult {
        fatalError("TODO")
    }

    public var currentQuestion: Question? {
        nil
    }

    public var result: QuizResult {
        QuizResult()
    }
}
