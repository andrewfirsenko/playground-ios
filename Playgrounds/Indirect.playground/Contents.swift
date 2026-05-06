import UIKit

// Error: Recursive enum 'Node' is not marked 'indirect'
//enum Node {
//    case none
//    case next(Node)
//}


indirect enum Node {
    case none
    case next(Node)
}

// Or

enum OneMoreNode {
    case none
    indirect case next(OneMoreNode)
}

// Real case

indirect enum Expression {
    case number(Int)
    case add(Expression, Expression)
    case multiplication(Expression, Expression)
}

func calculate(expression: Expression) -> Int {
    switch expression {
    case let .number(value):
        return value
    case let .add(lhs, rhs):
        return calculate(expression: lhs) + calculate(expression: rhs)
    case let .multiplication(lhs, rhs):
        return calculate(expression: lhs) * calculate(expression: rhs)
    }
}
