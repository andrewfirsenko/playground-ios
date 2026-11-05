#if PART1
import Testing
@testable import FeatureToggles

@Suite("Часть 1. FlagValue и FeatureFlag")
struct Part1FlagValueTests {

    // MARK: - Примитивы

    @Test func primitivesRoundTrip() {
        #expect(Bool(rawFlag: true.rawFlag) == true)
        #expect(Int(rawFlag: 7.rawFlag) == 7)
        #expect(Double(rawFlag: 1.5.rawFlag) == 1.5)
        #expect(String(rawFlag: "a".rawFlag) == "a")
    }

    @Test func primitivesProduceMatchingRawCase() {
        #expect(true.rawFlag == .bool(true))
        #expect(7.rawFlag == .int(7))
        #expect(1.5.rawFlag == .double(1.5))
        #expect("a".rawFlag == .string("a"))
    }

    @Test func typesAreStrict() {
        #expect(Bool(rawFlag: .int(1)) == nil)
        #expect(Int(rawFlag: .bool(true)) == nil)
        #expect(Int(rawFlag: .double(1.5)) == nil)
        #expect(String(rawFlag: .int(1)) == nil)
        #expect(Double(rawFlag: .string("1.5")) == nil)
    }

    @Test func doubleAcceptsInt() {
        #expect(Double(rawFlag: .int(1)) == 1.0)
    }

    // MARK: - Enum

    @Test func stringEnumConformsWithoutCode() {
        #expect(Theme(rawFlag: .string("dark")) == .dark)
        #expect(Theme.dark.rawFlag == .string("dark"))
    }

    @Test func intEnumConformsWithoutCode() {
        #expect(Tier(rawFlag: .int(1)) == .pro)
        #expect(Tier.pro.rawFlag == .int(1))
    }

    @Test func unknownEnumCaseIsNil() {
        #expect(Theme(rawFlag: .string("sepia")) == nil)
        #expect(Theme(rawFlag: .int(1)) == nil)
        #expect(Tier(rawFlag: .int(99)) == nil)
    }

    // MARK: - Массивы

    @Test func arrayOfPrimitives() {
        #expect([Int](rawFlag: .array([.int(1), .int(2)])) == [1, 2])
        #expect([1, 2].rawFlag == .array([.int(1), .int(2)]))
    }

    @Test func emptyArrayIsValid() {
        #expect([Int](rawFlag: .array([])) == [])
    }

    @Test func arrayOfEnums() {
        #expect([Theme](rawFlag: .array([.string("dark"), .string("light")])) == [.dark, .light])
    }

    @Test func nestedArrays() {
        let raw = RawFlagValue.array([.array([.int(1)]), .array([.int(2), .int(3)])])

        #expect([[Int]](rawFlag: raw) == [[1], [2, 3]])
        #expect([[1], [2, 3]].rawFlag == raw)
    }

    @Test func singleBadElementInvalidatesWholeArray() {
        #expect([Int](rawFlag: .array([.int(1), .string("x")])) == nil)
        #expect([Theme](rawFlag: .array([.string("dark"), .string("sepia")])) == nil)
    }

    @Test func arrayRejectsNonArrayRaw() {
        #expect([Int](rawFlag: .int(1)) == nil)
    }

    // MARK: - FeatureFlag

    @Test func flagKeepsKeyAndDefault() {
        let flag = FeatureFlag("theme", default: Theme.dark)

        #expect(flag.key == "theme")
        #expect(flag.defaultValue == .dark)
    }

    @Test func flagValueTypeIsInferred() {
        let bool: FeatureFlag<Bool> = Flags.newCheckout
        let theme: FeatureFlag<Theme> = Flags.theme
        let tiers: FeatureFlag<[Tier]> = Flags.allowedTiers

        #expect(bool.defaultValue == false)
        #expect(theme.defaultValue == .light)
        #expect(tiers.defaultValue == [.free])
    }
}
#endif
