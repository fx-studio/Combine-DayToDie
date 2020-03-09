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
  
  var subscriptions = Set<AnyCancellable>()
  
  @IBOutlet weak var countTexyField: UITextField!
  @IBOutlet weak var doneButton: UIButton!
  
  //  var countPublisher = PassthroughSubject<Int, Never>()
//
//  var count: Int = 0 {
//    didSet {
//      countPublisher.send(count)
//    }
//  }
  
  @Published var count: Int = 0
  
  var validated : AnyPublisher<Bool, Never> {
    return Publishers.Map(upstream: $count) { $0 >= 0 }.eraseToAnyPublisher()
  }
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // update UI
    // title
    $count
      .map { "\($0)" }
      .assign(to: \.title, on: self)
      .store(in: &subscriptions)
    
    // textfield
    countTexyField.text = "\(count)"
    
    countTexyField.publisher
      .sink { value in
        guard let value = value, let temp = Int(value) else {
          return
        }

        self.count = temp

    }.store(in: &subscriptions)
    
    // button
    validated
      .assign(to: \.isEnabled, on: doneButton)
      .store(in: &subscriptions)
  }
  
  @IBAction func done(_ sender: Any) {
    guard let value = Int(countTexyField.text ?? "0") else { return }
    count = value
    
    self.navigationController?.popViewController(animated: true)
  }
  
}
