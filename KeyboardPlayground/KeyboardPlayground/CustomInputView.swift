//
//  CustomInputView.swift
//  KeyboardPlayground
//
//  Created by Andrew on 09.03.2026.
//

import UIKit

final class CustomInputView: UIView, UIKeyInput {
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    var hasText: Bool {
        return false
    }
    
    func insertText(_ text: String) {
        debugPrint("log: insertText text=\(text)")
    }
    
    func deleteBackward() {
        debugPrint("log: deleteBackward")
    }
}
