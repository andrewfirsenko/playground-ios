import Foundation

func doAsyncLet() {
    Task {
        async let result1 = method1()
        async let result2 = method2()
        
        debugPrint("log: result1=\(await result1)")
//        debugPrint("log: result2=\(await result2)")
        /// END OF SCOPE
        /// childTasks.cancel()
        /// await chlidTasks
    }
}

func method1() async -> Int {
    return 1
}

func method2() async -> Int {
    return 2
}

doAsyncLet()
