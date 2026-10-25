@MainActor
public final class QuizSession {
    private let provider: CountryProvider
    private let questionFactory: QuestionFactory
    private let scoring: Scoring
    
    public init(
        provider: CountryProvider,
        questionFactory: QuestionFactory,
        scoring: Scoring
    ) {
        self.provider = provider
        self.questionFactory = questionFactory
        self.scoring = scoring
    }

    public func start(mode: QuizMode) async {
        let provider = provider
        let countries = await withTaskGroup(of: (Int, Country?).self, returning: [Country].self) { group in
            // naive impl
//            for (index, code) in mode.countryCodes.enumerated() {
//                group.addTask {
//                    let country = try? await provider.country(code: code)
//                    return (index, country)
//                }
//            }
//            
//            var loaded: [Country?] = Array(repeating: nil, count: mode.countryCodes.count)
//            for await (index, country) in group {
//                loaded[index] = country
//            }
//            return loaded.compactMap { $0 }
            
            // cool impl
            var codesIterator = mode.countryCodes.enumerated().makeIterator()
            for _ in 0..<3 {
                guard let next = codesIterator.next() else { continue }
                group.addTask {
                    let country = try? await provider.country(code: next.element)
                    return (next.offset, country)
                }
            }
            
            var loaded: [Country?] = Array(repeating: nil, count: mode.countryCodes.count)
            while let (index, country) = await group.next() {
                loaded[index] = country
                if let next = codesIterator.next() {
                    group.addTask {
                        let country = try? await provider.country(code: next.element)
                        return (next.offset, country)
                    }
                }
            }
            return loaded.compactMap { $0 }
        }
    }

    public func answer(_ option: AnswerOption) -> AnswerResult {
        fatalError("todo")
    }

    public var currentQuestion: Question? {
        nil
    }

    public var result: QuizResult {
        QuizResult()
    }
}
