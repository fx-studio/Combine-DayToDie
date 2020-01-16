//
//  ViewController.swift
//  HelloUIKit
//
//  Created by Le Phuong Tien on 1/16/20.
//  Copyright © 2020 Fx Studio. All rights reserved.
//

import UIKit
import Combine

class ViewController: UIViewController {
    @IBOutlet weak var button: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    @IBAction func tap(sender: UIButton) {
        print("UIKit : tap me!")
    }
}

