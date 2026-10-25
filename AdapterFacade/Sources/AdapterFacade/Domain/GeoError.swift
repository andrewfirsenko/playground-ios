public enum GeoError: Error {
    case notFound
    case invalidData
    case network(underlying: Error)
    case cancelled
}
