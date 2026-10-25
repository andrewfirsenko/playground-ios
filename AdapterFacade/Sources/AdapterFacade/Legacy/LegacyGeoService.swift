import Foundation

// Сторонний сервис — менять его нельзя. Это заглушка, имитирующая его поведение:
// сначала ответ из кеша, затем (через 0.3 с) из сети. Итого completion вызывается дважды.

public protocol Cancellable {
    func cancel()
}

public final class LegacyGeoService {
    private static func lookup(_ code: String) -> [String: Any]? {
        let storage: [String: [String: Any]] = [
            "FR": ["code": "FR", "name": "France", "capital": "Paris"],
            "DE": ["code": "DE", "name": "Germany", "capital": "Berlin"],
            "IT": ["code": "IT", "name": "Italy", "capital": "Rome"],
            "ES": ["code": "ES", "name": "Spain", "capital": "Madrid"]
        ]
        return storage[code]
    }

    public init() {}

    /// Может вызвать completion дважды: сначала из кеша, потом из сети.
    /// Возвращает токен, которым запрос можно отменить.
    @discardableResult
    public func fetch(code: String,
                      completion: @escaping ([String: Any]?, Error?) -> Void) -> Cancellable {
        let token = Token()
        // Старый сервис не знает про Sendable — гасим диагностику, как это сделал бы его автор.
        nonisolated(unsafe) let result = Self.lookup(code)
        nonisolated(unsafe) let completion = completion

        DispatchQueue.global().async {
            guard !token.isCancelled else { return }
            completion(result, nil)
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.3) {
            guard !token.isCancelled else { return }
            completion(result, nil)
        }
        return token
    }

    private final class Token: Cancellable, @unchecked Sendable {
        private let lock = NSLock()
        private var cancelled = false

        var isCancelled: Bool { lock.withLock { cancelled } }
        func cancel() { lock.withLock { cancelled = true } }
    }
}
