//
//  UIImageView.Ext.swift
//  DemoMVVMCombine
//
//  Created by Le Phuong Tien on 2/20/20.
//  Copyright © 2020 Fx Studio. All rights reserved.
//

import Foundation
import UIKit
import Combine

extension UIImageView {
  func load(url: URL) {
    DispatchQueue.global().async { [weak self] in
      if let data = try? Data(contentsOf: url) {
        if let image = UIImage(data: data) {
          DispatchQueue.main.async {
            self?.image = image
          }
        }
      }
    }
  }
  
  func load(urlString: String) {
    guard let url = URL(string: urlString) else { return }
    
    DispatchQueue.global().async { [weak self] in
      if let data = try? Data(contentsOf: url) {
        if let image = UIImage(data: data) {
          DispatchQueue.main.async {
            self?.image = image
          }
        }
      }
    }
  }

}
