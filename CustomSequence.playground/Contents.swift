import Foundation

struct Bag<Element: Hashable>: Sequence {
    
    // Private
    private var storage: [Element: Int] = [:]
    
    // Public
    var count: Int {
        storage.values.reduce(0, +)
    }
    
    mutating func insert(_ element: Element) {
        storage[element, default: 0] += 1
    }
    
    mutating func remove(_ element: Element) {
        guard let value = storage[element] else { return }
        
        if value > 1 {
            storage[element]? -= 1
        } else {
            storage[element] = nil
        }
    }
    
    // MARK: - Sequence
    
    func makeIterator() -> some IteratorProtocol {
        var copyStorage = storage
        
        return AnyIterator<Element> {
            guard let element = copyStorage.first else { return nil }
            
            if element.value > 1 {
                copyStorage[element.key]? -= 1
            } else {
                copyStorage[element.key] = nil
            }
            return element.key
        }
    }
}

extension Bag: CustomStringConvertible {
    var description: String {
        return self.reduce("") { partialResult, element in partialResult + "\(element) " }
    }
}

extension Bag: ExpressibleByArrayLiteral {
    
    typealias ArrayLiteralElement = Element
    
    init(arrayLiteral elements: Element...) {
        self.storage = elements.reduce(into: [Element: Int](), { partialResult, element in
            partialResult[element, default: 0] += 1
        })
    }
}

var bag: Bag = [2, 3, 3, 4, 5, 2, 3]

print("(\(bag.count)) \(bag)")
bag.forEach { element in
    print(element)
}
