//
//  HomeViewController.swift
//  HelloUIKit
//
//  Created by Le Phuong Tien on 3/3/20.
//  Copyright © 2020 Fx Studio. All rights reserved.
//

import UIKit
import Combine

class HomeViewController: UIViewController {
  
  var subscriptions = Set<AnyCancellable>()
  
  var countPublisher = CurrentValueSubject<Int, Never>(0)
  
  @IBOutlet weak var counterLabel: UILabel!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    countPublisher
      .handleEvents(receiveOutput: { [weak self] value in
        self?.view.backgroundColor = (value % 2 == 0) ? UIColor.white : UIColor.lightGray
      })
      .map { "\($0)"}
      .assign(to: \.text, on: self.counterLabel)
      .store(in: &subscriptions)
    
  }
  
  @IBAction func increase(_ sender: Any) {
    countPublisher.value += 1
    
  }
  
  @IBAction func reduce(_ sender: Any) {
    countPublisher.value += 1
  }
  
  
}
