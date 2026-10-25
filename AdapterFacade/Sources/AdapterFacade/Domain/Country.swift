public struct Country: Sendable, Equatable {
    public let code: String
    public let name: String
    public let capital: String

    public init(code: String, name: String, capital: String) {
        self.code = code
        self.name = name
        self.capital = capital
    }
}
