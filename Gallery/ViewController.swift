//
//  ViewController.swift
//  Gallery
//
//  Created by Shaw on 9/6/18.
//  Copyright © 2018 Shaw. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

public func random(in range: Range<Int>) -> Int {
    let count = UInt32(range.upperBound - range.lowerBound)
    return Int(arc4random_uniform(count)) + range.lowerBound
}

public extension UIKit.UIColor {
    public class var any: UIColor {
        let red   = CGFloat(random(in: 0 ..< 255)) / 255.0
        let green = CGFloat(random(in: 0 ..< 255)) / 255.0
        let blue  = CGFloat(random(in: 0 ..< 255)) / 255.0
        return UIColor(red: red, green: green, blue: blue, alpha: 1)
    }
}

