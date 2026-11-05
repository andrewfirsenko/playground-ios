/// Нетипизированное значение флага: то, что приходит из remote config или с диска.
/// Уже готово, менять не нужно.
enum RawFlagValue: Sendable, Equatable {
    case bool(Bool)
    case int(Int)
    case double(Double)
    case string(String)
    case array([RawFlagValue])
}
