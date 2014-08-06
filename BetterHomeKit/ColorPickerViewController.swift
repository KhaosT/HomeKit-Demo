//
//  ColorPickerViewController.swift
//  BetterHomeKit
//
//  Created by Khaos Tian on 7/19/14.
//  Copyright (c) 2014 Oltica. All rights reserved.
//

import UIKit

class ColorPickerViewController: UIViewController {

    @IBOutlet var colorPickerView: HRColorPickerView!
    
    var initialColor:UIColor?
    
    weak var delegate:AnyObject?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let initialColor = initialColor {
            colorPickerView.color = initialColor
        }
    }
    
    override func viewWillAppear(animated: Bool)  {
        super.viewWillAppear(animated)
    }
    
    @IBAction func updateColor(sender: AnyObject) {
        if let delegate = delegate as? CharacteristicViewController {
            delegate.updateLightWithColor(colorPickerView?.color)
        }
    }
}
