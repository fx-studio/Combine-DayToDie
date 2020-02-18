//
//  BaseViewController.swift
//  DemoMVVMCombine
//
//  Created by Le Phuong Tien on 2/18/20.
//  Copyright © 2020 Fx Studio. All rights reserved.
//

import UIKit
import Combine

class BaseViewController: UIViewController {
  
  //MARK: - Properties
  var subscriptions = [AnyCancellable]()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupData()
    setupUI()
  }
  
  //MARK: - Configuration
  func setupData() { }
  
  func setupUI() { }
  
  //MARK: - Navigation
  func alert(title: String, text: String?) -> AnyPublisher<Void, Never> {
    let alertVC = UIAlertController(title: title, message: text, preferredStyle: .alert)
    
    return Future { resolve in
      alertVC.addAction(UIAlertAction(title: "Close", style: .default, handler: { _ in
        resolve(.success(()))
      }))
      
      self.present(alertVC, animated: true, completion: nil)
    }.handleEvents(receiveCancel: {
      self.dismiss(animated: true)
    }).eraseToAnyPublisher()
  }
  
}
