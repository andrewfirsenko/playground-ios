import Testing
@testable import AdapterFacade

@Suite("LegacyGeoServiceAdapter")
struct LegacyGeoServiceAdapterTests {
    @Test("completion вызван дважды: краша нет, вернулось первое значение")
    func completionCalledTwice() async throws {
        Issue.record("TODO")
    }

    @Test("таск отменён: GeoError.cancelled и cancel() у Cancellable")
    func cancellation() async throws {
        Issue.record("TODO")
    }
}
