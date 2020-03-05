//
//  SettingsViewController.swift
//  HelloUIKit
//
//  Created by Le Phuong Tien on 3/5/20.
//  Copyright © 2020 Fx Studio. All rights reserved.
//

import UIKit
import Combine

class SettingsViewController: UIViewController {
  
  @IBOutlet weak var countTexyField: UITextField!
  
//  var countPublisher = PassthroughSubject<Int, Never>()
//
//  var count: Int = 0 {
//    didSet {
//      countPublisher.send(count)
//    }
//  }
  
  @Published var count: Int = 0
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    countTexyField.text = "\(count)"
  }
  
  @IBAction func done(_ sender: Any) {
    guard let value = Int(countTexyField.text ?? "0") else { return }
    count = value
    
    self.navigationController?.popViewController(animated: true)
  }
  
}
