public protocol CountryProvider: Sendable {
    func country(code: String) async throws(GeoError) -> Country
}
