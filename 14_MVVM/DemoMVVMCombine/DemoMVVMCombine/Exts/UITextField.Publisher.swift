//
//  UITextField.Publisher.swift
//  DemoMVVMCombine
//
//  Created by Le Phuong Tien on 2/18/20.
//  Copyright © 2020 Fx Studio. All rights reserved.
//

import Foundation
import UIKit
import Combine

extension UITextField {
  var publisher: AnyPublisher<String?, Never> {
    NotificationCenter.default
      .publisher(for: UITextField.textDidChangeNotification, object: self)
      .compactMap { $0.object as? UITextField? }
      .map { $0?.text }
      .eraseToAnyPublisher()
  }
}
