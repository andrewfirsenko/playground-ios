final class LegacyGeoServiceAdapter: CountryProvider {
    func country(code: String) async throws(GeoError) -> Country {
        fatalError("TODO")
    }
}
