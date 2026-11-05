#if PART3
import Testing
@testable import FeatureToggles

private func makeService(
    _ raw: [String: RawFlagValue] = [:]
) -> FeatureToggleService<InMemoryFlagProvider> {
    FeatureToggleService(provider: InMemoryFlagProvider(raw: raw))
}

@Suite("Часть 3. FeatureToggleService: чтение")
struct Part3ValueTests {

    @Test func returnsDefaultWhenNothingIsSet() async {
        #expect(await makeService().value(of: Flags.theme) == .light)
    }

    @Test func providerBeatsDefault() async {
        let service = makeService(["theme": .string("dark")])

        #expect(await service.value(of: Flags.theme) == .dark)
    }

    @Test func garbageFallsBackToDefault() async {
        let service = makeService([
            "theme": .string("sepia"),
            "max_retries": .string("many"),
        ])

        #expect(await service.value(of: Flags.theme) == .light)
        #expect(await service.value(of: Flags.maxRetries) == 3)
    }

    @Test func overrideBeatsProvider() async {
        let service = makeService(["max_retries": .int(5)])
        await service.setOverride(9, for: Flags.maxRetries)

        #expect(await service.value(of: Flags.maxRetries) == 9)
    }

    @Test func nilRemovesOverride() async {
        let service = makeService(["max_retries": .int(5)])
        await service.setOverride(9, for: Flags.maxRetries)
        await service.setOverride(nil, for: Flags.maxRetries)

        #expect(await service.value(of: Flags.maxRetries) == 5)
    }

    @Test func sameKeyWithDifferentTypesDoesNotConflict() async {
        let asBool = FeatureFlag("shared", default: false)
        let asInt = FeatureFlag("shared", default: 42)
        let service = makeService()
        await service.setOverride(true, for: asBool)

        #expect(await service.value(of: asBool) == true)
        #expect(await service.value(of: asInt) == 42)
    }

    @Test func overrideOfOtherTypeFallsThroughToProvider() async {
        let asBool = FeatureFlag("shared", default: false)
        let asInt = FeatureFlag("shared", default: 42)
        let service = makeService(["shared": .int(7)])
        await service.setOverride(true, for: asBool)

        #expect(await service.value(of: asInt) == 7)
    }

    @Test func setProviderReplacesValues() async {
        let service = makeService(["max_retries": .int(5)])
        await service.setProvider(InMemoryFlagProvider(raw: ["max_retries": .int(6)]))

        #expect(await service.value(of: Flags.maxRetries) == 6)
    }

    @Test func setProviderKeepsOverrides() async {
        let service = makeService()
        await service.setOverride(9, for: Flags.maxRetries)
        await service.setProvider(InMemoryFlagProvider(raw: ["max_retries": .int(6)]))

        #expect(await service.value(of: Flags.maxRetries) == 9)
    }

    @Test func worksWithComposedProvider() async {
        let remote = InMemoryFlagProvider(raw: ["max_retries": .string("garbage")])
        let local = InMemoryFlagProvider(raw: ["max_retries": .int(2)])
        let service = FeatureToggleService(provider: remote.fallback(to: local))

        #expect(await service.value(of: Flags.maxRetries) == 2)
    }
}

@Suite("Часть 3. FeatureToggleService: подписки")
struct Part3UpdatesTests {

    @Test func emitsCurrentValueImmediately() async {
        let service = makeService(["max_retries": .int(5)])
        let stream = await service.updates(of: Flags.maxRetries)

        #expect(await drain(stream) == [5])
    }

    @Test func emitsOnOverride() async {
        let service = makeService()
        let stream = await service.updates(of: Flags.maxRetries)
        await service.setOverride(4, for: Flags.maxRetries)
        await service.setOverride(nil, for: Flags.maxRetries)

        #expect(await drain(stream) == [3, 4, 3])
    }

    @Test func skipsWritesThatChangeNothing() async {
        let service = makeService(["max_retries": .int(5)])
        let stream = await service.updates(of: Flags.maxRetries)
        await service.setOverride(5, for: Flags.maxRetries)
        await service.setOverride(6, for: Flags.maxRetries)
        await service.setOverride(6, for: Flags.maxRetries)

        #expect(await drain(stream) == [5, 6])
    }

    @Test func emitsOnSetProvider() async {
        let service = makeService()
        let stream = await service.updates(of: Flags.theme)
        await service.setProvider(InMemoryFlagProvider(raw: ["theme": .string("dark")]))

        #expect(await drain(stream) == [.light, .dark])
    }

    @Test func setProviderNotifiesOnlyChangedFlags() async {
        let service = makeService(["max_retries": .int(5), "title": .string("a")])
        let retries = await service.updates(of: Flags.maxRetries)
        let titles = await service.updates(of: Flags.title)
        await service.setProvider(InMemoryFlagProvider(raw: [
            "max_retries": .int(5),
            "title": .string("b"),
        ]))

        #expect(await drain(retries) == [5])
        #expect(await drain(titles) == ["a", "b"])
    }

    @Test func overrideDoesNotNotifyOtherFlags() async {
        let service = makeService()
        let titles = await service.updates(of: Flags.title)
        await service.setOverride(true, for: Flags.newCheckout)

        #expect(await drain(titles) == ["Hello"])
    }

    @Test func subscribersOfDifferentTypesCoexist() async {
        let service = makeService()
        let bools = await service.updates(of: Flags.newCheckout)
        let themes = await service.updates(of: Flags.theme)
        let tiers = await service.updates(of: Flags.allowedTiers)
        await service.setOverride(true, for: Flags.newCheckout)
        await service.setOverride(.dark, for: Flags.theme)
        await service.setOverride([.pro], for: Flags.allowedTiers)

        #expect(await drain(bools) == [false, true])
        #expect(await drain(themes) == [.light, .dark])
        #expect(await drain(tiers) == [[.free], [.pro]])
    }

    @Test func severalSubscribersOfOneFlagAllReceive() async {
        let service = makeService()
        let first = await service.updates(of: Flags.maxRetries)
        let second = await service.updates(of: Flags.maxRetries)
        await service.setOverride(4, for: Flags.maxRetries)

        #expect(await drain(first) == [3, 4])
        #expect(await drain(second) == [3, 4])
    }

    @Test func lateSubscriberStartsFromCurrentValue() async {
        let service = makeService()
        await service.setOverride(4, for: Flags.maxRetries)
        let stream = await service.updates(of: Flags.maxRetries)

        #expect(await drain(stream) == [4])
    }
}
#endif
