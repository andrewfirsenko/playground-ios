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
        BagIterator<Element>(storage: storage)
    }
    
    // MARK: - BagIterator
    
    private struct BagIterator<Element: Hashable>: IteratorProtocol {

        private var storage: [Element: Int]
        
        init(storage: [Element: Int]) {
            self.storage = storage
        }
        
        mutating func next() -> Element? {
            guard let element = storage.first else { return nil }
            
            if element.value > 1 {
                storage[element.key]? -= 1
            } else {
                storage[element.key] = nil
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

var bag = Bag<Int>()
bag.insert(3)
bag.insert(2)
bag.insert(3)

print("(\(bag.count)) \(bag)")
bag.forEach { element in
    print(element)
}
