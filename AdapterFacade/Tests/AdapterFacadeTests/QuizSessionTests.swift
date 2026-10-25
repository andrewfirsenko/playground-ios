import Testing
@testable import AdapterFacade

@MainActor
@Suite("QuizSession")
struct QuizSessionTests {
    @Test("после start есть вопрос, после правильного ответа счёт +1")
    func startAndAnswer() async {
        Issue.record("TODO")
    }
}
