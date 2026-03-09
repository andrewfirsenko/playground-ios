//
//  ViewController.swift
//  KeyboardPlayground
//
//  Created by Andrew on 09.03.2026.
//

import UIKit

//class ViewController: UIViewController {
//    private let textFiled = UITextField()
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        textFiled.becomeFirstResponder()
//    }
//}

class ViewController: UIViewController {
    private let customInputView = CustomInputView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(customInputView)
        customInputView.becomeFirstResponder()
    }
}
