//
//  ColorPickerViewController.swift
//  BetterHomeKit
//
//  Created by Khaos Tian on 7/19/14.
//  Copyright (c) 2014 Oltica. All rights reserved.
//

import UIKit

class ColorPickerViewController: UIViewController {

    @IBOutlet var colorPickerView: HRColorPickerView
    
    weak var delegate:AnyObject?
    
    override func viewWillAppear(animated: Bool)  {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        if let delegate = delegate as? CharacteristicViewController {
            delegate.updateLightWithColor(colorPickerView.color)
        }
    }
    
    @IBAction func updateColor(sender: AnyObject) {
        if let delegate = delegate as? CharacteristicViewController {
            delegate.updateLightWithColor(colorPickerView.color)
        }
    }
}
