# Adapter + Facade

Мини-задание (пет-проект, около 40–60 минут).

Запуск тестов:

```bash
swift test
```

## Часть 1. Adapter

Есть сторонний сервис с колбэком, менять его нельзя (`Sources/AdapterFacade/Legacy`):

```swift
final class LegacyGeoService {
    /// Может вызвать completion дважды: сначала из кеша, потом из сети.
    /// Возвращает токен, которым запрос можно отменить.
    @discardableResult
    func fetch(code: String,
               completion: @escaping ([String: Any]?, Error?) -> Void) -> Cancellable { ... }
}

protocol Cancellable { func cancel() }
```

Контракт:

```swift
enum GeoError: Error {
    case notFound
    case invalidData
    case network(underlying: Error)
    case cancelled
}

protocol CountryProvider: Sendable {
    func country(code: String) async throws(GeoError) -> Country
}
```

Напиши `LegacyGeoServiceAdapter: CountryProvider`.

Требования:

1. Сделай композицию, а не `extension LegacyGeoService: CountryProvider` (вспомни вопрос 3).
2. Используй continuation, и `resume` вызывается ровно один раз, даже если `completion` прилетел дважды.
3. Поддержи отмену: `withTaskCancellationHandler`, отмена реального запроса через `Cancellable`. Гонку между `onCancel` и `resume` защити через `Mutex` или `OSAllocatedUnfairLock`.
4. Ошибка типизированная (`throws(GeoError)`). Подсказка: `withCheckedContinuation` + `Result`.
5. Маппинг `[String: Any]` → `Country` вынеси в отдельную чистую функцию, её удобно тестировать.

Примечание: `LegacyGeoService` — `final`, подклассом в тестах его не подменить.

## Часть 2. Facade

`QuizSession` — единая точка входа для экрана квиза:

```swift
@MainActor
final class QuizSession {
    init(provider: CountryProvider, questionFactory: QuestionFactory, scoring: Scoring)

    func start(mode: QuizMode) async
    func answer(_ option: AnswerOption) -> AnswerResult
    var currentQuestion: Question? { get }
    var result: QuizResult { get }
}
```

Требования:

* Экран знает только про `QuizSession`. Ни `CountryProvider`, ни фабрика наружу не торчат (Law of Demeter).
* Зависимости приходят через `init`, без синглтонов.

`QuestionFactory`, `Scoring` и модели квиза уже есть в `Sources/AdapterFacade/Quiz`.

## Часть 3. Тесты (Swift Testing)

1. Адаптер: `completion` вызвался дважды → краша нет, вернулось первое значение.
2. Адаптер: таск отменили → вернулся `GeoError.cancelled`, у `Cancellable` вызвался `cancel()`.
3. Маппинг: параметризованный тест на валидный словарь, словарь без обязательных полей и пустой словарь.
4. Фасад: `QuizSession` с мок-`CountryProvider` → после `start` есть вопрос, после правильного ответа счёт +1.

## Готово, когда

* Код и тесты лежат в пет-проекте, все тесты зелёные.
* В шпаргалке IOS-460 есть строки про Adapter, Facade и `@retroactive`.
* Код отправлен на ревью.
