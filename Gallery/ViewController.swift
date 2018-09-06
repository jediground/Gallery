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
    public convenience init(r red: UInt, g green: UInt, b blue: UInt, a alpha: CGFloat = 1.0) {
        let red   = CGFloat(red) / 255.0
        let green = CGFloat(green) / 255.0
        let blue  = CGFloat(blue) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    /// 0x3300cc or 0x30c
    public convenience init(hex: UInt32, alpha: CGFloat = 1) {
        let short = hex <= 0xfff
        let divisor: CGFloat = short ? 15 : 255
        let red   = CGFloat(short  ? (hex & 0xF00) >> 8 : (hex & 0xFF0000) >> 16) / divisor
        let green = CGFloat(short  ? (hex & 0x0F0) >> 4 : (hex & 0xFF00)   >> 8)  / divisor
        let blue  = CGFloat(short  ? (hex & 0x00F)      : (hex & 0xFF))           / divisor
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    /// #3300cc or #30c
    public convenience init(hex: String, alpha: CGFloat = 1) {
        // Convert hex string to an integer
        var hexint: UInt32 = 0
        
        // Create scanner
        let scanner = Scanner(string: hex)
        
        // Tell scanner to skip the # character
        scanner.charactersToBeSkipped = CharacterSet(charactersIn: "#")
        scanner.scanHexInt32(&hexint)
        
        self.init(hex: hexint, alpha: alpha)
    }
    
    public class var any: UIColor {
        let red   = CGFloat(random(in: 0 ..< 255)) / 255.0
        let green = CGFloat(random(in: 0 ..< 255)) / 255.0
        let blue  = CGFloat(random(in: 0 ..< 255)) / 255.0
        return UIColor(red: red, green: green, blue: blue, alpha: 1)
    }
}

// MARK: - iOS default color

public extension UIColor {
    public class var tint: UIColor {
        // 3, 122, 255, 1
        return UIColor(hex: 0x037AFF)
    }
    
    public class var separator: UIColor {
        // 200, 199, 204, 1
        return UIColor(hex: 0xC8C7CC)
    }
    
    public class var separatorDark: UIColor {
        // 69, 75, 65, 1
        return UIColor(hex: 0x454b41)
    }
    
    /// Grouped table view background.
    public class var groupedBackground: UIColor {
        // 239, 239, 244, 1
        return UIColor(hex: 0xEFEFF4)
    }
    
    /// Activity background
    public class var activityBackground: UIColor {
        // 248, 248, 248, 0.6
        return UIColor(hex: 0xF8F8F8, alpha: 0.6)
    }
    
    public class var disclosureIndicator: UIColor {
        return UIColor(hex: 0xC7C7CC)
    }
    
    /// Navigation bar title.
    public class var naviTitle: UIColor {
        // 3, 3, 3, 100
        return UIColor(hex: 0x030303)
    }
    
    public class var subTitle: UIColor {
        // 144, 144, 148, 100
        return UIColor(hex: 0x909094)
    }
    
    public class var placeholder: UIColor {
        // 200, 200, 205, 100
        return UIColor(hex: 0xC8C8CD)
    }
    
    public class var selected: UIColor {
        return UIColor(hex: 0xD9D9D9)
    }
}
