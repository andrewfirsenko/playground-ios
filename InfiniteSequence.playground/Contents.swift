import Foundation

struct InfiniteSequence<Element: Hashable>: Sequence {
    
    // Private
    private var elements: [Element]
    
    // MARK: - Sequence
    
    func makeIterator() -> some IteratorProtocol {
        var currentIndex = -1
        
        return AnyIterator<Element> {
            currentIndex = (currentIndex + 1) % elements.count
            return elements[currentIndex]
        }
    }
}

extension InfiniteSequence: ExpressibleByArrayLiteral {
    
    typealias ArrayLiteralElement = Element
    
    init(arrayLiteral elements: Element...) {
        self.elements = elements
    }
    
    init(_ elements: [Element]) {
        self.elements = elements
    }
}


zip(0..<100, InfiniteSequence(["a", "b", "c"])).forEach { (index, element) in
    print(index, element)
}
