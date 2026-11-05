# FeatureToggles

Live coding, Senior+. Тема: generics. Constrained extensions, conditional conformance,
generic-требования в протоколе, статическая композиция типов, стирание типа через замыкания.

Время: **30 минут** на код. Отдельно: 2 минуты на вопросы перед стартом и 5 минут на устные вопросы в конце.

Запуск тестов:

```bash
swift test
```

Приёмочные тесты уже написаны и выключены. Закончил часть — раскомментируй её флаг
в `Package.swift` (`PART1`, `PART2`, `PART3`, `BONUS`). Тесты менять нельзя.

Весь код пиши в `Sources/FeatureToggles`. `public` не нужен, тесты используют `@testable import`.
`RawFlagValue` уже готов.

---

## Контекст

Флаги в приложении сейчас читаются так:

```swift
let enabled = config["new_checkout"] as? Bool ?? false
```

Опечатка в ключе, неверный тип и разные дефолты в разных местах находятся только в проде.
Нужен сервис, в котором тип значения и дефолт заданы один раз, в объявлении флага:

```swift
enum Flags {
    static let newCheckout = FeatureFlag("new_checkout", default: false)
    static let theme = FeatureFlag("theme", default: Theme.light)
}

let theme = await toggles.value(of: Flags.theme) // Theme, а не Any?
```

Значение берётся по приоритету: локальный override → провайдеры → дефолт флага.
Сервис не должен падать из-за того, что сервер прислал мусор.

## Перед стартом (2 мин, не входит в 30)

Задай вопросы, которые задал бы на настоящем интервью, и назови риски. Таймер запускай после этого.

## Часть 1. Значения и флаги (~10 мин)

**1.1. Протокол `FlagValue`.** `Sendable` и `Equatable`, требования ровно эти:

```swift
init?(rawFlag: RawFlagValue)
var rawFlag: RawFlagValue { get }
```

Конформят `Bool`, `Int`, `Double`, `String`. Типы строгие: `Int(rawFlag: .bool(true))` и
`Int(rawFlag: .double(1.5))` дают `nil`. Единственное исключение: `Double(rawFlag: .int(1)) == 1.0`,
потому что JSON часто присылает `1` вместо `1.0`.

**1.2. Enum без кода.** Эти объявления должны компилироваться без единой строки реализации `FlagValue`:

```swift
enum Theme: String, FlagValue { case light, dark }
enum Tier: Int, FlagValue { case free = 0, pro = 1 }
```

Неизвестный кейс (`"sepia"`) даёт `nil`.

**1.3. Массивы.** `[Element]` — это `FlagValue`, когда `Element` — `FlagValue`. В том числе `[[Int]]` и `[Theme]`.
Хотя бы один плохой элемент: весь массив `nil`.

**1.4. `FeatureFlag<Value>`.**

```swift
init(_ key: String, default defaultValue: Value)
let key: String
let defaultValue: Value
```

Должен работать `static let` из примера выше: Swift 6, strict concurrency.

## Часть 2. Провайдеры (~7 мин)

**2.1. Протокол `FlagProvider`.** `Sendable`, требование ровно одно:

```swift
func value<V: FlagValue>(for flag: FeatureFlag<V>) -> V?
```

`nil` значит «нет значения или оно не того типа».

**2.2. `InMemoryFlagProvider`.**

```swift
init(raw: [String: RawFlagValue] = [:])
mutating func set<V: FlagValue>(_ value: V?, for flag: FeatureFlag<V>) // nil удаляет
```

**2.3. `FallbackProvider<Primary, Fallback>`.** Сам `FlagProvider`. Спрашивает `Primary`, при `nil` спрашивает
`Fallback`. Значит, если в `Primary` лежит мусор, значение возьмётся из `Fallback`.

Цепочка собирается без `any`, полный тип сохраняется:

