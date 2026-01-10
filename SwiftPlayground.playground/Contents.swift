import Foundation

var unsafeSet: Set<String> = Set()

DispatchQueue.concurrentPerform(iterations: 100) { _ in
    unsafeSet.insert(Thread.current.description)
}

print(unsafeSet)
