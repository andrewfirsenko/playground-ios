public enum QuizMode: Sendable {
    case europe

    var countryCodes: [String] {
        switch self {
        case .europe: ["FR", "DE", "IT", "ES"]
        }
    }
}

public struct AnswerOption: Sendable, Equatable, Identifiable {
    public let id: String
    public let title: String

    public init(id: String, title: String) {
        self.id = id
        self.title = title
    }
}

public struct Question: Sendable, Equatable {
    public let prompt: String
    public let options: [AnswerOption]
    public let correctOptionID: AnswerOption.ID

    public init(prompt: String, options: [AnswerOption], correctOptionID: AnswerOption.ID) {
        self.prompt = prompt
        self.options = options
        self.correctOptionID = correctOptionID
    }
}

public enum AnswerResult: Sendable, Equatable {
    case correct
    case incorrect(correctOptionID: AnswerOption.ID)
}

public struct QuizResult: Sendable, Equatable {
    public var score: Int
    public var answered: Int
    public var total: Int

    public init(score: Int = 0, answered: Int = 0, total: Int = 0) {
        self.score = score
        self.answered = answered
        self.total = total
    }
}
