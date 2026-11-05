#if PART2
import Testing
@testable import FeatureToggles

@Suite("Часть 2. Провайдеры")
struct Part2ProviderTests {

    // MARK: - InMemoryFlagProvider

    @Test func emptyProviderHasNoValue() {
        #expect(InMemoryFlagProvider().value(for: Flags.newCheckout) == nil)
    }

    @Test func readsRawValueAsTyped() {
        let provider = InMemoryFlagProvider(raw: [
            "theme": .string("dark"),
            "allowed_tiers": .array([.int(1)]),
        ])

        #expect(provider.value(for: Flags.theme) == .dark)
        #expect(provider.value(for: Flags.allowedTiers) == [.pro])
    }

    @Test func wrongTypeIsNil() {
        let provider = InMemoryFlagProvider(raw: ["max_retries": .string("many")])

        #expect(provider.value(for: Flags.maxRetries) == nil)
    }

    @Test func setStoresTypedValue() {
        var provider = InMemoryFlagProvider()
        provider.set(Theme.dark, for: Flags.theme)
        provider.set([.pro], for: Flags.allowedTiers)

        #expect(provider.value(for: Flags.theme) == .dark)
        #expect(provider.value(for: Flags.allowedTiers) == [.pro])
    }

    @Test func setNilRemovesValue() {
        var provider = InMemoryFlagProvider(raw: ["max_retries": .int(5)])
        provider.set(nil, for: Flags.maxRetries)

        #expect(provider.value(for: Flags.maxRetries) == nil)
    }

    // MARK: - FallbackProvider

    @Test func primaryWins() {
        let primary = InMemoryFlagProvider(raw: ["max_retries": .int(1)])
        let fallback = InMemoryFlagProvider(raw: ["max_retries": .int(2)])

        #expect(primary.fallback(to: fallback).value(for: Flags.maxRetries) == 1)
    }

    @Test func missingValueComesFromFallback() {
        let fallback = InMemoryFlagProvider(raw: ["max_retries": .int(2)])

        #expect(InMemoryFlagProvider().fallback(to: fallback).value(for: Flags.maxRetries) == 2)
    }

    @Test func garbageInPrimaryComesFromFallback() {
        let primary = InMemoryFlagProvider(raw: ["max_retries": .string("garbage")])
        let fallback = InMemoryFlagProvider(raw: ["max_retries": .int(2)])

        #expect(primary.fallback(to: fallback).value(for: Flags.maxRetries) == 2)
    }

    @Test func noValueAnywhereIsNil() {
        let chain = InMemoryFlagProvider().fallback(to: InMemoryFlagProvider())

        #expect(chain.value(for: Flags.maxRetries) == nil)
    }

    @Test func chainKeepsFullStaticType() {
        let a = InMemoryFlagProvider()
        let b = ConstantProvider(raw: .int(1))
        let c = InMemoryFlagProvider(raw: ["title": .string("c")])

        let chain: FallbackProvider<
            FallbackProvider<InMemoryFlagProvider, ConstantProvider>,
            InMemoryFlagProvider
        > = a.fallback(to: b).fallback(to: c)

        #expect(chain.value(for: Flags.maxRetries) == 1)
        #expect(chain.value(for: Flags.title) == "c")
    }

    @Test func fallbackWorksFromAnyProvider() {
        let chain = ConstantProvider(raw: .int(1))
            .fallback(to: InMemoryFlagProvider(raw: ["title": .string("x")]))

        #expect(chain.value(for: Flags.maxRetries) == 1)
        #expect(chain.value(for: Flags.title) == "x")
    }

    @Test func worksThroughExistential() {
        let providers: [any FlagProvider] = [
            InMemoryFlagProvider(raw: ["max_retries": .int(1)]),
            ConstantProvider(raw: .int(2)),
        ]

        #expect(providers.map { $0.value(for: Flags.maxRetries) } == [1, 2])
    }
}
#endif
