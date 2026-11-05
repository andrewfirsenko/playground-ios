#if BONUS
import Testing
@testable import FeatureToggles

@Suite("Бонус")
struct BonusTests {

    @Test func readsSeveralFlagsWithTheirTypes() async {
        let service = FeatureToggleService(provider: InMemoryFlagProvider(raw: ["theme": .string("dark")]))
        await service.setOverride(true, for: Flags.newCheckout)

        let result: (Bool, Int, Theme) = await service.values(
            of: Flags.newCheckout,
            Flags.maxRetries,
            Flags.theme
        )

        #expect(result.0 == true)
        #expect(result.1 == 3)
        #expect(result.2 == .dark)
    }

    @Test func finishedSubscriptionIsRemoved() async throws {
        let service = FeatureToggleService(provider: InMemoryFlagProvider())
        let finished = await service.updates(of: Flags.maxRetries)
        let alive = await service.updates(of: Flags.theme)
        #expect(await service.subscriberCount == 2)

        _ = await drain(finished)

        var remaining = await service.subscriberCount
        for _ in 0..<100 where remaining != 1 {
            try await Task.sleep(for: .milliseconds(10))
            remaining = await service.subscriberCount
        }
        #expect(remaining == 1)
        withExtendedLifetime(alive) {}
    }
}
#endif
