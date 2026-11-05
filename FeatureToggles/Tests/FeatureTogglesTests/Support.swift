#if PART1
@testable import FeatureToggles

enum Theme: String, FlagValue {
    case light, dark
}

enum Tier: Int, FlagValue {
    case free = 0, pro = 1
}

/// `static let` здесь заодно проверяет, что `FeatureFlag` — `Sendable`.
enum Flags {
    static let newCheckout = FeatureFlag("new_checkout", default: false)
    static let maxRetries = FeatureFlag("max_retries", default: 3)
    static let timeout = FeatureFlag("timeout", default: 1.5)
    static let title = FeatureFlag("title", default: "Hello")
    static let theme = FeatureFlag("theme", default: Theme.light)
    static let allowedTiers = FeatureFlag<[Tier]>("allowed_tiers", default: [.free])
}
#endif

#if PART2
/// Сторонний провайдер: на любой ключ отвечает одним и тем же значением.
struct ConstantProvider: FlagProvider {
    let raw: RawFlagValue

    func value<V: FlagValue>(for flag: FeatureFlag<V>) -> V? {
        V(rawFlag: raw)
    }
}
#endif

#if PART3
/// Читает всё, что успело прийти за `timeout`. Сломанная реализация не повесит тесты.
func drain<V: Sendable>(
    _ stream: AsyncStream<V>,
    timeout: Duration = .milliseconds(150)
) async -> [V] {
    let consumer = Task {
        var received: [V] = []
        for await value in stream {
            received.append(value)
        }
        return received
    }
    let timer = Task {
        try? await Task.sleep(for: timeout)
        consumer.cancel()
    }
    let received = await consumer.value
    timer.cancel()
    return received
}
#endif
