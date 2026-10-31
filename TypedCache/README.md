# TypedCache

Live coding, Senior+. Темы: generics, протоколы с associated types, type erasure, typed throws.
Время: **45 минут** (+ 5 минут на устные вопросы в конце).

Запуск тестов:

```bash
swift test
```

Приёмочные тесты уже написаны и выключены. Закончил часть — раскомментируй её флаг
в `Package.swift` (`PART1`, `PART2`, `PART3`, `BONUS`). Тесты менять нельзя.
Писать свои тесты можно, но не обязательно.

Весь код пиши в `Sources/TypedCache`. Типы публичные: это библиотека.

---

## Контекст

В приложении много кешей: аватарки, профили, конфиги. Сейчас это словари, раскиданные по сервисам.
Нужен один слой кеширования: общий протокол, LRU-реализация и read-through обёртка,
которая сама сходит в загрузчик при промахе.

## Часть 1. `Cache` и `LRUCache` (~15 мин)

**1.1. Протокол `Cache`.** Ключ и значение — associated types, ключ `Hashable`.
Должны работать `some Cache<String, Int>` и `any Cache<String, Int>`.

Требования протокола, ровно эти четыре:

```swift
var count: Int { get }
mutating func value(forKey key: Key) -> Value?
mutating func setValue(_ value: Value, forKey key: Key)
@discardableResult mutating func removeValue(forKey key: Key) -> Value?
```

**1.2. Extension протокола.** Всё ниже — без новых требований в протоколе:

* `isEmpty`.
* Subscript `cache[key]`. Чтение — через `value(forKey:)`, запись `nil` удаляет ключ.
* `value(forKey:orInsert:)`: при промахе вызывает замыкание, кладёт результат и возвращает его.
  Ошибка замыкания пробрасывается **с сохранением типа**: бросает `TestError` — снаружи ловится
  `TestError`, а не `any Error`. Не бросает — `try` не нужен.

**1.3. `LRUCache<Key, Value>`.**

* `init(capacity:)`. При переполнении вытесняется давно не использованный ключ.
* Чтение `value(forKey:)` и запись делают ключ самым свежим.
  Обновление существующего ключа ничего не вытесняет.
* Это `Sequence`: элементы `(key: Key, value: Value)`, порядок от самого свежего к самому старому.
  Итерация порядок не меняет.
* Value semantics: изменения копии не видны в оригинале.
* `Sendable`, когда `Key` и `Value` — `Sendable`.

Асимптотика на твой выбор. Озвучь её и скажи, что бы поменял в проде.

## Часть 2. `AnyCache` (~7 мин)

DI-контейнер отдаёт кеши как `any Cache<String, Profile>`. Дальше их нужно передать
в generic-код, который требует `C: Cache` (см. часть 3).

Напиши `AnyCache<Key, Value>`:

* Сам конформит `Cache`.
* Создаётся из любого конкретного кеша и из `any Cache<Key, Value>`.
* Разные реализации можно сложить в один `[AnyCache<String, Int>]`.
* Сохраняет value semantics.

## Часть 3. `DataLoader` и `ReadThroughCache` (~15 мин)

**3.1. Протокол `DataLoader`.** Асинхронно загружает значение по ключу:

```swift
func load(_ key: Key) async throws(Failure) -> Value
```

Тип ошибки — часть контракта. Загрузчик, который вообще не бросает
(`func load(_ key: Int) async -> String`), должен конформить протокол без лишних объявлений.

**3.2. `ReadThroughCache`.** Actor, generic по кешу и загрузчику.
Параметры связаны так, чтобы нельзя было собрать кеш `String → Int` с загрузчиком `URL → Data`.

```swift
init(cache: C, loader: L)
func value(forKey key: Key) async throws(Failure) -> Value
func invalidate(_ key: Key)
```

* Попадание — из кеша, промах — через загрузчик, результат кладётся в кеш.
* Ошибки не кешируются и пробрасываются с исходным типом.
  Для загрузчика без ошибок `value(forKey:)` вызывается без `try`.
* Swift 6, strict concurrency: никаких `@unchecked Sendable` и `nonisolated(unsafe)`.

## Бонус (если осталось время)

1. **Склейка запросов.** Три одновременных `value(forKey: "a")` при пустом кеше →
   загрузчик вызван один раз, результат или ошибку получают все трое.
   После ошибки следующий запрос снова идёт в загрузчик.
   Типизированная ошибка при этом не должна превратиться в `any Error`.
2. **O(1) LRU** с сохранением value semantics.

## Устные вопросы (после кода, ~5 мин)

1. `some Cache<String, Int>`, `any Cache<String, Int>` и `<C: Cache> where C.Key == String`:
   в чём разница для компилятора и в рантайме? Когда что выбираешь?
2. Почему `any Cache<String, Int>` нельзя напрямую передать в `ReadThroughCache<C: Cache, …>`?
   Как тогда работает `AnyCache(existential)`?
3. Метод объявлен **только** в extension протокола, а конкретный тип объявил метод с той же сигнатурой.
   Какая реализация вызовется через конкретный тип, через `some`, через `any`? А если метод есть в протоколе?
4. Зачем `Failure` в `DataLoader` — associated type, а не просто `throws`? Какую цену платим?

## Готово, когда

* Флаги `PART1`–`PART3` включены, `swift test` зелёный. `BONUS` — по желанию.
* Нет предупреждений компилятора.
* Скажи «готово» — будет ревью с оценкой.