```swift
let chain: FallbackProvider<FallbackProvider<A, B>, C> = a.fallback(to: b).fallback(to: c)
```

`fallback(to:)` работает для любого `FlagProvider`, а не только для `InMemoryFlagProvider`.

## Часть 3. `FeatureToggleService` (~13 мин)

`actor FeatureToggleService<Provider: FlagProvider>`:

```swift
init(provider: Provider)
func value<V: FlagValue>(of flag: FeatureFlag<V>) -> V
func setOverride<V: FlagValue>(_ value: V?, for flag: FeatureFlag<V>) // nil снимает override
func setProvider(_ provider: Provider)                                // пришёл новый конфиг
func updates<V: FlagValue>(of flag: FeatureFlag<V>) -> AsyncStream<V>
```

* `value(of:)`: override → провайдер → `flag.defaultValue`.
* Два флага с одним ключом и разными типами не должны ломать друг друга. Override от
  `FeatureFlag<Bool>` не влияет на чтение `FeatureFlag<Int>` с тем же ключом: тот получает
  значение провайдера или дефолт.
* `updates(of:)`: сразу отдаёт текущее значение, затем только реальные изменения.
  Повторная запись того же значения ничего не отправляет. `setProvider`, не поменявший значение
  флага, его подписчикам ничего не отправляет.
* Подписчики на флаги разных типов живут в одном сервисе. На один флаг можно подписаться несколько раз.
* Без `@unchecked Sendable` и `nonisolated(unsafe)`.

## Бонус (если осталось время)

1. **Parameter packs.** Согласованный снимок нескольких флагов за один вызов:

   ```swift
   let (isEnabled, retries, theme) = await toggles.values(of: Flags.newCheckout, Flags.maxRetries, Flags.theme)
   ```

   Подсказка: кортеж из pack expansion компилятор не считает `Sendable`, даже если все `V` такие.
   Посмотри в сторону `sending`.

2. **Без утечек.** Завершённая подписка убирается из сервиса. Добавь `var subscriberCount: Int { get }`.

## Устные вопросы (после кода, ~5 мин)

**Generics**

1. Почему `FlagProvider` объявляет generic-метод, а не `associatedtype Value`? Что изменилось бы для
   `any FlagProvider` и для цепочки провайдеров?
2. Почему `extension RawRepresentable: FlagValue` не скомпилируется, а `extension FlagValue where Self: RawRepresentable`
   скомпилируется? Чем одно отличается от другого?
3. `static let` в теле `FeatureFlag` и в `extension FeatureFlag` не компилируется, а в
   `extension FeatureFlag where Value == Bool` на Swift 6.4 компилируется. Почему?
4. `FeatureToggleService<any FlagProvider>` не компилируется. Почему? Как спрятать длинный
   `FallbackProvider<…>` от клиентов? Получится ли написать `AnyFlagProvider` на замыканиях, как обычный
   type-erased wrapper? Чего цепочка без `any` стоит и что даёт?
5. Как ты сложил разнотипных подписчиков в одну коллекцию? Какая информация о типе потеряна и где
   она всё ещё есть?

**Проектирование**

6. Когда применять новый конфиг: сразу или на следующем запуске? Что будет, если флаг поменяется посреди
   checkout-флоу? Как подружить это с kill switch?
7. Как сделать раскатку на 5% пользователей, чтобы пользователь не прыгал между вариантами?
   Где считать бакет: на клиенте или на сервере?
8. Первый запуск без сети, истёкший кеш, битый ответ. Какое значение увидит пользователь в каждом случае?
9. Как считать exposure для A/B-теста? Почему логировать в `value(of:)` может быть плохой идеей?
10. Как находить и удалять мёртвые флаги?

## Готово, когда

* Флаги `PART1`–`PART3` включены, `swift test` зелёный. `BONUS` — по желанию.
* Нет предупреждений компилятора.
* Скажи «готово» — будет ревью с оценкой.
