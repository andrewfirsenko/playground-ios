//
//  ViewController.swift
//  swift-core-animation-playground
//
//  Created by Andrey Firsenko on 03.06.2024.
//

import UIKit

class ViewController: UIViewController {
    
//    let circle = CALayer()
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        view.layer.addSublayer(circle)
//        circle.backgroundColor = UIColor.black.cgColor
//        circle.frame = CGRect(x: .zero, y: .zero, width: 100, height: 100)
//        circle.cornerRadius = circle.bounds.width / 2
//        
//        let tapGR = UITapGestureRecognizer(target: self, action: #selector(tapAction))
//        view.addGestureRecognizer(tapGR)
//    }
//    
//    override func viewWillLayoutSubviews() {
//        circle.position = view.center
//    }
//    
//    @objc func tapAction(sender: UITapGestureRecognizer) {
//        let location = sender.location(in: view)
//        circle.position = location
//    }
    
    let circle = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(circle)
        circle.backgroundColor = UIColor.black
        circle.frame = CGRect(x: .zero, y: .zero, width: 100, height: 100)
        circle.layer.cornerRadius = circle.bounds.width / 2
        
        let tapGR = UITapGestureRecognizer(target: self, action: #selector(tapAction))
        view.addGestureRecognizer(tapGR)
    }
    
    override func viewWillLayoutSubviews() {
        circle.layer.position = view.center
    }
    
    @objc func tapAction(sender: UITapGestureRecognizer) {
        let location = sender.location(in: view)
        let presentationLayer = circle.layer.presentation() ?? circle.layer
        let anim = CABasicAnimation(keyPath: "position")
        anim.setValue("change_position_anim", forKey: "animId")
        anim.duration = 2
        anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        anim.fromValue = presentationLayer.position
        anim.toValue = location
        anim.delegate = self
        
        circle.layer.position = location
        circle.layer.add(anim, forKey: "change_position_anim_key")
    }
}

extension UIViewController: CAAnimationDelegate {
    
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        guard let animId = anim.value(forKey: "animId") as? String else { return }
        
        switch animId {
        case "change_position_anim": print("log: anim \(animId) stop.")
        default: break
        }
    }
}

